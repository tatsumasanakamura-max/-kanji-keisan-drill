# AI Question Pipeline

This pipeline generates, validates, reviews, improves, and merges kanji question
data for `assets/data/*.json`.

The goal is not to mass-produce raw AI text. The goal is to run an editorial
quality flow similar to elementary Japanese language, kanji drill, and kanji
proficiency test material production.

## Setup

Create `.env` at the project root.

```text
OPENAI_API_KEY=sk-...
OPENAI_MODEL=gpt-4.1-mini
OPENAI_REVIEW_MODEL=gpt-4.1-mini
OPENAI_API_BASE=https://api.openai.com/v1
```

## Generate

```bash
python tools/question_pipeline/generate_questions.py --target grade5 --type reading --count 5
```

Supported targets:

```text
grade1 grade2 grade3 grade4 grade5 grade6
kanken10 kanken9 kanken8 kanken7 kanken6 kanken5 kanken4 kanken3
```

Supported types:

```text
reading writing compound sentence homophone opposite synonym yojijukugo radical correction
```

For `reading` through `synonym`, generated questions use the context schema:

```json
{
  "prompt": "",
  "sentence": "",
  "target": "",
  "choices": [],
  "answer": 0
}
```

`question` is kept as a duplicate of `sentence` for backward compatibility.

## Validate

```bash
python tools/question_pipeline/validate_questions.py --input tools/question_pipeline/output/generated/example.json
```

Validation checks JSON syntax, required fields, answer range, choice count,
difficulty, tags, meaning, example, duplicate IDs, duplicate questions,
duplicate choices, empty strings, invalid categories, and context-schema rules.

## Educational Review

The review step acts as an educational committee review, not a casual AI review.
It judges whether each question can be adopted for elementary-school home
learning and classroom use.

```bash
python tools/question_pipeline/review_questions.py assets/data/grade5.json
```

Reports are written to `output/reports`, for example:

```text
tools/question_pipeline/output/reports/grade5_review.json
```

Each item includes:

- `adoption`: `accept`, `revise`, or `reject`
- `unique_answer`
- `naturalness_check`
- `educational_quality`
- `issues`
- `suggestion`

Review emphasis:

- `homophone`: choices must share the same reading and be selected by context.
- `synonym`: choices must be genuine near-synonyms, not loose associations.
- `opposite`: the target must appear naturally without explanatory AI-like text.
- All types: the sentence alone must make exactly one answer correct.

## Improve

Improve questions based on the review report.

```bash
python tools/question_pipeline/improve_questions.py \
  --questions assets/data/grade5.json \
  --review tools/question_pipeline/output/reports/grade5_review.json
```

The improver revises items when:

- `adoption` is `revise` or `reject`
- `unique_answer` is `false`
- score is below 80
- textbook quality is below 80
- natural Japanese score is below 80
- AI-like score is 40 or higher
- meaning/example consistency is below 80

When quality or uniqueness is weak, the improver should rewrite the whole
sentence context, not merely swap one word.

## Quality Score

Run structural scoring only:

```bash
python tools/question_pipeline/quality_score.py --input assets/data/grade5.json
```

Run structural scoring plus AI-review scoring:

```bash
python tools/question_pipeline/quality_score.py \
  --input assets/data/grade5.json \
  --review tools/question_pipeline/output/reports/grade5_review.json
```

AI-review score uses:

```text
naturalness                  20
unique answer                25
textbook quality             20
learning effect              15
choice quality               10
meaning/example consistency  10
```

Decision guide:

```text
90+    adopt
80-89  minor revision
70-79  improve
0-69   regenerate
```

## Merge

Merge only improved/adoptable data.

```bash
python tools/question_pipeline/merge_questions.py --dry-run
python tools/question_pipeline/merge_questions.py
```

The merge step backs up `assets/data` before writing.

## Recommended Flow

```text
1. generate
2. validate
3. quality_score
4. review
5. improve
6. review again
7. validate
8. quality_score with review
9. merge only accepted data
```
