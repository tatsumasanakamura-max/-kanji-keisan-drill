from __future__ import annotations

import json
from typing import Any

from config import CONTEXT_QUESTION_TYPES, FIXED_PROMPTS, QUESTION_TYPES, REQUIRED_FIELDS


SCHEMA_TEXT = """Each question must keep the existing base fields:
{
  "id": "string",
  "grade": integer,
  "kanken": integer,
  "difficulty": integer from 1 to 5,
  "type": one of CATEGORY_LIST,
  "question": "string, duplicate of sentence for backward compatibility",
  "prompt": "string",
  "sentence": "string",
  "target": "string",
  "choices": ["string", "string", "string", "string"],
  "answer": integer zero-based index in choices,
  "answer_text": "string, required for writing and compound",
  "reading": "string, required for homophone",
  "meaning": "string",
  "example": "string",
  "mnemonic": "string",
  "synonyms": ["string"],
  "antonyms": ["string"],
  "tags": ["string"]
}"""


TYPE_RULES = {
    "reading": [
        "Answer the reading of the underlined kanji word in a natural sentence.",
        "target must exactly match the kanji word inside sentence.",
        "choices must be plausible readings, but only one is correct.",
    ],
    "writing": [
        "Convert the underlined hiragana word in context to kanji.",
        "target must exactly match the hiragana word inside sentence.",
        "answer_text is the correct kanji word.",
        "choices are kanji words; avoid obviously fake compounds.",
    ],
    "compound": [
        "Complete a compound word from context.",
        "sentence contains a word with the placeholder □.",
        "target contains □, such as 山□ or □業.",
        "answer_text is the completed compound.",
        "choices must be single real kanji characters.",
    ],
    "sentence": [
        "Choose the word that fits the sentence meaning.",
        "sentence contains the placeholder target such as ○○.",
        "choices must have the same part of speech and writing level.",
        "Do not mix kanji and hiragana writing levels in choices.",
    ],
    "homophone": [
        "Choose the correct kanji/word with the same reading from context.",
        "reading is required.",
        "choices must share the same reading.",
        "Do not make this merely a compound-completion question.",
        "The sentence context must make only one homophone correct.",
    ],
    "opposite": [
        "Choose the antonym of the underlined target word.",
        "target must appear naturally inside sentence.",
        "choices must have the same part of speech.",
        "Avoid explanatory phrases such as 'the opposite result'.",
    ],
    "synonym": [
        "Choose a genuine near-synonym of the underlined target word.",
        "target must appear naturally inside sentence.",
        "choices must have the same part of speech.",
        "Avoid loose associations and explanatory phrases.",
    ],
}


UNIQUENESS_RULES = """
The sentence alone must make exactly one choice correct.

Reject or revise any item where multiple choices can naturally fit the same
sentence. For example, do not allow a context where agriculture, commerce,
industry, and fishing could all fit. Do not allow a context where elementary
school, junior high school, and high school could all fit.

Short AI-like sentences are not acceptable when they do not determine a unique
answer. Use two or three natural textbook-style sentences if needed.

Bad: He succeeded in □業.
Good: He opened a stationery shop in front of the station and was trusted by
local families for many years. He succeeded in □業.

Bad: I go to □学校 every morning.
Good: Wearing a randoseru and walking with friends, she goes to □学校 every
morning.

Bad: The new □科 teacher.
Good: Today we observed how plants grow and used lab tools to investigate them.
The new □科 teacher taught the lesson.
""".strip()


def generate_prompt(target: str, grade: int, kanken: int, question_type: str, count: int, existing_ids: list[str]) -> str:
    fixed_prompt = FIXED_PROMPTS.get(question_type, "")
    context_rules = TYPE_RULES.get(question_type, [])
    return f"""
You are a veteran editor with over 20 years of experience creating Japanese
elementary language arts, kanji drill, and kanji proficiency test materials.
The questions you create will be used by Japanese elementary school students at
school and for home study. Aim for the quality of textbook publishers and major
commercial elementary learning materials.

Target course: {target}
Grade: {grade}
Kanken level: {kanken}
Category/type: {question_type}
Count: {count}

Before output, internally perform this editorial flow:
1. Create the question as a professional teaching editor.
2. Review it yourself for textbook quality.
3. Revise sentence, choices, meaning, and example as needed.
4. Output only items that are adoptable as JSON.

Hard requirements:
- No dummy questions.
- No placeholders except the intentional target marker such as □ or ○.
- No AI-like short sentences.
- No conversational style.
- Natural Japanese suitable for fifth-grade elementary students.
- The sentence alone must determine one correct answer.
- Wrong choices should be plausible but clearly wrong from context.
- JSON only. No Markdown. No comments. No explanatory text outside JSON.
- Existing IDs must not be reused.
- answer is the zero-based index of the correct choice.
- Use natural Japanese text. Do not output mojibake.

Context schema requirements:
- Include prompt, sentence, target for context question types.
- prompt must exactly equal the fixed prompt for the type.
- sentence may use two or three natural sentences when needed.
- target must exactly appear inside sentence.
- question must duplicate sentence for backward compatibility.
- meaning must explain the correct answer word.
- example must be the completed natural sentence.
- choices must be real words or real kanji only.
- Keep part of speech and writing level consistent across choices.

Uniqueness requirements:
{UNIQUENESS_RULES}

Fixed prompt for this type:
{fixed_prompt}

Type-specific rules:
{json.dumps(context_rules, ensure_ascii=False, indent=2)}

Allowed categories: {sorted(QUESTION_TYPES)}
Context-required categories: {sorted(CONTEXT_QUESTION_TYPES)}
Required base fields: {sorted(REQUIRED_FIELDS)}
Existing ID examples to avoid: {existing_ids[:200]}

{SCHEMA_TEXT.replace("CATEGORY_LIST", ", ".join(sorted(QUESTION_TYPES)))}

Return exactly:
{{"questions":[...]}}
""".strip()


