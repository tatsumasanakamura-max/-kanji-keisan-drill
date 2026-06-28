import fs from 'node:fs';
import path from 'node:path';
import { execFileSync } from 'node:child_process';

const rootDir = process.cwd();
const samplePath = path.join(rootDir, 'assets/data/sample_questions.json');
const gradesDir = path.join(rootDir, 'assets/data/grades');
const commonPath = path.join(rootDir, 'assets/data/common_data.json');

function readSourceJson() {
  const candidates = [
    () => fs.readFileSync(samplePath, 'utf8'),
    () =>
      execFileSync(
        'git',
        ['--git-dir=.gitdir', '--work-tree=.', 'show', 'c6425b0:assets/data/sample_questions.json'],
        { cwd: rootDir, encoding: 'utf8' },
      ),
  ];

  for (const read of candidates) {
    try {
      const raw = read().replace(/^\uFEFF/, '');
      return JSON.parse(raw);
    } catch (error) {
      if (error instanceof SyntaxError) {
        continue;
      }
      if (error.code === 'ENOENT') {
        continue;
      }
      if (error.status === 128 || error.status === 1) {
        continue;
      }
      throw error;
    }
  }

  throw new Error('Unable to read the legacy sample question bank.');
}

function gradeLabel(grade) {
  return grade <= 6 ? `小学${grade}年生` : `中学${grade - 6}年生`;
}

function writeJson(filePath, value) {
  const serialized = JSON.stringify(value, null, 2);
  JSON.parse(serialized);
  fs.writeFileSync(filePath, `${serialized}\n`, 'utf8');
}

const source = readSourceJson();
fs.mkdirSync(gradesDir, { recursive: true });

for (let grade = 1; grade <= 9; grade += 1) {
  writeJson(path.join(gradesDir, `grade_${grade}.json`), {
    grade,
    label: gradeLabel(grade),
    kanjiReadingQuestions: (source.kanji_reading ?? []).filter((item) => item.grade === grade),
    kanjiWritingPrompts: (source.kanji_writing ?? []).filter((item) => item.grade === grade),
    mathQuestions: (source.math_drill ?? []).filter((item) => item.grade === grade),
  });
}

writeJson(commonPath, {
  daily_challenges: source.daily_challenges ?? [],
  gacha_rewards: source.gacha_rewards ?? [],
  encyclopedia: source.encyclopedia ?? [],
});

console.log(`wrote grade files to ${gradesDir}`);
console.log(`wrote common data to ${commonPath}`);
