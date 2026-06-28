import fs from 'node:fs';
import path from 'node:path';

const rootDir = process.cwd();
const dataDir = path.join(rootDir, 'assets/data');

const types = [
  'reading',
  'writing',
  'compound',
  'sentence',
  'homophone',
  'opposite',
  'synonym',
  'yojijukugo',
  'radical',
  'correction',
];

const gradeSeeds = {
  1: [
    ['山', 'やま', '高くもり上がった土地。', '山にのぼる。'],
    ['川', 'かわ', '水が流れるところ。', '川で魚を見る。'],
    ['林', 'はやし', '木が集まっている場所。', '林の中を歩く。'],
    ['正しい', 'ただしい', 'まちがいがないこと。', '正しい答えを書く。'],
  ],
  2: [
    ['計算', 'けいさん', '数を使って答えを出すこと。', '計算をたしかめる。'],
    ['曜日', 'ようび', '一週間の日の名前。', '月曜日に学校へ行く。'],
    ['親切', 'しんせつ', '人にやさしくすること。', '親切に道を教える。'],
    ['強い', 'つよい', '力や気持ちがしっかりしていること。', '強い風がふく。'],
  ],
  3: [
    ['感想', 'かんそう', '見たり聞いたりしたあとの思い。', '本の感想を書く。'],
    ['研究', 'けんきゅう', 'くわしく調べること。', '植物を研究する。'],
    ['速達', 'そくたつ', '早く届ける郵便。', '速達で手紙を送る。'],
    ['悲しい', 'かなしい', '心がいたむような気持ち。', '悲しい知らせを聞く。'],
  ],
  4: [
    ['慣例', 'かんれい', '以前からのならわし。', '式は慣例にしたがって進む。'],
    ['観察', 'かんさつ', '物事をよく見て調べること。', '昆虫を観察する。'],
    ['協力', 'きょうりょく', '力を合わせること。', '友だちと協力する。'],
    ['必要', 'ひつよう', 'なくてはならないこと。', '練習が必要だ。'],
  ],
  5: [
    ['精密', 'せいみつ', '細かいところまで正確なこと。', '精密な機械を作る。'],
    ['責任', 'せきにん', '自分が引き受けるべきつとめ。', '係の責任を果たす。'],
    ['快適', 'かいてき', '気持ちよく過ごせること。', '快適な部屋で勉強する。'],
    ['許可', 'きょか', 'してよいと認めること。', '先生の許可をもらう。'],
  ],
  6: [
    ['尊敬', 'そんけい', 'すぐれた人をうやまうこと。', '努力する人を尊敬する。'],
    ['討論', 'とうろん', '意見を出し合って話し合うこと。', '課題について討論する。'],
    ['危険', 'きけん', 'あぶないこと。', '危険な場所に近づかない。'],
    ['簡潔', 'かんけつ', '短くまとまっていること。', '簡潔に説明する。'],
  ],
};

const kankenToGrade = {
  10: 1,
  9: 2,
  8: 3,
  7: 4,
  6: 5,
  5: 6,
  4: 6,
  3: 6,
};

function distractors(reading) {
  const bank = ['かんれつ', 'かんりょう', 'けんれい', 'けんきゅう', 'せいみつ', 'きょうりょく', 'ひつよう', 'そんけい'];
  return [reading, ...bank.filter((item) => item !== reading)].slice(0, 4);
}

function question(id, grade, kanken, difficulty, type, source, choices, answer, extra = {}) {
  const [word, reading, meaning, example] = source;
  return {
    id,
    grade,
    kanken,
    difficulty,
    type,
    question: type === 'writing' ? reading : word,
    choices,
    answer,
    meaning,
    example,
    mnemonic: extra.mnemonic ?? '',
    synonyms: extra.synonyms ?? [],
    antonyms: extra.antonyms ?? [],
    tags: extra.tags ?? [],
  };
}

