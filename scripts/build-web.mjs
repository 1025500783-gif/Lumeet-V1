import { cpSync, existsSync, mkdirSync, readFileSync, rmSync, writeFileSync } from 'node:fs';

const FILES = ['index.html', 'tailwind.css', 'video.js', 'vad.js', 'manifest.webmanifest', 'sw.js'];
const PAGE_ONLY_FILES = ['_headers'];
const ICONS = ['apple-touch-icon.png', 'icon-192.png', 'icon-512.png'];

rmSync('www', { recursive: true, force: true });
mkdirSync('www');
for (const f of FILES) {
  if (existsSync(f)) cpSync(f, `www/${f}`);
}
for (const f of PAGE_ONLY_FILES) {
  if (existsSync(f)) cpSync(f, `www/${f}`);
}
for (const f of ICONS) cpSync(`icons/${f}`, `www/${f}`);
console.log('www/ 已更新');

// 網頁版也包進 MCP 橋接器，iPhone 直接用 Safari 打開橋接網址
const web = {};
for (const f of FILES) web['/' + f] = readFileSync(f, 'utf8');
// 圖示用 base64 存，橋接器回傳時再轉回二進位
for (const f of ICONS) web['/' + f] = 'base64:' + readFileSync(`icons/${f}`).toString('base64');
writeFileSync('mcp-relay/src/web-assets.js', `// 自動產生，請改專案根目錄的檔案後跑 npm run build:web\nexport default ${JSON.stringify(web)};\n`);
console.log('mcp-relay/src/web-assets.js 已更新');
