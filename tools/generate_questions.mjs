import fs from 'node:fs';

const outPath = 'C:/Users/la_sp/OneDrive/Desktop/漢字計算ドリル/assets/data/sample_questions.json';

const gradeWords = {
  1: [
    ['日', 'ひ'],
    ['月', 'つき'],
    ['火', 'ひ'],
    ['水', 'みず'],
    ['木', 'き'],
    ['金', 'きん'],
    ['土', 'つち'],
    ['山', 'やま'],
    ['川', 'かわ'],
    ['田', 'た'],
    ['人', 'ひと'],
    ['口', 'くち'],
    ['手', 'て'],
    ['足', 'あし'],
    ['子', 'こ'],
    ['女', 'おんな'],
    ['男', 'おとこ'],
    ['空', 'そら'],
    ['雨', 'あめ'],
    ['花', 'はな'],
  ],
  2: [
    ['学校', 'がっこう'],
    ['先生', 'せんせい'],
    ['名前', 'なまえ'],
    ['時間', 'じかん'],
    ['分', 'ふん'],
    ['年', 'とし'],
    ['友だち', 'ともだち'],
    ['元気', 'げんき'],
    ['天気', 'てんき'],
    ['家族', 'かぞく'],
    ['東京', 'とうきょう'],
    ['左右', 'さゆう'],
    ['図書', 'としょ'],
    ['国語', 'こくご'],
    ['行く', 'いく'],
    ['来る', 'くる'],
    ['見学', 'けんがく'],
    ['買い物', 'かいもの'],
    ['走る', 'はしる'],
    ['村', 'むら'],
  ],
  3: [
    ['国民', 'こくみん'],
    ['海外', 'かいがい'],
    ['電車', 'でんしゃ'],
    ['音楽', 'おんがく'],
    ['体育', 'たいいく'],
    ['力', 'ちから'],
    ['住所', 'じゅうしょ'],
    ['朝日', 'あさひ'],
    ['夕方', 'ゆうがた'],
    ['新聞', 'しんぶん'],
    ['道路', 'どうろ'],
    ['前後', 'ぜんご'],
    ['番号', 'ばんごう'],
    ['強い', 'つよい'],
    ['広場', 'ひろば'],
    ['門', 'もん'],
    ['研究', 'けんきゅう'],
    ['世界', 'せかい'],
    ['公園', 'こうえん'],
    ['地図', 'ちず'],
  ],
  4: [
    ['努力', 'どりょく'],
    ['紹介', 'しょうかい'],
    ['便利', 'べんり'],
    ['協力', 'きょうりょく'],
    ['旅行', 'りょこう'],
    ['理由', 'りゆう'],
    ['祭り', 'まつり'],
    ['料理', 'りょうり'],
    ['写真', 'しゃしん'],
    ['図形', 'ずけい'],
    ['安心', 'あんしん'],
    ['注意', 'ちゅうい'],
    ['改良', 'かいりょう'],
    ['未来', 'みらい'],
    ['知識', 'ちしき'],
    ['伝言', 'でんごん'],
    ['表情', 'ひょうじょう'],
    ['発表', 'はっぴょう'],
    ['練習', 'れんしゅう'],
    ['景色', 'けしき'],
  ],
  5: [
    ['責任', 'せきにん'],
    ['反省', 'はんせい'],
    ['約束', 'やくそく'],
    ['説明', 'せつめい'],
    ['相談', 'そうだん'],
    ['文化', 'ぶんか'],
    ['伝統', 'でんとう'],
    ['効果', 'こうか'],
    ['価値', 'かち'],
    ['条件', 'じょうけん'],
    ['可能', 'かのう'],
    ['技術', 'ぎじゅつ'],
    ['比較', 'ひかく'],
    ['進歩', 'しんぽ'],
    ['解決', 'かいけつ'],
    ['議論', 'ぎろん'],
    ['判断', 'はんだん'],
    ['調査', 'ちょうさ'],
    ['選択', 'せんたく'],
    ['想像', 'そうぞう'],
  ],
  6: [
    ['環境', 'かんきょう'],
    ['影響', 'えいきょう'],
    ['構成', 'こうせい'],
    ['保護', 'ほご'],
    ['目的', 'もくてき'],
    ['連携', 'れんけい'],
    ['記録', 'きろく'],
    ['編集', 'へんしゅう'],
    ['収集', 'しゅうしゅう'],
    ['貢献', 'こうけん'],
    ['実現', 'じつげん'],
    ['認識', 'にんしき'],
    ['共通', 'きょうつう'],
    ['管理', 'かんり'],
    ['協調', 'きょうちょう'],
    ['整備', 'せいび'],
    ['保存', 'ほぞん'],
    ['論理', 'ろんり'],
    ['資料', 'しりょう'],
    ['感想', 'かんそう'],
  ],
  7: [
    ['現在', 'げんざい'],
    ['状況', 'じょうきょう'],
    ['観察', 'かんさつ'],
    ['要因', 'よういん'],
    ['仕組み', 'しくみ'],
    ['主張', 'しゅちょう'],
    ['課題', 'かだい'],
    ['結論', 'けつろん'],
    ['価値観', 'かちかん'],
    ['意図', 'いと'],
    ['誤解', 'ごかい'],
    ['深刻', 'しんこく'],
    ['適切', 'てきせつ'],
    ['目標', 'もくひょう'],
    ['資源', 'しげん'],
    ['能率', 'のうりつ'],
    ['肯定', 'こうてい'],
    ['否定', 'ひてい'],
    ['解釈', 'かいしゃく'],
    ['相当', 'そうとう'],
  ],
  8: [
    ['経済', 'けいざい'],
    ['政策', 'せいさく'],
    ['需要', 'じゅよう'],
    ['供給', 'きょうきゅう'],
    ['権利', 'けんり'],
    ['義務', 'ぎむ'],
    ['支援', 'しえん'],
    ['構造', 'こうぞう'],
    ['認証', 'にんしょう'],
    ['比率', 'ひりつ'],
    ['変化', 'へんか'],
    ['持続', 'じぞく'],
    ['抽象', 'ちゅうしょう'],
    ['具体', 'ぐたい'],
    ['論点', 'ろんてん'],
    ['関係', 'かんけい'],
    ['交流', 'こうりゅう'],
    ['効果', 'こうか'],
    ['確認', 'かくにん'],
    ['実験', 'じっけん'],
  ],
  9: [
    ['複雑', 'ふくざつ'],
    ['体系', 'たいけい'],
    ['連鎖', 'れんさ'],
    ['誤差', 'ごさ'],
    ['推進', 'すいしん'],
    ['改善', 'かいぜん'],
    ['傾向', 'けいこう'],
    ['関心', 'かんしん'],
    ['重要', 'じゅうよう'],
    ['発展', 'はってん'],
    ['統合', 'とうごう'],
    ['拡大', 'かくだい'],
    ['比較', 'ひかく'],
    ['検証', 'けんしょう'],
    ['解釈', 'かいしゃく'],
    ['評価', 'ひょうか'],
    ['協議', 'きょうぎ'],
    ['反論', 'はんろん'],
    ['選択', 'せんたく'],
    ['達成', 'たっせい'],
  ],
};

