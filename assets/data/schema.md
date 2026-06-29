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
  "prompt": "",
  "sentence": "",
  "target": "",
  "choices": [],
  "answer": 0,
  "answer_text": "",
  "reading": "",
  "meaning": "",
  "example": "",
  "mnemonic": "",
  "synonyms": [],
  "antonyms": [],
  "tags": []
}
```

`type` is enum-managed in Dart by `QuestionType`.

For new `reading`, `writing`, `compound`, `sentence`, `homophone`, `opposite`,
and `synonym` questions, use context-question fields:

- `prompt`: fixed instruction for the question type.
- `sentence`: natural sentence shown to the learner.
- `target`: exact text inside `sentence` to bold and underline.
- `question`: duplicate `sentence` for backward compatibility.
- `answer_text`: required for `writing` and `compound`.
- `reading`: required for `homophone`.

Legacy data with only `question` is still valid for backward compatibility.
