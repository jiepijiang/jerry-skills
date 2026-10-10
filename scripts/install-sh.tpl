#!/usr/bin/env bash
# ============================================================================
# jerry-skills 安装器
# ----------------------------------------------------------------------------
# 用法：
#   curl -fsSL <站点>/install.sh | bash -s -- <slug> [--agent <名称>]
#
#   --agent  装到哪个 AI 助手的 skills 目录（默认 workbuddy）
#
# 这个文件是**模板**：scripts/gen-install-sh.mjs 会把 __SUPABASE_*__ 替换成
# 真实端点后写进 public/install.sh。别直接改 public/install.sh —— 它每次构建
# 都会被覆盖。
#
# ⚠️ 脚本里出现的目录必须和 src/data/site.js 的 `agents` 一致。
#    两处不一致会出现「网页写着装到 A、实际装到 B」。
# ============================================================================
set -euo pipefail

ENDPOINT="__SUPABASE_URL__"
ANON_KEY="__SUPABASE_ANON_KEY__"
SITE="__SITE_URL__"

SLUG=""
AGENT="workbuddy"

usage() {
  cat <<'EOF'
jerry-skills 安装器

用法:
  curl -fsSL <站点>/install.sh | bash -s -- <slug> [--agent <名称>]

参数:
  <slug>              技能的唯一标识（在技能详情页能看到）
  --agent <名称>      安装目标，默认 workbuddy

可选的目标:
  workbuddy  ~/.workbuddy-ai/skills
  claude     ~/.claude/skills
  cursor     ~/.cursor/skills
  codex      ~/.codex/skills
  gemini     ~/.gemini/skills
  copilot    ~/.copilot/skills
  windsurf   ~/.windsurf/skills
  cline      ~/.cline/skills

示例:
  curl -fsSL __SITE__/install.sh | bash -s -- pdf-editor --agent claude
EOF
}

dir_for_agent() {
  case "$1" in
    workbuddy) echo "$HOME/.workbuddy-ai/skills" ;;
    claude)    echo "$HOME/.claude/skills" ;;
    cursor)    echo "$HOME/.cursor/skills" ;;
    codex)     echo "$HOME/.codex/skills" ;;
    gemini)    echo "$HOME/.gemini/skills" ;;
    copilot)   echo "$HOME/.copilot/skills" ;;
    windsurf)  echo "$HOME/.windsurf/skills" ;;
    cline)     echo "$HOME/.cline/skills" ;;
    *)         return 1 ;;
  esac
}

while [ $# -gt 0 ]; do
  case "$1" in
    --agent)   AGENT="${2:-}"; shift 2 ;;
    --agent=*) AGENT="${1#*=}"; shift ;;
    -h|--help) usage; exit 0 ;;
    -*)        echo "未知参数：$1" >&2; usage >&2; exit 2 ;;
    *)         SLUG="$1"; shift ;;
  esac
done

if [ -z "$SLUG" ]; then
  echo "缺少技能标识（slug）。" >&2
  usage >&2
  exit 2
fi

# slug 会被拼进 JSON 请求体 —— 挡掉会破坏 JSON 的字符（引号、反斜杠、控制字符）
case "$SLUG" in
  *'"'*|*'\'*)
    echo "非法的技能标识：$SLUG" >&2
    exit 2
    ;;
esac

TARGET_ROOT="$(dir_for_agent "$AGENT")" || {
  echo "不认识的 --agent：$AGENT（用 --help 看可选值）" >&2
  exit 2
}

if [ "$ENDPOINT" = "__SUPABASE_URL__" ] || [ -z "$ENDPOINT" ]; then
  echo "这个 install.sh 没有注入后端地址（构建时未配置 Supabase）。" >&2
  echo "请到技能详情页用「下载 .zip」手动安装。" >&2
  exit 1
fi

if ! command -v python3 >/dev/null 2>&1; then
  echo "需要 python3 来解压与解析响应（macOS 自带，常见 Linux 发行版也有）。" >&2
  exit 1
fi

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

echo "→ 正在获取 $SLUG …"

HTTP_CODE="$(curl -sS -o "$TMP/resp.json" -w '%{http_code}' \
  -X POST "$ENDPOINT/rest/v1/rpc/download_skill" \
  -H 'Content-Type: application/json' \
  -H "apikey: $ANON_KEY" \
  -H "Authorization: Bearer $ANON_KEY" \
  --data "{\"p_slug\":\"$SLUG\"}")" || {
  echo "网络请求失败，请检查网络后重试。" >&2
  exit 1
}

if [ "$HTTP_CODE" != "200" ]; then
  echo "请求失败（HTTP $HTTP_CODE）。" >&2
  head -c 400 "$TMP/resp.json" >&2 || true
  echo >&2
  exit 1
fi

# 用 python 解析 + 解码：**不用 jq**（不是每台机器都有），也不靠 grep 匹配 JSON
python3 - "$TMP/resp.json" "$TMP" <<'PY'
import base64, json, os, sys

path, outdir = sys.argv[1], sys.argv[2]
try:
    data = json.load(open(path, encoding='utf-8'))
except Exception as exc:                       # noqa: BLE001
    print(f'响应不是合法 JSON：{exc}', file=sys.stderr)
    sys.exit(1)

if not data.get('ok'):
    code = data.get('code', 'unknown')
    msg = {
        'not_found': '没有找到这个技能（slug 写错了？）',
        'invalid_payload': '请求参数不对',
    }.get(code, f'下载失败（{code}）')
    print(msg, file=sys.stderr)
    sys.exit(1)

try:
    raw = base64.b64decode(data['bundle_b64'], validate=False)
except Exception as exc:                       # noqa: BLE001
    print(f'技能包解码失败：{exc}', file=sys.stderr)
    sys.exit(1)

if raw[:2] != b'PK':
    print('下载到的内容不是 zip，已中止。', file=sys.stderr)
    sys.exit(1)

with open(os.path.join(outdir, 'skill.zip'), 'wb') as fh:
    fh.write(raw)
print(data.get('filename') or 'skill.zip')
PY

TARGET="$TARGET_ROOT/$SLUG"

# 已存在先备份，不直接删 —— 用户可能改过里面的东西
if [ -e "$TARGET" ]; then
  BACKUP="$TARGET.bak.$(date +%Y%m%d%H%M%S)"
  mv "$TARGET" "$BACKUP"
  echo "→ 已备份原目录到 $BACKUP"
fi

mkdir -p "$TARGET"

if command -v unzip >/dev/null 2>&1; then
  unzip -oq "$TMP/skill.zip" -d "$TARGET"
else
  python3 -c 'import sys, zipfile; zipfile.ZipFile(sys.argv[1]).extractall(sys.argv[2])' \
    "$TMP/skill.zip" "$TARGET"
fi

if [ ! -f "$TARGET/SKILL.md" ]; then
  echo "⚠️  装完了，但目录里没有 SKILL.md —— 这个技能包可能不完整。" >&2
fi

echo "✅ 已安装到 $TARGET"
echo "   文件：$(find "$TARGET" -type f | wc -l | tr -d ' ') 个"
echo "   技能主页：$SITE/skills/$SLUG"