const mathPatterns = {
  1: [
    ['3 + 2', 5], ['4 + 1', 5], ['6 - 1', 5], ['2 + 3', 5], ['7 - 2', 5],
    ['5 + 4', 9], ['8 - 3', 5], ['9 - 4', 5], ['1 + 8', 9], ['10 - 6', 4],
    ['2 + 7', 9], ['4 + 3', 7], ['9 - 1', 8], ['6 + 2', 8], ['5 - 2', 3],
    ['3 + 6', 9], ['7 - 5', 2], ['8 - 6', 2], ['4 + 5', 9], ['10 - 7', 3],
  ],
  2: [
    ['12 + 5', 17], ['18 - 6', 12], ['24 + 3', 27], ['30 - 8', 22], ['15 + 7', 22],
    ['21 - 4', 17], ['34 + 2', 36], ['40 - 9', 31], ['26 + 4', 30], ['19 - 3', 16],
    ['28 + 6', 34], ['32 - 5', 27], ['47 + 1', 48], ['50 - 7', 43], ['16 + 8', 24],
    ['63 - 10', 53], ['29 + 9', 38], ['41 - 2', 39], ['55 + 5', 60], ['70 - 20', 50],
  ],
  3: [
    ['2 × 3', 6], ['4 × 5', 20], ['6 × 7', 42], ['8 × 3', 24], ['9 × 4', 36],
    ['12 ÷ 3', 4], ['15 ÷ 5', 3], ['18 ÷ 6', 3], ['7 × 8', 56], ['6 × 4', 24],
    ['3 × 9', 27], ['10 × 5', 50], ['24 ÷ 4', 6], ['32 ÷ 8', 4], ['5 × 7', 35],
    ['11 × 2', 22], ['14 ÷ 2', 7], ['9 × 6', 54], ['20 ÷ 5', 4], ['4 × 8', 32],
  ],
  4: [
    ['23 + 14', 37], ['48 - 19', 29], ['36 + 27', 63], ['52 - 18', 34], ['15 × 3', 45],
    ['64 ÷ 8', 8], ['29 + 11', 40], ['72 - 26', 46], ['7 × 6', 42], ['81 ÷ 9', 9],
    ['34 + 25', 59], ['90 - 45', 45], ['12 × 4', 48], ['56 ÷ 7', 8], ['31 + 28', 59],
    ['75 - 17', 58], ['9 × 5', 45], ['63 ÷ 9', 7], ['44 + 16', 60], ['88 - 29', 59],
  ],
  5: [
    ['3/4 + 1/4', 1], ['1/2 + 1/3', 5 / 6], ['2/3 - 1/3', 1 / 3], ['0.5 + 0.2', 0.7], ['1.5 - 0.4', 1.1],
    ['2 × 7 + 3', 17], ['36 ÷ 6 + 2', 8], ['8 + 4 × 2', 16], ['(9 - 3) × 2', 12], ['18 ÷ 3 + 5', 11],
    ['25 + 17', 42], ['64 - 28', 36], ['7 × 8', 56], ['72 ÷ 8', 9], ['13 + 9', 22],
    ['45 - 19', 26], ['6 × 9', 54], ['81 ÷ 9', 9], ['3/5 + 1/5', 0.8], ['4/5 - 2/5', 0.4],
  ],
  6: [
    ['12 × 3 + 4', 40], ['7 × 8 - 5', 51], ['(18 + 6) ÷ 4', 6], ['2/5 + 1/10', 0.5], ['3/4 - 1/8', 0.625],
    ['15% of 200', 30], ['25% of 80', 20], ['3.6 + 1.4', 5.0], ['9.5 - 2.7', 6.8], ['4 × (7 - 2)', 20],
    ['84 ÷ 7 + 6', 18], ['5/6 - 1/6', 2 / 3], ['2.5 × 4', 10], ['120 - 35', 85], ['18 + 27', 45],
    ['9 × 6 - 8', 46], ['56 ÷ 8 + 3', 10], ['(30 - 6) ÷ 3', 8], ['0.75 + 0.25', 1], ['2/3 + 1/6', 5 / 6],
  ],
  7: [
    ['(-3) + 8', 5], ['(-5) + 2', -3], ['7 - (-2)', 9], ['(-4) - 6', -10], ['(-2) × 3', -6],
    ['12 + (-7)', 5], ['(-9) ÷ 3', -3], ['(-8) + (-1)', -9], ['15 - 20', -5], ['(-6) × (-2)', 12],
    ['3x = 12', 4], ['x + 7 = 19', 12], ['2x = 18', 9], ['x - 5 = -2', 3], ['4x = 28', 7],
    ['|−7|', 7], ['(-10) + 13', 3], ['18 - (-4)', 22], ['(-12) ÷ (-3)', 4], ['5 + (-11)', -6],
  ],
  8: [
    ['x + 15 = 42', 27], ['3x = 21', 7], ['2x + 5 = 19', 7], ['x - 8 = 13', 21], ['4x = 36', 9],
    ['y / 5 = 6', 30], ['12 + x = 50', 38], ['2(x + 3) = 18', 6], ['x / 4 = 9', 36], ['5x - 10 = 20', 6],
    ['30% of 90', 27], ['1.2 × 5', 6], ['7.5 - 2.8', 4.7], ['(8 + 4) × 3', 36], ['64 ÷ 8 + 2', 10],
    ['0.8 + 0.6', 1.4], ['3/8 + 1/8', 0.5], ['9.6 ÷ 3', 3.2], ['15 - 4.5', 10.5], ['2.4 × 2', 4.8],
  ],
  9: [
    ['x + 3 = 14', 11], ['2x + 1 = 15', 7], ['3x - 6 = 9', 5], ['x / 2 = 9', 18], ['4x = 52', 13],
    ['(x - 4) × 2 = 18', 13], ['7^2', 49], ['sqrt(81)', 9], ['0.25 × 40', 10], ['12.5 - 4.75', 7.75],
    ['18% of 150', 27], ['6 × (8 + 2)', 60], ['96 ÷ 12', 8], ['3.2 + 1.8', 5], ['15.6 - 6.4', 9.2],
    ['5x + 5 = 40', 7], ['2(x + 6) = 24', 6], ['100 ÷ 4 + 3', 28], ['2/3 + 1/3', 1], ['0.5 × 0.6', 0.3],
  ],
};