def review_prompt(payload: dict[str, Any]) -> str:
    return f"""
You are an educational review committee member for Japanese elementary language
arts and kanji learning materials. Review whether the submitted kanji questions
are adoptable for fifth-grade home-learning and school material.

Make a clear adoption judgment for each item:
- accept: can be used as-is.
- revise: can be used after revision.
- reject: invalid as a question or should be regenerated.

For every item, check:
- Does the sentence alone determine exactly one answer?
- Could any wrong choice also fit naturally?
- Is the Japanese natural and human-written?
- Is it suitable for elementary students?
- Does it feel like textbook or commercial drill quality?
- Are choices educational and not too unnatural?
- Are meaning and example consistent with the correct answer?

Type-specific high-priority checks:
- reading: readings should be plausible; wrong readings should not be bizarre.
- writing: wrong kanji compounds should not be fake or grotesquely unnatural.
- compound: multiple compounds must not fit the same context.
- sentence: choices must share part of speech and writing level.
- homophone: choices must share the same reading and be selected by context.
- opposite: avoid explanatory AI-like wording; use natural antonyms.
- synonym: choices must be genuine near-synonyms, not loose associations.

Return JSON only. No Markdown. No explanation outside JSON.
Schema:
{{
  "summary": {{
    "total": integer,
    "accept": integer,
    "revise": integer,
    "reject": integer,
    "average_score": number,
    "main_issues": ["string"]
  }},
  "overall_score": integer,
  "items": [
    {{
      "id": "string",
      "adoption": "accept | revise | reject",
      "score": integer,
      "issues": ["string"],
      "suggestion": "string",
      "adoption_detail": {{
        "reason": "string",
        "suggestion": "string"
      }},
      "unique_answer": boolean,
      "unique_answer_reason": "string",
      "naturalness_check": {{
        "natural_japanese": integer,
        "human_written_quality": integer,
        "ai_like_score": integer
      }},
      "educational_quality": {{
        "textbook_quality": integer,
        "learning_effect": integer,
        "grade_fit": integer,
        "choice_quality": integer,
        "meaning_example_consistency": integer
      }},
      "needs_improvement": boolean
    }}
  ]
}}

Scoring guide:
- 90 or above: accept.
- 80-89: revise lightly.
- 70-79: revise substantially.
- 69 or below: reject/regenerate.
- unique_answer=false always requires revise or reject.
- ai_like_score is bad when high; 40 or above needs revision.

Questions:
{payload}
""".strip()


def improve_prompt(questions: list[dict[str, Any]], review: dict[str, Any]) -> str:
    return f"""
You are improving kanji questions according to an educational committee review.

Improve every item where:
- adoption is revise or reject.
- unique_answer is false.
- score is below 80.
- textbook_quality is below 80.
- natural_japanese is below 80.
- ai_like_score is 40 or above.
- meaning_example_consistency is below 80.

Do not merely swap one word. When uniqueness or quality is weak, revise the
whole sentence context, target, choices, answer, answer_text, meaning, example,
difficulty, and tags as needed.

Rules:
- Keep IDs unchanged.
- Keep the same type unless the item is structurally impossible.
- Keep the existing base schema.
- Include prompt, sentence, target for context question types.
- prompt must be the fixed prompt for the question type.
- sentence must be natural Japanese and may use two or three sentences.
- target must exactly appear inside sentence.
- question must duplicate sentence for backward compatibility.
- choices must be real words or real kanji only.
- Keep part of speech and writing level consistent.
- Homophone must use same-reading choices and context-based selection.
- Synonym must use genuine near-synonyms.
- Opposite must use natural antonyms in natural context.
- Return all original questions, including unchanged accept items.
- JSON only. No Markdown. No comments.

Uniqueness requirements:
{UNIQUENESS_RULES}

Return only:
{{"questions":[...]}}

Questions:
{questions}

Review:
{review}
""".strip()
