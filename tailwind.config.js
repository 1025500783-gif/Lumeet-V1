// 介面樣式改成本機編譯，不再從 cdn.tailwindcss.com 載入（中國大陸常連不上，會變成沒有樣式的畫面）
// 改了 index.html 或 video.js 的 class 之後，跑 npm run build:css 重新產生 tailwind.css
module.exports = {
  content: ['./index.html', './video.js'],
  plugins: [require('@tailwindcss/forms'), require('@tailwindcss/container-queries')],
};
