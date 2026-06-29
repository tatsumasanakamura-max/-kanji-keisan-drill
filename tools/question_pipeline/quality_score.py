from __future__ import annotations

import argparse
from pathlib import Path
from typing import Any

from config import GENERATED_DIR, IMPROVED_DIR, REPORTS_DIR, ensure_directories, latest_json, questions_from_payload, read_json, timestamp, write_json
from validate_questions import validate_payload


def duplicate_errors(questions: list[dict[str, Any]]) -> list[str]:
    errors: list[str] = []
    ids: set[str] = set()
    signatures: set[str] = set()
    for question in questions:
        question_id = str(question.get("id", "")).strip()
        if question_id in ids:
            errors.append(f"duplicate id: {question_id}")
        ids.add(question_id)
        signature = (
            f"{question.get('type')}|{question.get('sentence', question.get('question'))}|"
            f"{question.get('target')}|{question.get('choices')}"
        )
        if signature in signatures:
            errors.append(f"duplicate question: {question_id}")
        signatures.add(signature)
    return errors


def missing_data_errors(questions: list[dict[str, Any]]) -> list[str]:
    errors: list[str] = []
    for question in questions:
        question_id = str(question.get("id", "<no-id>"))
        for key in ("meaning", "example", "tags"):
            value = question.get(key)
            if value is None or value == "" or value == []:
                errors.append(f"{question_id}: missing {key}")
    return errors


def category_errors(questions: list[dict[str, Any]]) -> list[str]:
    return [
        f"{question.get('id', '<no-id>')}: type={question.get('type')} difficulty={question.get('difficulty')}"
        for question in questions
        if not isinstance(question.get("difficulty"), int)
    ]


def score_file(input_path: Path) -> dict[str, Any]:
    report: dict[str, Any] = {
        "input": str(input_path),
        "score": 0,
        "sections": {},
        "errors": [],
    }
    try:
        payload = read_json(input_path)
        questions = questions_from_payload(payload)
        report["sections"]["json_quality"] = {"score": 20, "errors": []}
    except Exception as error:
        report["sections"]["json_quality"] = {"score": 0, "errors": [str(error)]}
        report["errors"].append(str(error))
        return report

    validation_errors = validate_payload(payload, str(input_path))
    syntax_score = 20 if not validation_errors else max(0, 20 - len(validation_errors) * 2)
    dupes = duplicate_errors(questions)
    missing = missing_data_errors(questions)
    categories = category_errors(questions)

    sections = {
        "syntax": {"score": syntax_score, "errors": validation_errors},
        "duplicates": {"score": 20 if not dupes else max(0, 20 - len(dupes) * 5), "errors": dupes},
        "missing_data": {"score": 20 if not missing else max(0, 20 - len(missing) * 3), "errors": missing},
        "category_consistency": {"score": 20 if not categories else max(0, 20 - len(categories) * 5), "errors": categories},
    }
    report["sections"].update(sections)
    report["score"] = sum(section["score"] for section in report["sections"].values())
    report["errors"] = [error for section in report["sections"].values() for error in section["errors"]]
    return report


def main() -> int:
    parser = argparse.ArgumentParser(description="Score generated question quality.")
    parser.add_argument("--input", type=Path)
    parser.add_argument("--report", type=Path)
    args = parser.parse_args()

    ensure_directories()
    candidates = [path for path in (latest_json(GENERATED_DIR), latest_json(IMPROVED_DIR)) if path]
    input_path = args.input or (max(candidates, key=lambda item: item.stat().st_mtime) if candidates else None)
    if not input_path:
        raise SystemExit("No input file found. Run generate_questions.py first or pass --input.")

    report = score_file(input_path)
    report_path = args.report or REPORTS_DIR / f"{timestamp()}_quality_score.json"
    write_json(report_path, report)
    print(f"quality score: {report['score']}/100")
    print(f"report: {report_path}")
    return 0 if report["score"] >= 80 else 1


if __name__ == "__main__":
    raise SystemExit(main())