function questionsForGrade(grade, kanken) {
  const seeds = gradeSeeds[grade];
  const out = [];
  let serial = 1;
  for (const seed of seeds) {
    const [word, reading] = seed;
    out.push(question(`g${grade}-reading-${serial}`, grade, kanken, Math.min(5, grade), 'reading', seed, distractors(reading), 0, { tags: ['kanji', 'reading'] }));
    out.push(question(`g${grade}-writing-${serial}`, grade, kanken, Math.min(5, grade), 'writing', seed, [word, `${word}う`, word.replace(word[0], '同'), `${word[0]}学`], 0, { tags: ['kanji', 'writing', 'strokes:0'] }));
    serial += 1;
  }

  const first = seeds[0];
  out.push(question(`g${grade}-compound-1`, grade, kanken, 2, 'compound', first, [first[0], `${first[0]}力`, `大${first[0]}`, `${first[0]}語`], 0, { tags: ['compound'] }));
  out.push(question(`g${grade}-sentence-1`, grade, kanken, 2, 'sentence', first, [`${first[3]}`, `${first[1]}を読む。`, '音だけを聞く。', '答えを消す。'], 0, { tags: ['sentence'] }));
  out.push(question(`g${grade}-homophone-1`, grade, kanken, 3, 'homophone', first, [first[0], '感例', '官例', '完例'], 0, { tags: ['homophone'] }));
  out.push(question(`g${grade}-opposite-1`, grade, kanken, 3, 'opposite', first, ['反対語を選ぶ', '類義語を選ぶ', '読みを選ぶ', '部首を選ぶ'], 0, { antonyms: ['反対'], tags: ['opposite'] }));
  out.push(question(`g${grade}-synonym-1`, grade, kanken, 3, 'synonym', first, ['似た意味の語', '反対の語', '送りがな', '画数'], 0, { synonyms: ['類義'], tags: ['synonym'] }));
  out.push(question(`g${grade}-yojijukugo-1`, grade, kanken, 4, 'yojijukugo', first, ['一日一善', '一石二鳥', '十人十色', '七転八起'], grade % 4, { tags: ['yojijukugo'] }));
  out.push(question(`g${grade}-radical-1`, grade, kanken, 2, 'radical', first, ['部首', '音読み', '訓読み', '例文'], 0, { tags: ['radical'] }));
  out.push(question(`g${grade}-correction-1`, grade, kanken, 4, 'correction', first, [first[0], '誤字をふくむ語', '送りがななし', '読みちがい'], 0, { tags: ['correction'] }));
  return out;
}

function mathQuestionsForGrade(grade) {
  return Array.from({ length: 8 }, (_, index) => {
    const a = grade * 3 + index + 2;
    const b = index + 1;
    return {
      id: `math-${grade}-${index + 1}`,
      grade,
      expression: `${a} + ${b}`,
      answer: a + b,
      options: [a + b, a + b + 1, a + b - 1, a + b + 3],
      operation: 'addition',
      explanation: `${a} + ${b} = ${a + b}`,
      tags: ['math', `grade:${grade}`],
    };
  });
}

function writeJson(filePath, value) {
  fs.writeFileSync(filePath, `${JSON.stringify(value, null, 2)}\n`, 'utf8');
}

fs.mkdirSync(dataDir, { recursive: true });

for (let grade = 1; grade <= 6; grade += 1) {
  const kanken = 11 - grade;
  writeJson(path.join(dataDir, `grade${grade}.json`), {
    grade,
    label: `小学${grade}年`,
    questions: questionsForGrade(grade, kanken),
    mathQuestions: mathQuestionsForGrade(grade),
  });
}

for (const level of [10, 9, 8, 7, 6, 5, 4, 3]) {
  const grade = kankenToGrade[level];
  writeJson(path.join(dataDir, `kanken${level}.json`), {
    grade,
    label: `漢検${level}級`,
    questions: questionsForGrade(grade, level).map((item) => ({
      ...item,
      id: item.id.replace(`g${grade}-`, `k${level}-`),
      kanken: level,
      difficulty: Math.min(5, item.difficulty + (level <= 4 ? 1 : 0)),
    })),
    mathQuestions: [],
  });
}

writeJson(path.join(dataDir, 'common_data.json'), {
  daily_challenges: [
    {
      id: 'dc-001',
      title: '今日の5問チャレンジ',
      description: '漢字または計算を5問解こう。',
      target: 5,
      rewardPoints: 20,
      rewardExp: 30,
      tags: ['mixed'],
    },
    {
      id: 'dc-002',
      title: '苦手克服',
      description: '苦手問題を3問復習しよう。',
      target: 3,
      rewardPoints: 25,
      rewardExp: 35,
      tags: ['weakness'],
    },
  ],
  gacha_rewards: [
    {
      id: 'gr-001',
      name: '努力メダル',
      rarity: 'common',
      description: '毎日の学習を続けた証。',
      pointsCost: 10,
    },
    {
      id: 'gr-002',
      name: '集中バッジ',
      rarity: 'rare',
      description: '連続正解で手に入る特別なバッジ。',
      pointsCost: 30,
    },
  ],
  encyclopedia: [
    {
      id: 'enc-001',
      title: '復習間隔',
      body: '前日、3日前、7日前、14日前の問題を優先して出題します。',
      category: 'system',
    },
  ],
});

console.log(`wrote Ver2 data to ${dataDir}`);