function makeMeaning(grade, index) {
  return `grade${grade}-vocab-${index + 1}`;
}

function makeStrokeCount(kanji) {
  const len = [...kanji].length;
  return Math.max(4, len * 5 + (len > 1 ? 1 : 0));
}

function pickReadingOptions(readings, reading, index) {
  const wrongs = [];
  for (let offset = 1; wrongs.length < 3 && offset < readings.length * 2; offset++) {
    const candidate = readings[(index + offset * 3) % readings.length];
    if (candidate !== reading && !wrongs.includes(candidate)) {
      wrongs.push(candidate);
    }
  }
  while (wrongs.length < 3) {
    const candidate = `${readings[(index + wrongs.length + 4) % readings.length]}ー`;
    if (candidate !== reading && !wrongs.includes(candidate)) {
      wrongs.push(candidate);
    }
  }
  const options = [reading, ...wrongs].slice(0, 4);
  const answerIndex = (index + options.length) % 4;
  const rotated = options.slice(answerIndex).concat(options.slice(0, answerIndex));
  return { options: rotated, answerIndex: rotated.indexOf(reading) };
}

function buildReadingQuestions() {
  const items = [];
  for (const grade of Object.keys(gradeWords).map(Number)) {
    const entries = gradeWords[grade];
    const readings = entries.map((entry) => entry[1]);
    entries.forEach(([kanji, reading], index) => {
      const { options, answerIndex } = pickReadingOptions(readings, reading, index);
      items.push({
        id: `kr-${grade}-${String(index + 1).padStart(3, '0')}`,
        grade,
        kanji,
        reading,
        meaning: makeMeaning(grade, index),
        options,
        answerIndex,
        explanation: `${kanji}は「${reading}」と読みます。`,
        tags: grade <= 2 ? ['basic'] : grade <= 4 ? ['elementary'] : ['middle-school'],
      });
    });
  }
  return items;
}

