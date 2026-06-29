from __future__ import annotations

import json
import os
from pathlib import Path
from typing import Any


PIPELINE_DIR = Path(__file__).resolve().parent
PROJECT_ROOT = PIPELINE_DIR.parents[1]
ASSETS_DATA_DIR = PROJECT_ROOT / "assets" / "data"
OUTPUT_DIR = PIPELINE_DIR / "output"
GENERATED_DIR = OUTPUT_DIR / "generated"
REVIEWS_DIR = OUTPUT_DIR / "reviews"
IMPROVED_DIR = OUTPUT_DIR / "improved"
REPORTS_DIR = OUTPUT_DIR / "reports"
BACKUPS_DIR = PIPELINE_DIR / "backups"

MODEL = os.getenv("OPENAI_MODEL", "gpt-4.1-mini")
REVIEW_MODEL = os.getenv("OPENAI_REVIEW_MODEL", MODEL)
API_BASE = os.getenv("OPENAI_API_BASE", "https://api.openai.com/v1")

QUESTION_TYPES = {
    "reading",
    "writing",
    "compound",
    "sentence",
    "homophone",
    "opposite",
    "synonym",
    "yojijukugo",
    "radical",
    "correction",
}
CONTEXT_QUESTION_TYPES = {
    "reading",
    "writing",
    "compound",
    "sentence",
    "homophone",
    "opposite",
    "synonym",
}
FIXED_PROMPTS = {
    "reading": "線を引いた言葉の読みを選びなさい。",
    "writing": "線を引いた言葉を漢字で書きなさい。",
    "compound": "文に合うように、□に入る漢字を選びなさい。",
    "sentence": "文の意味に合う言葉を選びなさい。",
    "homophone": "文の意味に合う漢字を選びなさい。",
    "opposite": "線を引いた言葉と反対の意味の言葉を選びなさい。",
    "synonym": "線を引いた言葉と意味が近い言葉を選びなさい。",
}
DIFFICULTIES = {1, 2, 3, 4, 5}
TARGETS = {
    **{f"grade{i}": {"kind": "grade", "grade": i, "kanken": 11 - i} for i in range(1, 7)},
    **{f"kanken{i}": {"kind": "kanken", "grade": {10: 1, 9: 2, 8: 3, 7: 4, 6: 5, 5: 6, 4: 6, 3: 6}[i], "kanken": i} for i in (10, 9, 8, 7, 6, 5, 4, 3)},
}
REQUIRED_FIELDS = {
    "id",
    "grade",
    "kanken",
    "difficulty",
    "type",
    "question",
    "choices",
    "answer",
    "meaning",
    "example",
    "mnemonic",
    "synonyms",
    "antonyms",
    "tags",
}
OPTIONAL_FIELDS = {
    "prompt",
    "sentence",
    "target",
    "answer_text",
    "reading",
}


def load_env() -> None:
    env_path = PROJECT_ROOT / ".env"
    if not env_path.exists():
        env_path = PIPELINE_DIR / ".env"
    if not env_path.exists():
        return
    for raw_line in env_path.read_text(encoding="utf-8").splitlines():
        line = raw_line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, value = line.split("=", 1)
        os.environ.setdefault(key.strip(), value.strip().strip('"').strip("'"))


def openai_api_key() -> str:
    load_env()
    key = os.getenv("OPENAI_API_KEY", "").strip()
    if not key:
        raise RuntimeError("OPENAI_API_KEY is missing. Add it to .env.")
    return key


def ensure_directories() -> None:
    for path in (GENERATED_DIR, REVIEWS_DIR, IMPROVED_DIR, REPORTS_DIR, BACKUPS_DIR):
        path.mkdir(parents=True, exist_ok=True)


def read_json(path: Path) -> Any:
    return json.loads(path.read_text(encoding="utf-8"))


def write_json(path: Path, value: Any) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(value, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def parse_json_text(text: str) -> Any:
    cleaned = text.strip()
    if cleaned.startswith("```"):
        lines = cleaned.splitlines()
        if lines and lines[0].startswith("```"):
            lines = lines[1:]
        if lines and lines[-1].startswith("```"):
            lines = lines[:-1]
        cleaned = "\n".join(lines).strip()
    try:
        return json.loads(cleaned)
    except json.JSONDecodeError:
        start = cleaned.find("{")
        end = cleaned.rfind("}")
        if start >= 0 and end > start:
            return json.loads(cleaned[start : end + 1])
        raise


def latest_json(directory: Path) -> Path | None:
    if not directory.exists():
        return None
    files = sorted(directory.glob("*.json"), key=lambda item: item.stat().st_mtime, reverse=True)
    return files[0] if files else None


def timestamp() -> str:
    from datetime import datetime

    return datetime.now().strftime("%Y%m%d_%H%M%S")


def questions_from_payload(payload: Any) -> list[dict[str, Any]]:
    if isinstance(payload, list):
        return payload
    if isinstance(payload, dict) and isinstance(payload.get("questions"), list):
        return payload["questions"]
    raise ValueError("JSON must be a question list or an object with a questions list.")


def course_file_for_target(target: str) -> Path:
    if target not in TARGETS:
        raise ValueError(f"Unknown target: {target}")
    info = TARGETS[target]
    if info["kind"] == "grade":
        return ASSETS_DATA_DIR / f"grade{info['grade']}.json"
    return ASSETS_DATA_DIR / f"kanken{info['kanken']}.json"
