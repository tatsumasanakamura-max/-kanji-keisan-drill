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
  "question": "string",
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
        "Purpose: answer the reading of the underlined kanji word in a sentence.",
        "question and sentence must both be the natural sentence body only.",
        "target must be the exact kanji word inside sentence.",
        "choices must be readings.",
    ],
    "writing": [
        "Purpose: convert the underlined hiragana word in a sentence to kanji.",
        "target must be the exact hiragana word inside sentence.",
        "answer_text must be the correct kanji form.",
        "choices must be kanji words.",
    ],
    "compound": [
        "Purpose: complete the compound word in context.",
        "sentence must contain a word with □.",
        "target must include □, such as 山□.",
        "answer_text must be the completed compound.",
        "choices must be single real kanji characters.",
    ],
    "sentence": [
        "Purpose: choose the word that fits the sentence meaning.",
        "sentence must contain target placeholder such as ○○.",
        "choices must have the same writing level; do not mix kanji and hiragana.",
        "The completed sentence must be natural Japanese.",
    ],
    "homophone": [
        "Purpose: choose the correct kanji from context for the same reading.",
        "reading must be present.",
        "sentence must contain target placeholder such as ○.",
        "choices must be real kanji with the same reading.",
    ],
    "opposite": [
        "Purpose: choose the antonym of the underlined word in the sentence.",
        "target must be the exact word inside sentence.",
        "choices must have the same part of speech.",
        "Use natural antonyms.",
    ],
    "synonym": [
        "Purpose: choose a word with a similar meaning to the underlined word.",
        "target must be the exact word inside sentence.",
        "choices must have the same part of speech.",
        "Use real words only. Do not use explanatory phrases like サイズが大きい.",
    ],
}


def generate_prompt(target: str, grade: int, kanken: int, question_type: str, count: int, existing_ids: list[str]) -> str:
    fixed_prompt = FIXED_PROMPTS.get(question_type, "")
    context_rules = TYPE_RULES.get(question_type, [])
    return f"""
You are generating high-quality Japanese kanji drill questions for elementary learners.

Target course: {target}
Grade: {grade}
Kanken level: {kanken}
Category/type: {question_type}
Count: {count}

Hard requirements:
- ダミー問題禁止
- プレースホルダー禁止
- 実際に学習効果がある問題
- 漢検・学校教材レベルの品質
- 自然な日本語の文章を読んで文脈から判断する問題
- 誤答は実際に迷う内容
- 小学生向けの文
- JSONのみ
- Markdown禁止
- 説明禁止
- Existing IDs must not be reused.
- The answer field is the zero-based index of the correct item in choices.
- Use natural Japanese text. Do not output mojibake.
- Keep the existing assets/data JSON structure compatible.

Context schema requirements for reading/writing/compound/sentence/homophone/opposite/synonym:
- Include prompt, sentence, target.
- prompt must be the fixed prompt for the type.
- sentence must be natural Japanese.
- target must exactly appear inside sentence.
- question must duplicate sentence for backward compatibility.
- meaning must explain the correct answer word.
- example must be the completed natural sentence.
- choices must be real words or real kanji only.
- Keep part of speech and writing level consistent across choices.

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
You are an expert Japanese elementary education material reviewer.
Review the submitted kanji questions as educational content.

Evaluate each question and the set overall on a 100 point scale.
Focus especially on:
- sentence が自然か
- target が sentence に含まれているか
- choices が同じ品詞か
- choices の表記レベルが統一されているか
- choices の難易度が適切か
- 誤答が実際に迷う内容か
- 学年・漢検級に適合しているか
- meaning が正解語の意味になっているか
- example が完成した自然な例文になっているか

Return JSON only. No Markdown. No explanation outside JSON.
Schema:
{{
  "overall_score": integer,
  "summary": "string",
  "items": [
    {{
      "id": "string",
      "score": integer,
      "needs_improvement": boolean,
      "issues": ["string"],
      "improvement_suggestions": ["string"]
    }}
  ]
}}

Questions:
{payload}
""".strip()


def improve_prompt(questions: list[dict[str, Any]], review: dict[str, Any]) -> str:
    return f"""
You improve only the submitted kanji questions based on the review.

Rules:
- Keep IDs unchanged.
- Keep the existing base schema.
- For reading/writing/compound/sentence/homophone/opposite/synonym, include prompt, sentence, target.
- prompt must be the fixed prompt for the question type.
- sentence must be natural Japanese.
- target must exactly appear inside sentence.
- question must duplicate sentence for backward compatibility.
- Improve choices, meaning, example, difficulty, and distractors where needed.
- Keep choices to real words or real kanji only.
- Keep part of speech and writing level consistent.
- Do not add Markdown.
- Do not add explanations outside JSON.
- Return only JSON in this shape: {{"questions":[...]}}

Questions:
{questions}

Review:
{review}
""".strip()
