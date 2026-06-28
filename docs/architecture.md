# Architecture

The app keeps startup fast by loading only common metadata at boot. Course question files are loaded lazily through `QuestionRepository.loadCourse`.

## Layers

- `core/models`: immutable data models for questions, progress, courses, and study modes.
- `core/data`: asset loading, JSON decoding, validation, and per-course cache.
- `core/services`: question selection algorithms.
- `core/state`: `GameController` coordinates profile, progress, scoring, difficulty, and persistence.
- `features`: screen-level UI.

## Data Flow

1. Home selects a `StudyMode`.
2. Course selection stores either grade mode or Kanken mode in `AppProfile`.
3. The quiz screen asks `GameController` for the selected `StudyCourse`.
4. `QuestionRepository` loads only `assets/data/gradeN.json` or `assets/data/kankenN.json`.
5. `QuestionPicker` chooses the next question using new/weak/review weighting.
6. `GameController` persists result history through Hive.

## Scale

Question files are independent JSON assets, so 10000+ questions can be split by grade, Kanken level, or future event packs without loading all data at once.

