from __future__ import annotations

import argparse
from pathlib import Path
from typing import Any

from config import ASSETS_DATA_DIR, CONTEXT_QUESTION_TYPES, DIFFICULTIES, FIXED_PROMPTS, GENERATED_DIR, IMPROVED_DIR, QUESTION_TYPES, REQUIRED_FIELDS, latest_json, questions_from_payload, read_json


def normalized_text(value: Any) -> str:
    return str(value).strip()


def requires_context_schema(payload: Any) -> bool:
    return isinstance(payload, dict) and payload.get("format_version") in {
        "reading-target-v2",
        "context-sentence-v3",
    }


def validate_payload(payload: Any, source: str) -> list[str]:
    errors: list[str] = []
    try:
        questions = questions_from_payload(payload)
    except ValueError as error:
        return [f"{source}: {error}"]

    seen_ids: dict[str, int] = {}
    seen_questions: dict[str, str] = {}
    for index, question in enumerate(questions):
        prefix = f"{source}: questions[{index}]"
        if not isinstance(question, dict):
            errors.append(f"{prefix}: question must be object")
            continue
        missing = REQUIRED_FIELDS - set(question)
        if missing:
            errors.append(f"{prefix}: missing fields {sorted(missing)}")
        for key, value in question.items():
            if isinstance(value, str) and value.strip() == "":
                if key not in {"mnemonic"}:
                    errors.append(f"{prefix}: empty string in {key}")
            if isinstance(value, list):
                for item_index, item in enumerate(value):
                    if isinstance(item, str) and item.strip() == "":
                        errors.append(f"{prefix}: empty string in {key}[{item_index}]")

        question_id = normalized_text(question.get("id", ""))
        if question_id:
            if question_id in seen_ids:
                errors.append(f"{prefix}: duplicate id {question_id} also at questions[{seen_ids[question_id]}]")
            seen_ids[question_id] = index

        category = question.get("type")
        if category not in QUESTION_TYPES:
            errors.append(f"{prefix}: invalid category/type {category!r}")

        difficulty = question.get("difficulty")
        if difficulty not in DIFFICULTIES:
            errors.append(f"{prefix}: invalid difficulty {difficulty!r}")

        choices = question.get("choices")
        if not isinstance(choices, list) or len(choices) != 4:
            errors.append(f"{prefix}: choices must have exactly 4 items")
        else:
            choice_texts = [normalized_text(choice) for choice in choices]
            if len(set(choice_texts)) != len(choice_texts):
                errors.append(f"{prefix}: duplicate choices")
            answer = question.get("answer")
            if not isinstance(answer, int) or answer < 0 or answer >= len(choices):
                errors.append(f"{prefix}: answer out of range")

        for key in ("tags", "synonyms", "antonyms"):
            value = question.get(key)
            if not isinstance(value, list) or not all(isinstance(item, str) for item in value):
                errors.append(f"{prefix}: {key} must be a string list")
        if not isinstance(question.get("meaning"), str) or not question.get("meaning", "").strip():
            errors.append(f"{prefix}: meaning is required")
        if not isinstance(question.get("example"), str) or not question.get("example", "").strip():
            errors.append(f"{prefix}: example is required")
        target = question.get("target", "")
        if target is not None and not isinstance(target, str):
            errors.append(f"{prefix}: target must be a string when present")
        if question.get("type") in CONTEXT_QUESTION_TYPES and requires_context_schema(payload):
            prompt = normalized_text(question.get("prompt", ""))
            expected_prompt = FIXED_PROMPTS.get(str(question.get("type")), "")
            sentence_text = normalized_text(question.get("sentence", ""))
            target_text = normalized_text(target)
            question_text = normalized_text(question.get("question", ""))
            if not prompt:
                errors.append(f"{prefix}: prompt is required for context question data")
            elif expected_prompt and prompt != expected_prompt:
                errors.append(f"{prefix}: prompt must be fixed for type {question.get('type')!r}")
            if not sentence_text:
                errors.append(f"{prefix}: sentence is required for context question data")
            if sentence_text and question_text != sentence_text:
                errors.append(f"{prefix}: question must duplicate sentence for backward compatibility")
            if not target_text:
                errors.append(f"{prefix}: target is required for context question data")
            elif sentence_text and target_text not in sentence_text:
                errors.append(f"{prefix}: target must exactly appear in sentence")
            if question.get("type") in {"writing", "compound"}:
                if not normalized_text(question.get("answer_text", "")):
                    errors.append(f"{prefix}: answer_text is required for {question.get('type')}")
            if question.get("type") == "homophone":
                if not normalized_text(question.get("reading", "")):
                    errors.append(f"{prefix}: reading is required for homophone")
            if question.get("type") == "compound" and isinstance(choices, list):
                if not all(isinstance(choice, str) and len(choice.strip()) == 1 for choice in choices):
                    errors.append(f"{prefix}: compound choices must be single kanji characters")

        question_key = "|".join(
            [
                normalized_text(question.get("type", "")),
                normalized_text(question.get("sentence", question.get("question", ""))),
                normalized_text(question.get("target", "")),
                normalized_text(question.get("choices", "")),
            ]
        )
        if question_key in seen_questions:
            errors.append(f"{prefix}: duplicate question content also at {seen_questions[question_key]}")
        seen_questions[question_key] = f"questions[{index}]"
    return errors


def paths_from_args(input_path: Path | None) -> list[Path]:
    if input_path:
        return [input_path]
    candidates = [path for path in (latest_json(GENERATED_DIR), latest_json(IMPROVED_DIR)) if path]
    if candidates:
        return [max(candidates, key=lambda item: item.stat().st_mtime)]
    return sorted(ASSETS_DATA_DIR.glob("grade*.json")) + sorted(ASSETS_DATA_DIR.glob("kanken*.json"))


def main() -> int:
    parser = argparse.ArgumentParser(description="Validate question JSON without AI.")
    parser.add_argument("--input", type=Path)
    args = parser.parse_args()

    all_errors: list[str] = []
    for path in paths_from_args(args.input):
        try:
            payload = read_json(path)
        except Exception as error:
            all_errors.append(f"{path}: JSON parse error: {error}")
            continue
        all_errors.extend(validate_payload(payload, str(path)))

    if all_errors:
        print("Validation failed:")
        for error in all_errors:
            print(f"- {error}")
        return 1
    print("Validation passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
