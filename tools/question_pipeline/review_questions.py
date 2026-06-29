from __future__ import annotations

import argparse
import json
import urllib.request
from pathlib import Path
from typing import Any

from config import API_BASE, GENERATED_DIR, REPORTS_DIR, REVIEWS_DIR, REVIEW_MODEL, ensure_directories, latest_json, openai_api_key, parse_json_text, read_json, timestamp, write_json
from prompts import review_prompt


def normalize_review(review: dict[str, Any], total: int) -> dict[str, Any]:
    items = review.get("items", [])
    if not isinstance(items, list):
        items = []
        review["items"] = items

    counts = {"accept": 0, "revise": 0, "reject": 0}
    scores: list[int] = []
    issue_counts: dict[str, int] = {}
    for item in items:
        if not isinstance(item, dict):
            continue
        adoption = str(item.get("adoption", "")).strip().lower()
        if adoption not in counts:
            score = int(item.get("score", 0) or 0)
            unique = item.get("unique_answer")
            if score >= 90 and unique is not False:
                adoption = "accept"
            elif score >= 70:
                adoption = "revise"
            else:
                adoption = "reject"
            item["adoption"] = adoption
        counts[adoption] += 1
        scores.append(int(item.get("score", 0) or 0))
        if adoption != "accept":
            item["needs_improvement"] = True
        if item.get("unique_answer") is False:
            item["needs_improvement"] = True
        for issue in item.get("issues", []):
            if isinstance(issue, str) and issue.strip():
                issue_counts[issue] = issue_counts.get(issue, 0) + 1

    average_score = round(sum(scores) / len(scores), 1) if scores else 0
    main_issues = [
        issue
        for issue, _count in sorted(
            issue_counts.items(), key=lambda pair: pair[1], reverse=True
        )[:5]
    ]
    review["summary"] = {
        "total": total,
        "accept": counts["accept"],
        "revise": counts["revise"],
        "reject": counts["reject"],
        "average_score": average_score,
        "main_issues": main_issues,
    }
    review["overall_score"] = int(review.get("overall_score") or average_score)
    return review


def call_openai(prompt: str) -> dict[str, Any]:
    body = {
        "model": REVIEW_MODEL,
        "input": [
            {"role": "system", "content": "You are a strict educational material reviewer. Return JSON only."},
            {"role": "user", "content": prompt},
        ],
        "temperature": 0.2,
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


def main() -> int:
    parser = argparse.ArgumentParser(description="Review generated questions with OpenAI.")
    parser.add_argument("input_positional", nargs="?", type=Path)
    parser.add_argument("--input", type=Path)
    parser.add_argument("--output", type=Path)
    parser.add_argument("--report", type=Path)
    args = parser.parse_args()

    ensure_directories()
    input_path = args.input or args.input_positional or latest_json(GENERATED_DIR)
    if not input_path:
        raise SystemExit("No generated file found.")
    payload = read_json(input_path)
    questions = payload.get("questions", []) if isinstance(payload, dict) else []
    review = call_openai(review_prompt(payload))
    review = normalize_review(review, len(questions))
    review["input"] = str(input_path)
    if isinstance(payload, dict) and "target" in payload:
        review["target"] = payload["target"]
    if isinstance(payload, dict) and "format_version" in payload:
        review["format_version"] = payload["format_version"]
    stamp = timestamp()
    output_path = args.output or REVIEWS_DIR / f"{stamp}_review.json"
    report_path = args.report or REPORTS_DIR / (
        f"{input_path.stem}_review.json"
        if input_path.name.startswith("grade") or input_path.parent.name == "data"
        else f"{stamp}_review_report.json"
    )
    write_json(output_path, review)
    write_json(report_path, review)
    print(f"review score: {review.get('overall_score', 'unknown')}/100")
    print(f"review: {output_path}")
    print(f"report: {report_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
