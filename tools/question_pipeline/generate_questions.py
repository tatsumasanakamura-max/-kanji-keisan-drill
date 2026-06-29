from __future__ import annotations

import argparse
import json
import urllib.request
from pathlib import Path
from typing import Any

from config import API_BASE, GENERATED_DIR, MODEL, TARGETS, course_file_for_target, ensure_directories, openai_api_key, parse_json_text, read_json, timestamp, write_json
from prompts import generate_prompt


def call_openai(prompt: str) -> dict[str, Any]:
    body = {
        "model": MODEL,
        "input": [
            {"role": "system", "content": "Return valid JSON only."},
            {"role": "user", "content": prompt},
        ],
        "temperature": 0.4,
    }
    request = urllib.request.Request(
        f"{API_BASE.rstrip('/')}/responses",
        data=json.dumps(body).encode("utf-8"),
        headers={
            "Authorization": f"Bearer {openai_api_key()}",
            "Content-Type": "application/json",
        },
        method="POST",
    )
    with urllib.request.urlopen(request, timeout=180) as response:
        data = json.loads(response.read().decode("utf-8"))
    text = data.get("output_text")
    if not text:
        chunks: list[str] = []
        for item in data.get("output", []):
            for content in item.get("content", []):
                if content.get("type") in {"output_text", "text"}:
                    chunks.append(content.get("text", ""))
        text = "".join(chunks)
    return parse_json_text(text)


def existing_ids_for_target(target: str) -> list[str]:
    path = course_file_for_target(target)
    if not path.exists():
        return []
    payload = read_json(path)
    return [item.get("id", "") for item in payload.get("questions", []) if isinstance(item, dict)]


def main() -> int:
    parser = argparse.ArgumentParser(description="Generate kanji questions with OpenAI.")
    parser.add_argument("--target", required=True, choices=sorted(TARGETS))
    parser.add_argument("--type", required=True, choices=sorted({"reading", "writing", "compound", "sentence", "homophone", "opposite", "synonym", "yojijukugo", "radical", "correction"}))
    parser.add_argument("--count", required=True, type=int)
    parser.add_argument("--output", type=Path)
    args = parser.parse_args()

    if args.count < 1:
        raise SystemExit("--count must be 1 or greater.")

    ensure_directories()
    target_info = TARGETS[args.target]
    prompt = generate_prompt(
        args.target,
        int(target_info["grade"]),
        int(target_info["kanken"]),
        args.type,
        args.count,
        existing_ids_for_target(args.target),
    )
    payload = call_openai(prompt)
    if isinstance(payload, dict):
        payload.setdefault("target", args.target)
        payload.setdefault("type", args.type)
        payload.setdefault("count", args.count)
        payload.setdefault("format_version", "context-sentence-v3")
    output_path = args.output or GENERATED_DIR / f"{timestamp()}_{args.target}_{args.type}_{args.count}.json"
    write_json(output_path, payload)
    print(f"generated: {output_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
