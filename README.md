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
- GitHub Pages: `.github/workflows/deploy.yml` を追加

## GitHub Pages

GitHub リポジトリの `Settings > Pages` で `Source` を `GitHub Actions` に設定してください。

Pages 公開時の URL は次の形式です。

- `https://tatsumasanakamura-max.github.io/-kanji-keisan-drill/`

GitHub Actions 側では `flutter build web --base-href "/-kanji-keisan-drill/"` でビルドします。

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

## 学年別JSON / ランダム出題 / ハイライト強化

- 問題データを学年別JSONに分離しました
- 新しい配置は `assets/data/grades/grade_1.json` から `grade_9.json` です
- 学年対応は `小1〜小6 = grade_1〜grade_6`、`中1〜中3 = grade_7〜grade_9` です
- 共通データは `assets/data/common_data.json` に分けました
- アプリ本体は学年別JSONを読み込み、学年に応じた問題だけを出題します
- 漢字読み、漢字書き、計算ドリルはそれぞれ学年内でランダム出題します
- 1周したら再シャッフルし、同じ問題が連続しにくいようにしました
- 漢字読みは選択直後に正誤を大きく表示し、不正解時は正解選択肢も緑で示します
- 計算ドリルは大きい入力欄と送信ボタンに変更し、回答後は次の問題ボタンを大きく表示します
- 漢字書きは学年別JSONからランダム出題し、できたボタン後に次へ進めます
- iPad Safari向けに、ボタン、余白、結果表示を大きめに調整しました

## iPad Safari 確認項目

- 小1で `grade_1.json` だけが参照される
- 小5で `grade_5.json` だけが参照される
- 中3で `grade_9.json` だけが参照される
- 漢字読み、漢字書き、計算ドリルの問題順が毎回ランダムになる
- 回答時の正解・不正解ハイライトが明確に見える
- 不正解時に正解も分かる
- ポイント、経験値、コンボ、苦手リスト、成績画面が引き続き更新される
- `flutter build web` が成功する
- GitHub Pages 公開版でも動作する
