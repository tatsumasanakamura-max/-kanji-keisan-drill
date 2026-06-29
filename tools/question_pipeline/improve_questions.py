from __future__ import annotations

import argparse
import json
import urllib.request
from pathlib import Path
from typing import Any

from config import API_BASE, GENERATED_DIR, IMPROVED_DIR, REPORTS_DIR, REVIEWS_DIR, MODEL, ensure_directories, latest_json, openai_api_key, parse_json_text, questions_from_payload, read_json, timestamp, write_json
from prompts import improve_prompt


def review_requires_improvement(review: dict[str, Any]) -> bool:
    if int(review.get("overall_score", 0)) < 90:
        return True
    for item in review.get("items", []):
        if not isinstance(item, dict):
            continue
        adoption = str(item.get("adoption", "")).strip().lower()
        if adoption in {"revise", "reject"}:
            return True
        if item.get("unique_answer") is False:
            return True
        if item.get("needs_improvement") is True:
            return True
        if int(item.get("score", 100)) < 80:
            return True
        naturalness = item.get("naturalness_check", {})
        if isinstance(naturalness, dict):
            if int(naturalness.get("natural_japanese", 100) or 0) < 80:
                return True
            if int(naturalness.get("ai_like_score", 0) or 0) >= 40:
                return True
        educational = item.get("educational_quality", {})
        if isinstance(educational, dict):
            if int(educational.get("textbook_quality", 100) or 0) < 80:
                return True
            if int(educational.get("meaning_example_consistency", 100) or 0) < 80:
                return True
        uniqueness = item.get("uniqueness_check", {})
        if isinstance(uniqueness, dict):
            answer = str(uniqueness.get("answer", "")).strip().upper()
            if answer == "NO":
                return True
    return False


def call_openai(prompt: str) -> dict[str, Any]:
    body = {
        "model": MODEL,
        "input": [
            {"role": "system", "content": "Improve educational questions. Return JSON only."},
            {"role": "user", "content": prompt},
        ],
        "temperature": 0.3,
    }
    request = urllib.request.Request(
        f"{API_BASE.rstrip('/')}/responses",
        data=json.dumps(body, ensure_ascii=False).encode("utf-8"),
        headers={"Authorization": f"Bearer {openai_api_key()}", "Content-Type": "application/json"},
        method="POST",
    )
    with urllib.request.urlopen(request, timeout=180) as response:
        data = json.loads(response.read().decode("utf-8"))
    text = data.get("output_text", "")
    if not text:
        text = "".join(
            content.get("text", "")
            for item in data.get("output", [])
            for content in item.get("content", [])
            if content.get("type") in {"output_text", "text"}
        )
    return parse_json_text(text)


def merge_partial_improvements(
    original_questions: list[dict[str, Any]],
    improved: dict[str, Any],
) -> dict[str, Any]:
    improved_questions = improved.get("questions", [])
    if not isinstance(improved_questions, list):
        return {"questions": original_questions}
    if len(improved_questions) == len(original_questions):
        return improved

    by_id = {
        question.get("id"): question
        for question in improved_questions
        if isinstance(question, dict) and question.get("id")
    }
    merged = [by_id.get(question.get("id"), question) for question in original_questions]
    improved["questions"] = merged
    improved["partial_improvement_merged"] = True
    return improved


def main() -> int:
    parser = argparse.ArgumentParser(description="Improve questions based on review JSON.")
    parser.add_argument("--input", type=Path)
    parser.add_argument("--questions", type=Path)
    parser.add_argument("--review", type=Path)
    parser.add_argument("--output", type=Path)
    args = parser.parse_args()

    ensure_directories()
    input_path = args.input or args.questions or latest_json(GENERATED_DIR)
    review_path = args.review or latest_json(REVIEWS_DIR)
    if not input_path or not review_path:
        raise SystemExit("Input and review files are required.")

    payload = read_json(input_path)
    questions = questions_from_payload(payload)
    review = read_json(review_path)
    if not review_requires_improvement(review):
        improved = {"questions": questions, "adoption": "accepted_without_changes", "review": str(review_path)}
    else:
        improved = call_openai(improve_prompt(questions, review))
        improved = merge_partial_improvements(questions, improved)
        improved["adoption"] = "improved"
        improved["review"] = str(review_path)
    if isinstance(payload, dict) and "target" in payload:
        improved["target"] = payload["target"]
    elif isinstance(review, dict) and "target" in review:
        improved["target"] = review["target"]
    if isinstance(payload, dict) and "format_version" in payload:
        improved["format_version"] = payload["format_version"]
    stamp = timestamp()
    output_path = args.output or IMPROVED_DIR / f"{stamp}_improved.json"
    write_json(output_path, improved)
    write_json(
        REPORTS_DIR / f"{stamp}_improvement_report.json",
        {
            "input": str(input_path),
            "review": str(review_path),
            "output": str(output_path),
            "adoption": improved.get("adoption"),
            "questions": improved.get("questions", []),
        },
    )
    print(f"improved: {output_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
