/**
 * 安装命令 / AI Agent 提示词生成
 * ---------------------------------------------------------------------------
 * 本站是纯静态托管（GitHub Pages），没有服务端可以「安装」。
 * 所以「安装」= 给用户一段**能真正跑起来**的命令，由用户本机执行：
 *
 *   ① 命令行安装：拉安装脚本，脚本从 Supabase 取技能包并落盘到对应 AI 助手的
 *      skills 目录。macOS / Linux 用 install.sh，Windows 用 install.ps1。
 *   ② AI Agent 安装：给一段自然语言提示词，粘给任意 agent，让它自己执行。
 *
 * 两者都必须**指向同一个下载源**（download_skill RPC），否则会出现
 * 「网页说装 A、实际装到 B」。
 */
import { SITE_URL, agentByKey, osByKey, DEFAULT_AGENT, DEFAULT_OS } from '@/data/site'

/**
 * 安装脚本的公开地址。
 *
 * ⚠️ 这两个文件是**构建期**由 scripts/gen-installers.mjs 生成的产物，
 *    不在仓库里（和 dist/ 同性质）。所以地址拼错时不会在本地报错，
 *    只会线上 404 —— scripts/tests/installers.test.mjs 里钉了文件名。
 */
export function installerUrl(os = DEFAULT_OS) {
  return `${SITE_URL}/${os === 'windows' ? 'install.ps1' : 'install.sh'}`
}

/**
 * 命令行安装命令（按系统）。
 *
 * macOS / Linux：
 *   `bash -s --` 把后面的参数传给脚本（`curl | bash` 时不能直接跟位置参数）。
 *
 * Windows：Windows 上没有 bash，`curl | bash` 直接执行不了，所以整条换成 PowerShell。
 *   这一行里每一段都是有原因的，别顺手「简化」：
 *
 *   - `[Net.ServicePointManager]::SecurityProtocol = …Tls12`
 *     老一些的 Windows PowerShell 5.1 默认只协商 TLS 1.0，连 GitHub Pages 会以
 *     「基础连接已经关闭」这种看不出原因的错失败。这一句是廉价的保险。
 *
 *   - `(New-Object Net.WebClient).DownloadString(...)`，而不是 `irm`
 *     `irm` 对 `application/octet-stream` 的响应在 Windows PowerShell 5.1 上返回的是
 *     **byte[]**，`[scriptblock]::Create` 会直接抛错；而 GitHub Pages 给 .ps1 发的
 *     正是这个 content-type。（PowerShell 7 上 `irm` 恰好返回字符串，所以这个坑
 *     只在 Windows 自带的 5.1 上现形 —— 本地用 pwsh 试是试不出来的。）
 *     `DownloadString` 永远返回字符串，不看 content-type。
 *
 *   - `[scriptblock]::Create(...)` + `&`，而不是 `irm … | iex`
 *     后者没法给脚本传参数，而我们要把 slug 和 agent 交进去。
 *
 *   - 不走 `powershell -File`：那得先把脚本落盘，还会撞上 ExecutionPolicy。
 *     `[scriptblock]::Create` 不落盘，也就不受执行策略限制。
 */
export function cliCommand(slug, agentKey = DEFAULT_AGENT, os = DEFAULT_OS) {
  if (os === 'windows') {
    return (
      '[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12; ' +
      `& ([scriptblock]::Create((New-Object Net.WebClient).DownloadString('${installerUrl('windows')}'))) ` +
      `-Slug ${slug} -Agent ${agentKey}`
    )
  }
  return `curl -fsSL ${installerUrl('unix')} | bash -s -- ${slug} --agent ${agentKey}`
}

/**
 * 猜一个系统，**只用来选默认值**（用户随时可以改）。
 *
 * 判据是 UA 里有没有 "win"。注意别拿 "Linux" 当「非 Windows」的判据：
 * Android 的 UA 里也有 Linux，而 macOS 的 UA 里写的是 Macintosh / Darwin。
 * 只有 Windows 的 UA 里有 "Windows" —— 所以反向判断最稳。
 *
 * Node / SSR 下没有 navigator，兜底 unix（跟 DEFAULT_OS 保持一致）。
 */
export function detectOS() {
  if (typeof navigator === 'undefined') return DEFAULT_OS
  const s = [
    navigator.userAgentData?.platform,
    navigator.platform,
    navigator.userAgent,
  ]
    .filter(Boolean)
    .join(' ')
  return /win/i.test(s) ? 'windows' : 'unix'
}

/**
 * AI Agent 安装提示词。
 * 写成「可执行 + 可核验」的样子：agent 能照着跑，用户能看出它做了什么。
 *
 * 里面带上的是**当前所选系统**的命令 —— agent 跑在同一台机器上，
 * 它该看到的就是那条能跑通的。
 */
export function agentPrompt(skill, agentKey = DEFAULT_AGENT, os = DEFAULT_OS) {
  const agent = agentByKey(agentKey)
  const osInfo = osByKey(os)
  const slug = skill?.slug || '<slug>'
  const name = skill?.name || slug
  const cmd = cliCommand(slug, agentKey, os)

  return `请帮我把 AI Agent 技能「${name}」安装到 ${agent.label} 的 skills 目录。

${osInfo.promptLine}

    ${cmd}

要求：
1. 安装目标目录是 ${agent.dir}，技能会落在 ${agent.dir}/${slug}。
2. 如果该目录已存在，先把旧目录改名备份（加 .bak 后缀），再安装，不要直接删。
3. 安装完成后，请列出 ${agent.dir}/${slug} 的内容，确认 SKILL.md 在里面。
4. 把结果（成功/失败、装了哪些文件）简要告诉我。

技能主页：${SITE_URL}/skills/${slug}`
}
