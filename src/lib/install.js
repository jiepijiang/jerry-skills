/**
 * 安装命令 / AI Agent 提示词生成
 * ---------------------------------------------------------------------------
 * 本站是纯静态托管（GitHub Pages），没有服务端可以「安装」。
 * 所以「安装」= 给用户一段**能真正跑起来**的命令，由用户本机执行：
 *
 *   ① 命令行安装：curl 拉 install.sh，脚本从 Supabase 取技能包并落盘到
 *      对应 AI 助手的 skills 目录。
 *   ② AI Agent 安装：给一段自然语言提示词，粘给任意 agent，让它自己执行。
 *
 * 两者都必须**指向同一个下载源**（download_skill RPC），否则会出现
 * 「网页说装 A、实际装到 B」。
 */
import { SITE_URL, agentByKey, DEFAULT_AGENT } from '@/data/site'

/** install.sh 的公开地址 */
export function installerUrl() {
  return `${SITE_URL}/install.sh`
}

/**
 * 命令行安装命令。
 * `bash -s --` 把后面的参数传给脚本（`curl | bash` 时不能直接跟位置参数）。
 */
export function cliCommand(slug, agentKey = DEFAULT_AGENT) {
  return `curl -fsSL ${installerUrl()} | bash -s -- ${slug} --agent ${agentKey}`
}

/**
 * AI Agent 安装提示词。
 * 写成「可执行 + 可核验」的样子：agent 能照着跑，用户能看出它做了什么。
 */
export function agentPrompt(skill, agentKey = DEFAULT_AGENT) {
  const agent = agentByKey(agentKey)
  const slug = skill?.slug || '<slug>'
  const name = skill?.name || slug
  const cmd = cliCommand(slug, agentKey)

  return `请帮我把 AI Agent 技能「${name}」安装到 ${agent.label} 的 skills 目录。

执行这条命令即可：

    ${cmd}

要求：
1. 安装目标目录是 ${agent.dir}，技能会落在 ${agent.dir}/${slug}。
2. 如果该目录已存在，先把旧目录改名备份（加 .bak 后缀），再安装，不要直接删。
3. 安装完成后，请列出 ${agent.dir}/${slug} 的内容，确认 SKILL.md 在里面。
4. 把结果（成功/失败、装了哪些文件）简要告诉我。

技能主页：${SITE_URL}/skills/${slug}`
}
