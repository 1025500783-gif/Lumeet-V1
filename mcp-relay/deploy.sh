#!/usr/bin/env bash
# 一鍵部署視訊通話 MCP 橋接：bash deploy.sh（可重複執行）
set -euo pipefail
cd "$(dirname "$0")"

WRANGLER="npx --yes wrangler"
# 明確指定設定檔：有些環境（例如手機上的 Linux 終端機）wrangler 找不到同資料夾的 wrangler.toml
CFG="--config $PWD/wrangler.toml"
step() { printf '\n\033[1m== %s\033[0m\n' "$1"; }

step "1/4 安裝套件"
npm install --silent

step "2/4 Cloudflare 登入"
if ! $WRANGLER whoami 2>/dev/null | grep -qi "associated with"; then
  if ! $WRANGLER login; then
    # 手機上的 Linux 終端機（Termux、Operit 等）瀏覽器授權常常接不回來，改用 API Token
    cat <<'MSG'

登入失敗。手機上的終端機常常這樣，改用 API Token 登入：
  1. 瀏覽器打開 https://dash.cloudflare.com/profile/api-tokens
  2. Create Token → 模板選「Edit Cloudflare Workers」→ 建立後複製 Token（只顯示一次）
  3. 在終端機執行（把 你的Token 換成剛剛那串），再跑一次本腳本：
       export CLOUDFLARE_API_TOKEN=你的Token
       bash deploy.sh
Token 等於你 Cloudflare 帳號的鑰匙，不要截圖、不要給任何人。
MSG
    exit 1
  fi
fi

step "3/4 部署"
DEPLOY_OUT=$($WRANGLER deploy $CFG 2>&1 | tee /dev/stderr)
URL=$(printf '%s' "$DEPLOY_OUT" | grep -o 'https://[^ ]*workers\.dev' | head -1)

step "4/4 設定密碼"
SECRET=""
if $WRANGLER secret list $CFG 2>/dev/null | grep -q '"RELAY_SECRET"'; then
  echo "之前已設定過密碼（只在第一次部署時顯示）。忘記的話刪掉重設：npx wrangler secret delete RELAY_SECRET，再跑一次本腳本"
else
  SECRET=$(openssl rand -hex 24)
  printf '%s' "$SECRET" | $WRANGLER secret put RELAY_SECRET $CFG
fi

URL=${URL:-https://<你的網址>.workers.dev}
SHOW=${SECRET:-<你的密碼>}

printf '\n\033[1m完成！以下資料只顯示這一次，請存好\033[0m\n\n'
echo "【App 設定 → AI 接入方式選「MCP 橋接」】"
echo "  橋接網址：$URL"
echo "  橋接密碼：$SHOW"
echo
echo "【AI 端加入 MCP】"
echo "  MCP 網址：$URL/mcp/$SHOW"
echo
echo "  Claude Code："
echo "    claude mcp add --transport http video-call $URL/mcp/$SHOW"
echo
echo "  Codex（~/.codex/config.toml）："
echo "    [mcp_servers.video-call]"
echo "    url = \"$URL/mcp/$SHOW\""
echo
echo "  claude.ai：設定 → 連接器 → 新增自訂連接器，貼上 MCP 網址"
echo
echo "通話前跟你的 AI 說：「進入視訊通話模式」"
