// Renders a page once per frame (passing ?t=seconds) in a single Chrome session.
import puppeteer from 'puppeteer-core';
import { mkdirSync } from 'node:fs';

const [, , pageUrl, outDir, fps = '30', seconds = '12', scale = '1.5'] = process.argv;
mkdirSync(outDir, { recursive: true });
const browser = await puppeteer.launch({
  executablePath: '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',
  headless: true,
  args: ['--hide-scrollbars'],
});
const page = await browser.newPage();
await page.setViewport({ width: 1280, height: 720, deviceScaleFactor: Number(scale) });
const total = Math.round(Number(fps) * Number(seconds));
for (let frame = 0; frame < total; frame++) {
  await page.goto(`${pageUrl}?t=${(frame / Number(fps)).toFixed(4)}`, { waitUntil: 'load' });
  await page.screenshot({ path: `${outDir}/${String(frame).padStart(4, '0')}.png` });
}
await browser.close();
console.log(`rendered ${total} frames`);
