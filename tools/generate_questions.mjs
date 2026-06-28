import fs from 'node:fs';
import path from 'node:path';

const rootDir = 'C:/Users/la_sp/OneDrive/Desktop/漢字計算ドリル';
const sourcePath = path.join(rootDir, 'assets/data/sample_questions.json');
const gradesDir = path.join(rootDir, 'assets/data/grades');
const commonPath = path.join(rootDir, 'assets/data/common_data.json');

const gradeLabels = {
  1: '小学1年生',
  2: '小学2年生',
  3: '小学3年生',
  4: '小学4年生',
  5: '小学5年生',
  6: '小学6年生',
  7: '中学1年生',
  8: '中学2年生',
  9: '中学3年生',
};

const raw = fs.readFileSync(sourcePath, 'utf8');
const source = JSON.parse(raw);

fs.mkdirSync(gradesDir, { recursive: true });

const allGrades = [...Array(9)].map((_, index) => index + 1);
for (const grade of allGrades) {
  const label = gradeLabels[grade];
  const reading = source.kanji_reading.filter((item) => item.grade === grade);
  const writing = source.kanji_writing.filter((item) => item.grade === grade);
  const math = source.math_drill.filter((item) => item.grade === grade);
  const gradeData = {
    grade,
    label,
    kanjiReadingQuestions: reading,
    kanjiWritingPrompts: writing,
    mathQuestions: math,
  };

  const gradePath = path.join(gradesDir, `grade_${grade}.json`);
  const serialized = JSON.stringify(gradeData, null, 2);
  JSON.parse(serialized);
  fs.writeFileSync(gradePath, serialized, 'utf8');
}

const commonData = {
  daily_challenges: source.daily_challenges ?? [],
  gacha_rewards: source.gacha_rewards ?? [],
  encyclopedia: source.encyclopedia ?? [],
};

const commonSerialized = JSON.stringify(commonData, null, 2);
JSON.parse(commonSerialized);
fs.writeFileSync(commonPath, commonSerialized, 'utf8');

console.log(`wrote grade files to ${gradesDir}`);
console.log(`wrote common data to ${commonPath}`);
