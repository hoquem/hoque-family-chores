// Try the Mission Guide prompt against Gemini without deploying.
// Prints the guide for each sample chore so the wording can be checked by eye.
// Run from the repo root:
//   GEMINI_API_KEY=$(firebase functions:secrets:access GEMINI_API_KEY --project hoque-family-chores-app) \
//     node scripts/try_chore_guide.js ["Chore title" ...]
const path = require('path');
const { callGeminiForGuide, GEMINI_MODEL } = require(path.resolve('functions/choreGuide.js'));

const apiKey = process.env.GEMINI_API_KEY;
if (!apiKey) throw new Error('GEMINI_API_KEY not set');

const SAMPLES = [
  { title: 'Clean the car', difficulty: 'medium' },
  { title: 'Wash the dog', difficulty: 'small' },
  { title: 'Empty the dishwasher', description: 'Unload clean, load dirty', difficulty: 'small' },
  { title: 'Take Kumo to the vets', difficulty: 'large' },
];
const chores = process.argv.length > 2 ? process.argv.slice(2).map((title) => ({ title, difficulty: 'medium' })) : SAMPLES;

(async () => {
  console.log(`model: ${GEMINI_MODEL}\n`);
  for (const chore of chores) {
    const g = await callGeminiForGuide({ ...chore, parentTip: '', apiKey });
    console.log(`== ${chore.title}`);
    console.log(`motivation: ${g.motivation}`);
    g.steps.forEach((s, i) => console.log(`  ${i + 1}. ${s}`));
    console.log(`forYou: ${g.forYou}\nforFamily: ${g.forFamily}\nforHome: ${g.forHome}\ntakeaway: ${g.takeaway}\n`);
  }
})().catch((e) => { console.error(e); process.exit(1); });