function buildWritingPrompts() {
  const items = [];
  for (const grade of Object.keys(gradeWords).map(Number)) {
    const entries = gradeWords[grade];
    entries.forEach(([kanji, reading], index) => {
      items.push({
        id: `kw-${grade}-${String(index + 1).padStart(3, '0')}`,
        grade,
        kanji,
        reading,
        strokeCount: makeStrokeCount(kanji),
        hint: grade <= 2
          ? '大きく、まっすぐ、ていねいに書こう。'
          : grade <= 4
            ? '形のバランスを見ながら、ゆっくり書こう。'
            : '画の位置と長さをそろえて、くずれないように書こう。',
        strokeOrderNotes: '上から下、左から右を意識して練習しよう。',
        tags: grade <= 2 ? ['basic'] : grade <= 4 ? ['elementary'] : ['middle-school'],
      });
    });
  }
  return items;
}

function makeOptions(answer, grade, index) {
  const set = new Set([answer]);
  const deltas = grade <= 2 ? [-2, -1, 1, 2, 3, 4] : grade <= 4 ? [-5, -3, 3, 5, 7, 9] : [-8, -6, 6, 8, 10, 12];
  let deltaIndex = 0;
  while (set.size < 4) {
    const delta = deltas[(index + deltaIndex) % deltas.length];
    const value = answer + delta;
    if (Number.isFinite(value)) {
      set.add(value);
    }
    deltaIndex += 1;
  }
  const options = [...set];
  for (let i = options.length - 1; i > 0; i--) {
    const j = (index + i) % (i + 1);
    [options[i], options[j]] = [options[j], options[i]];
  }
  return options;
}

