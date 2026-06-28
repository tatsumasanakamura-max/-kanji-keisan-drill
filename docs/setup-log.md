# Setup Log

## Goal

Set up Flutter SDK and verify the `kanji_keisan_quest` project for Windows + Web.

## Environment

- Flutter SDK installed locally in `.tools/flutter`
- User PATH updated with `.tools/flutter/bin`
- `PUB_CACHE` redirected to a workspace-local cache
- `APPDATA` / `LOCALAPPDATA` redirected to temp paths for tool execution

## Commands Run

```powershell
flutter --version
flutter doctor -v
flutter create --platforms=windows,web .
flutter pub get
flutter analyze
flutter run -d chrome --web-port=5000 --web-hostname=127.0.0.1
flutter build web
flutter build windows
```

## What Worked

- Flutter SDK installed successfully
- `flutter doctor -v` runs successfully
- `flutter create --platforms=windows,web .` added Windows and Web runners
- `flutter pub get` succeeded after moving Pub cache into the workspace
- `flutter run -d chrome` started and served the app on `http://127.0.0.1:5000`
- `flutter build web` succeeded

## Issues Found

- `flutter analyze` failed in this environment with an analysis server JSON parse error
- `flutter build windows` is still blocked here by Flutter's symlink-support check
- `flutter doctor -v` reports Visual Studio is not installed, so Windows desktop tooling is incomplete

## Fixes Applied

- Installed Flutter 3.44.4 stable into `.tools/flutter`
- Added Flutter SDK bin path to the user PATH
- Enabled Windows desktop and Web support in the project generation step
- Redirected `PUB_CACHE` away from restricted AppData storage
- Enabled Windows Developer Mode registry keys for the current user

## Web Verification

- Chrome run started successfully
- Local HTTP check returned `200` on `http://127.0.0.1:5000`
- Web build output is in `build/web`

## Windows Verification

- Not fully completed in this environment
- `flutter doctor -v` still reports missing Visual Studio with the `Desktop development with C++` workload
- Install Visual Studio Community 2022 or Build Tools with that workload, then rerun:

```powershell
flutter build windows
```

## Next Steps

1. Install Visual Studio Community 2022
2. Add the `Desktop development with C++` workload
3. Rerun `flutter build windows`
4. Rerun `flutter analyze` in a fully permissive Windows session

## Game Implementation Session

- Wired `assets/data/sample_questions.json` into the reading and math screens
- Added shared game state for points, experience, combo, weak items, and results
- Correct answers now award points and exp
- Wrong answers now upsert the weakness list
- Results screen now shows live progress and recent attempts
- Web build passed again after wiring game logic
- Web runtime check on `http://127.0.0.1:5001` returned `200`

## Writing Canvas Session

- Replaced the writing screen with a touch-friendly canvas that supports pen input, eraser mode, undo, clear, and a large done button
- Added writing practice rewards at 15 points and 15 experience
- Added `writingPracticeCount` to the profile model and results screen
- Fixed the sample question JSON so Japanese reading and writing prompts display correctly
- Verified the updated web build with a static browser run on `build/web`
- Confirmed the writing screen can draw a stroke, show the completion overlay, and persist the updated stats back to the home screen

## Question Bank Expansion Session

- Expanded the sample question bank to 20 questions per grade for kanji reading, kanji writing, and math
- Added grade-spanning Japanese vocab and arithmetic samples for grades 1 through 9
- Updated the math question model so decimal answers can be parsed and displayed
- Verified `flutter run -d chrome` after the fix and confirmed the home screen, writing screen, and math screen render with the larger dataset
- Re-ran `flutter build web` after the data expansion and the build still succeeded

## GitHub Pages Session

- Added `.github/workflows/deploy.yml` for GitHub Actions Pages deployment
- Configured web build with `--base-href "/-kanji-keisan-drill/"`
- Added `web/404.html` so GitHub Pages can fall back to the Flutter app on direct route access
- Updated `web/index.html` title and description to the app name
- Documented the Pages URL in `README.md`

## Grade-Specific Question Bank Session

- Split the shared question bank into `assets/data/grades/grade_1.json` through `grade_9.json`
- Added `assets/data/common_data.json` for the shared daily challenge, gacha, and encyclopedia content
- Updated the repository to load questions by `selectedGrade`
- Switched the reading, writing, and math screens to grade-specific random question order
- Added stronger result highlighting for reading answers and larger touch targets for the math input flow
- Updated the writing screen to reuse the new grade-specific bank and preserve the reward flow
- Added the new asset directory to `pubspec.yaml`
- Added a generator script at `tools/generate_questions.mjs` so the split can be recreated from the legacy sample file
- Updated README and setup notes with the new file layout and iPad Safari check list
