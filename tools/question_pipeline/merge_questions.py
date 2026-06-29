from __future__ import annotations

import argparse
import shutil
from pathlib import Path
from typing import Any

from config import ASSETS_DATA_DIR, BACKUPS_DIR, IMPROVED_DIR, TARGETS, course_file_for_target, ensure_directories, latest_json, questions_from_payload, read_json, timestamp, write_json
from validate_questions import validate_payload


def infer_target(questions: list[dict[str, Any]]) -> str:
    if not questions:
        raise ValueError("No questions to merge.")
    first = questions[0]
    grade = first.get("grade")
    kanken = first.get("kanken")
    for name, info in TARGETS.items():
        if info["kind"] == "grade" and info["grade"] == grade:
            return name
    for name, info in TARGETS.items():
        if info["kind"] == "kanken" and info["kanken"] == kanken:
            return name
    raise ValueError(f"Cannot infer target from grade={grade}, kanken={kanken}. Pass --target.")


def backup_assets() -> Path:
    backup_dir = BACKUPS_DIR / f"assets_data_{timestamp()}"
    shutil.copytree(ASSETS_DATA_DIR, backup_dir)
    return backup_dir


def merge(course: dict[str, Any], incoming: list[dict[str, Any]]) -> dict[str, Any]:
    existing = course.setdefault("questions", [])
    existing_ids = {item.get("id") for item in existing if isinstance(item, dict)}
    existing_signatures = {
        f"{item.get('type')}|{item.get('sentence', item.get('question'))}|{item.get('target')}|{item.get('choices')}"
        for item in existing
        if isinstance(item, dict)
    }
    for question in incoming:
        question_id = question.get("id")
        signature = (
            f"{question.get('type')}|{question.get('sentence', question.get('question'))}|"
            f"{question.get('target')}|{question.get('choices')}"
        )
        if question_id in existing_ids:
            raise ValueError(f"ID already exists: {question_id}")
        if signature in existing_signatures:
            raise ValueError(f"Question content already exists: {question_id}")
        existing.append(question)
        existing_ids.add(question_id)
        existing_signatures.add(signature)
    return course


def main() -> int:
    parser = argparse.ArgumentParser(description="Merge improved questions into assets/data.")
    parser.add_argument("--input", type=Path)
    parser.add_argument("--target", choices=sorted(TARGETS))
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args()

    ensure_directories()
    input_path = args.input or latest_json(IMPROVED_DIR)
    if not input_path:
        raise SystemExit("No improved file found. Run improve_questions.py first or pass --input.")
    incoming_payload = read_json(input_path)
    errors = validate_payload(incoming_payload, str(input_path))
    if errors:
        print("Merge blocked by validation errors:")
        for error in errors:
            print(f"- {error}")
        return 1

    incoming = questions_from_payload(incoming_payload)
    payload_target = incoming_payload.get("target") if isinstance(incoming_payload, dict) else None
    target = args.target or payload_target or infer_target(incoming)
    course_path = course_file_for_target(target)
    course = read_json(course_path)
    merged = merge(course, incoming)

    if args.dry_run:
        print(f"dry-run ok: {len(incoming)} questions can merge into {course_path}")
        return 0

    backup_dir = backup_assets()
    write_json(course_path, merged)
    print(f"merged {len(incoming)} questions into {course_path}")
    print(f"backup: {backup_dir}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