function buildMathQuestions() {
  const items = [];
  for (const grade of Object.keys(mathPatterns).map(Number)) {
    mathPatterns[grade].forEach(([expression, answer], index) => {
      items.push({
        id: `md-${grade}-${String(index + 1).padStart(3, '0')}`,
        grade,
        expression,
        answer,
        options: makeOptions(answer, grade, index),
        operation: expression.includes('×')
          ? 'multiplication'
          : expression.includes('÷')
            ? 'division'
            : /[xy]/.test(expression)
              ? 'equation'
              : 'mixed',
        explanation: `答えは ${answer} です。`,
        tags: grade <= 2 ? ['basic'] : grade <= 4 ? ['elementary'] : grade <= 6 ? ['mixed'] : ['middle-school'],
      });
    });
  }
  return items;
}

const json = {
  kanji_reading: buildReadingQuestions(),
  kanji_writing: buildWritingPrompts(),
  math_drill: buildMathQuestions(),
  daily_challenges: [
    {
      id: 'dc-001',
      title: '今日の5問チャレンジ',
      description: '漢字読み3問と計算2問を正解しよう。',
      target: 5,
      rewardPoints: 20,
      rewardExp: 30,
      tags: ['mixed'],
    },
    {
      id: 'dc-002',
      title: '書き練習集中',
      description: '漢字書き練習を3回クリアしよう。',
      target: 3,
      rewardPoints: 25,
      rewardExp: 35,
      tags: ['writing'],
    },
  ],
  gacha_rewards: [
    { id: 'gr-001', name: '日めくりメダル', rarity: 'common', description: 'ちいさな努力の証です。', pointsCost: 10 },
    { id: 'gr-002', name: '学習バッジ', rarity: 'rare', description: '連続正解で手に入るかも。', pointsCost: 30 },
    { id: 'gr-003', name: 'かがやき宝石', rarity: 'superRare', description: '高得点でねらえます。', pointsCost: 100 },
  ],
  encyclopedia: [
    { id: 'enc-001', title: 'コンボ', body: '連続正解でコンボがつながると、もらえるポイントが少し増えます。', category: 'system' },
    { id: 'enc-002', title: '経験値', body: '学習を進めると経験値がたまり、レベルが上がります。', category: 'system' },
  ],
};

const serialized = JSON.stringify(json, null, 2);
JSON.parse(serialized);
fs.writeFileSync(outPath, serialized, 'utf8');
console.log(`wrote ${serialized.length} chars to ${outPath}`);
