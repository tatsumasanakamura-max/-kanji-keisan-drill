# Context Question Schema

New generated questions for these types must use the context schema:

- `reading`
- `writing`
- `compound`
- `sentence`
- `homophone`
- `opposite`
- `synonym`

Base shape:

```json
{
  "prompt": "",
  "sentence": "",
  "target": "",
  "choices": [],
  "answer": 0
}
```

The app displays:

```text
prompt

sentence
```

The exact `target` text inside `sentence` is rendered bold and underlined.

Compatibility rule:

- Keep `question` as a duplicate of `sentence`.
- Existing legacy data with only `question` remains valid.

Type-specific fields:

- `writing`: add `answer_text`.
- `compound`: add `answer_text`; choices must be single kanji characters.
- `homophone`: add `reading`; choices must share that reading.

Quality rules:

- `sentence` must be natural Japanese.
- `target` must exist in `sentence`.
- `prompt` must be fixed by type.
- `meaning` explains the correct answer.
- `example` is the completed natural sentence.
- Choices are real words or kanji only.
- Distractors should be plausible and educational.
