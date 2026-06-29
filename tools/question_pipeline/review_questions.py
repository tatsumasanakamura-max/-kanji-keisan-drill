from __future__ import annotations

import argparse
import json
import urllib.request
from pathlib import Path
from typing import Any

from config import API_BASE, GENERATED_DIR, REPORTS_DIR, REVIEWS_DIR, REVIEW_MODEL, ensure_directories, latest_json, openai_api_key, parse_json_text, read_json, timestamp, write_json
from prompts import review_prompt


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
    parser.add_argument("--input", type=Path)
    parser.add_argument("--output", type=Path)
    args = parser.parse_args()

    ensure_directories()
    input_path = args.input or latest_json(GENERATED_DIR)
    if not input_path:
        raise SystemExit("No generated file found.")
    payload = read_json(input_path)
    review = call_openai(review_prompt(payload))
    review["input"] = str(input_path)
    if isinstance(payload, dict) and "target" in payload:
        review["target"] = payload["target"]
    if isinstance(payload, dict) and "format_version" in payload:
        review["format_version"] = payload["format_version"]
    stamp = timestamp()
    output_path = args.output or REVIEWS_DIR / f"{stamp}_review.json"
    write_json(output_path, review)
    write_json(REPORTS_DIR / f"{stamp}_review_report.json", review)
    print(f"review score: {review.get('overall_score', 'unknown')}/100")
    print(f"review: {output_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
