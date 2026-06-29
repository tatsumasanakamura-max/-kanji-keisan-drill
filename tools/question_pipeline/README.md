# AI question generation pipeline

Kanji Keisan Quest の `assets/data/*.json` と同じスキーマで、AI生成、検証、品質採点、AIレビュー、AI改善、統合を行うためのCLIです。

Codexが大量の問題を直接作るのではなく、継続的に問題を追加、検証、改善できる道具として使います。

## Setup

Python 3.10 以上を使用します。標準ライブラリのみで動くため、追加パッケージは不要です。

プロジェクトルートに `.env` を作成します。

```text
OPENAI_API_KEY=sk-...
OPENAI_MODEL=gpt-4.1-mini
OPENAI_REVIEW_MODEL=gpt-4.1-mini
```

実行前に移動します。

```bash
cd tools/question_pipeline
```

## Generate

```bash
python generate_questions.py --target grade1 --type reading --count 10
```

出力先:

```text
output/generated/
```

対象:

```text
grade1 grade2 grade3 grade4 grade5 grade6
kanken10 kanken9 kanken8 kanken7 kanken6 kanken5 kanken4 kanken3
```

カテゴリ:

```text
reading writing compound sentence homophone opposite synonym yojijukugo radical correction
```

生成プロンプトには以下を必ず含めています。

- ダミー問題禁止
- プレースホルダー禁止
- 実際に学習効果がある問題
- 誤答は実際に迷う内容
- 小学生向け例文
- JSONのみ
- Markdown禁止
- 説明禁止

## Validate

AIを使わず、PythonのみでJSONを検証します。

```bash
python validate_questions.py
```

最新の `output/generated/*.json` があればそれを検証します。明示する場合:

```bash
python validate_questions.py --input output/generated/example.json
```

検証項目:

- JSON構文
- 必須項目
- answer範囲
- choices数
- difficulty
- tags
- meaning
- example
- 重複ID
- 重複問題
- 重複choices
- 空文字
- 不正カテゴリ

## Quality Score

```bash
python quality_score.py
```

100点満点で採点し、`output/reports/` にレポートを保存します。

採点項目:

- JSON品質 20点
- 構文 20点
- 重複 20点
- データ欠損 20点
- カテゴリ整合性 20点

## Review

OpenAI APIで教材監修者レビューを行います。

```bash
python review_questions.py
```

結果は `output/reviews/` にJSONで保存されます。

評価項目:

- 学年適合
- 漢検級適合
- 選択肢品質
- 誤答品質
- 学習効果
- 意味
- 例文
- 難易度
- 不自然表現
- 改善案

## Improve

レビュー結果を使って問題だけを改善します。スキーマ変更は禁止しています。

```bash
python improve_questions.py
```

レビューの `overall_score` が90点以上なら、改善なしで採用候補として `output/improved/` に保存します。90点未満ならOpenAIで改善します。

## Merge

改善済み、またはレビューで採用可となった問題だけを `assets/data` に統合します。統合前に必ずバックアップを作成します。

```bash
python merge_questions.py
```

安全確認だけ行う場合:

```bash
python merge_questions.py --dry-run
```

バックアップ先:

```text
tools/question_pipeline/backups/
```

## Required Flow

```text
1. generate
2. validate
3. quality_score
4. review
5. improve, only when the review score is below 90
6. validate
7. quality_score
8. merge
```

80点未満は改善必須、90点以上はそのまま採用候補にできます。

## Common Errors

`OPENAI_API_KEY is missing`

`.env` に `OPENAI_API_KEY` を追加してください。

`Validation failed`

表示された問題IDと項目を確認してください。特に `answer` の範囲、`choices` の重複、`meaning` と `example` の空欄がよくある原因です。

`ID already exists`

既存の `assets/data` とIDが重複しています。生成し直すか、改善JSONのIDを既存ルールに合わせて変更してください。

`Question content already exists`

同じカテゴリ、問題文、選択肢の問題がすでにあります。重複統合を防ぐために停止しています。

## Scale Notes

1万問以上を扱う前提で、生成物、レビュー、改善済みデータ、レポート、バックアップを分離しています。本体のJSON構造は変えず、統合時にだけ `assets/data` に書き込むため、段階ごとの差し戻しや再レビューがしやすい構成です。

将来は `config.py` と `prompts.py` を差し替えることで、GPTモデル変更、Gemini、Claude、ローカルLLM、Firebase保存、Web管理画面、CSV入出力、PDF出力へ拡張できます。
