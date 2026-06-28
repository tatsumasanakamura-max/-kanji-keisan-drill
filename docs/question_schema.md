# Question Schema

Canonical files live in `assets/data/`.

- `grade1.json` through `grade6.json`
- `kanken10.json` through `kanken3.json`
- `common_data.json`

Each course file contains:

```json
{
  "grade": 1,
  "label": "小学1年",
  "questions": [],
  "mathQuestions": []
}
```

Each kanji question uses:

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

Supported `type` values:

- `reading`
- `writing`
- `compound`
- `sentence`
- `homophone`
- `opposite`
- `synonym`
- `yojijukugo`
- `radical`
- `correction`

Rules:

- `id` must be unique within all question assets.
- `difficulty` must be 1 through 5.
- `answer` is the zero-based index in `choices`.
- `choices` should include plausible distractors, not arbitrary wrong answers.
- Explanatory fields should be filled where available because the answer screen displays them.

