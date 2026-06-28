# 漢字・計算クエスト Ver1.0

個人利用向けの Flutter アプリ土台です。

## 対応方針

- Flutter で実装
- Windows アプリ対応
- Web 版対応
- iPad は Safari で開いてホーム画面追加でアプリ風に使う
- App Store / Google Play 公開はしない
- OpenAI API は Ver1.0 では使わない

## Ver1.0 の構成

- ホーム画面
- 学年選択
- 漢字読み 4 択クイズ
- 漢字書き練習
- 計算ドリル
- ポイント
- 経験値
- レベルアップ
- コンボ演出
- 今日のチャレンジ
- ガチャ
- 図鑑
- 苦手リスト
- 成績画面
- 設定画面

## 画面遷移

- `/` : ホーム
- `/grade` : 学年選択
- `/kanji-reading` : 漢字読み 4 択クイズ
- `/kanji-writing` : 漢字書き練習
- `/math-drill` : 計算ドリル
- `/challenge` : 今日のチャレンジ
- `/gacha` : ガチャ
- `/encyclopedia` : 図鑑
- `/weakness` : 苦手リスト
- `/results` : 成績画面
- `/settings` : 設定画面

## データモデル

- `AppProfile`: 学年、ポイント、経験値、レベル、コンボ、成績の基礎情報
- `KanjiReadingQuestion`: 漢字読み 4 択クイズ
- `KanjiWritingPrompt`: 漢字書き練習用の出題情報
- `MathQuestion`: 計算ドリル用の出題情報
- `DailyChallenge`: 今日のチャレンジ
- `GachaReward`: ガチャ報酬
- `EncyclopediaEntry`: 図鑑項目
- `WeakItem`: 苦手記録
- `ResultSummary`: 成績の集計結果

## 保存方式

- 端末側の保存は `Hive`
- Windows ではローカル保存
- Web ではブラウザ内保存
- Ver1.0 では Firebase / ログイン / 課金 / オンラインランキングはなし

## サンプル問題

`assets/data/sample_questions.json` に学年別のサンプル問題を入れています。

## セットアップ結果

- Flutter SDK: `.tools/flutter`
- Web build: `build/web`
- Chrome run: `http://127.0.0.1:5000`
- Windows build: この環境では Visual Studio 未導入のため未完了

## セットアップログ

- [docs/setup-log.md](docs/setup-log.md)

## 次の実装候補

1. JSON から問題を読み込む
2. 正誤判定とポイント加算
3. コンボとレベルアップ演出
4. 書き取りキャンバスの入力保存
5. 図鑑・苦手リスト・成績集計の実装

## Writing Canvas Update

- Added a large, touch-friendly kanji writing canvas with pen, eraser, undo, clear, and done controls
- Writing completion now awards 15 points and 15 EXP
- Writing practice count is shown in the home hero and results screen
- Japanese sample question data was fixed so prompts render correctly in the browser

## Question Bank Update

- Expanded `assets/data/sample_questions.json` to 20 questions per grade for kanji reading, kanji writing, and math
- Fixed the math model to accept integer and decimal answers
- Verified the expanded dataset in Chrome using `flutter run -d chrome`
