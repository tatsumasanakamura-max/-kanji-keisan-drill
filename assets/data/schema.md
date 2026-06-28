# JSON Schema

This directory uses one JSON file per learning course. The app must not load every file at startup.

Required course files:

- `grade1.json` to `grade6.json`
- `kanken10.json`, `kanken9.json`, `kanken8.json`, `kanken7.json`, `kanken6.json`, `kanken5.json`, `kanken4.json`, `kanken3.json`

Kanji question format:

```json
{
  "id": "",
  "grade": 1,
  "kanken": 10,
  "difficulty": 1,
  "type": "reading",
  "question": "",
  "choices": [],
  "answer": 0,
  "meaning": "",
  "example": "",
  "mnemonic": "",
  "synonyms": [],
  "antonyms": [],
  "tags": []
}
```

`type` is enum-managed in Dart by `QuestionType`.

