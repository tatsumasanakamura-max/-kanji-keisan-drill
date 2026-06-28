# 漢字・計算ドリル Ver2.0

Flutter製の漢字検定・計算ドリル総合学習アプリです。小学1〜6年、漢検10〜3級をコースとして扱い、選択したコースのJSONだけをLazy Loadします。

## 主な機能

- 学年モード: 小学1〜6年
- 漢検モード: 10級〜3級
- 漢字カテゴリ10種類: 読み、書き、熟語、文中、同音異義語、対義語、類義語、四字熟語、部首、誤字訂正
- 出題比率: 新規40%、苦手40%、復習20%
- 復習優先日: 前日、3日前、7日前、14日前
- 苦手履歴: 正答率、回答時間、連続不正解、最終出題日、連続正解数
- 学習モード: 通常学習、苦手克服、今日の復習、10問テスト、50問模試、ランダム100問
- 成績: 総問題数、正答率、カテゴリ別、学年別、漢検級別、平均回答時間、苦手ランキング、連続学習日数、経験値、レベル

## データ構成

問題データは `assets/data/` に配置します。

- `grade1.json` ... `grade6.json`
- `kanken10.json` ... `kanken3.json`
- `common_data.json`
- `schema.md`

詳細は [docs/question_schema.md](docs/question_schema.md) を参照してください。

## 開発

```powershell
.\.tools\flutter\bin\flutter.bat pub get
.\.tools\flutter\bin\dart.bat analyze
.\.tools\flutter\bin\flutter.bat test
```

問題データを再生成する場合:

```powershell
node tools\generate_questions.mjs
```

## ドキュメント

- [architecture.md](docs/architecture.md)
- [question_schema.md](docs/question_schema.md)
- [future_features.md](docs/future_features.md)
- [setup-log.md](docs/setup-log.md)
