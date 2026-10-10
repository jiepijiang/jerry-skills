/**
 * 安装命令生成（src/lib/install.js）的测试
 * ---------------------------------------------------------------------------
 * 这一段是**用户直接复制走**的东西 —— 拼错了不会报错，只会让对方的终端吐一行
 * 看不懂的英文。所以每一段都得钉住。
 *
 * 用 vite 的 ssrLoadModule 真加载一次模块（它 import 了 @/data/site，
 * 那个文件用了 import.meta.env，Node 里直接 import 会炸）。
 */
import { after, before, test } from 'node:test'
import assert from 'node:assert/strict'
import { readFileSync } from 'node:fs'

import { ROOT, createSsrServer } from './_ssr.mjs'

let server
let install
let site

before(async () => {
  server = await createSsrServer()
  install = await server.ssrLoadModule('/src/lib/install.js')
  site = await server.ssrLoadModule('/src/data/site.js')
})

after(async () => {
  await server?.close()
})

const SKILL = { slug: 'pdf-editor', name: 'PDF 编辑器' }

/* ------------------------------------------------------------ 脚本地址 */

test('macOS/Linux 拿 install.sh，Windows 拿 install.ps1', () => {
  assert.ok(install.installerUrl('unix').endsWith('/install.sh'), install.installerUrl('unix'))
  assert.ok(install.installerUrl('windows').endsWith('/install.ps1'), install.installerUrl('windows'))
})

test('不传 os 时默认走 macOS/Linux（和 DEFAULT_OS 一致）', () => {
  assert.equal(install.installerUrl(), install.installerUrl(site.DEFAULT_OS))
  assert.equal(install.installerUrl(), install.installerUrl('unix'))
})

test('两个脚本地址只差文件名，站点前缀必须相同', () => {
  const a = install.installerUrl('unix')
  const b = install.installerUrl('windows')
  assert.equal(a.slice(0, a.lastIndexOf('/')), b.slice(0, b.lastIndexOf('/')))
})

/* ---------------------------------------------------------- 命令行命令 */

test('macOS/Linux 的命令是 curl … install.sh | bash -s --', () => {
  const cmd = install.cliCommand('pdf-editor', 'claude', 'unix')
  // SSR 里没有站点地址（SITE_URL 是空串），所以前缀用 \S* 而不是 \S+
  assert.match(cmd, /^curl -fsSL \S*\/install\.sh \| bash -s -- pdf-editor --agent claude$/, cmd)
})

test('Windows 的命令是 PowerShell 那条，且不掺 bash', () => {
  const cmd = install.cliCommand('pdf-editor', 'claude', 'windows')
  assert.ok(cmd.includes('/install.ps1'), cmd)
  assert.ok(!cmd.includes('| bash'), 'Windows 上不能出现 | bash')
  assert.ok(!/\bcurl\b/.test(cmd), 'Windows 上不要混进 curl')
})

test('Windows 命令的四段关键写法都在（少一段就装不上）', () => {
  const cmd = install.cliCommand('pdf-editor', 'claude', 'windows')
  // ① 老 PowerShell 5.1 默认只协商 TLS 1.0，不补这句会以「基础连接已经关闭」失败
  assert.ok(cmd.includes('SecurityProtocol=[Net.SecurityProtocolType]::Tls12'), '缺 TLS 1.2')
  // ② 必须用 DownloadString 而不是 irm：irm 遇到 application/octet-stream 在 PS 5.1 上
  //    返回 byte[]，scriptblock::Create 会直接抛错，而 GitHub Pages 发的就是这个类型
  assert.ok(cmd.includes('(New-Object Net.WebClient).DownloadString('), '缺 DownloadString')
  // ③ 必须用 scriptblock::Create 才能把参数传进去（irm | iex 传不了参）
  assert.ok(cmd.includes('[scriptblock]::Create('), '缺 scriptblock::Create')
  // ④ 参数要真的带上
  assert.ok(cmd.includes('-Slug pdf-editor'), '缺 -Slug')
  assert.ok(cmd.includes('-Agent claude'), '缺 -Agent')
})

test('★ 两条命令都必须是一整行 —— 界面上换行只是 CSS 的事', () => {
  // 详情页给命令行那块加了 white-space: pre-wrap（Windows 那条太长，不换行读不全）。
  // 万一哪天有人图省事，在**字符串里**插了真换行，粘进终端就会变成两条命令。
  for (const os of ['unix', 'windows']) {
    const cmd = install.cliCommand('pdf-editor', 'claude', os)
    assert.ok(!cmd.includes('\n'), `${os} 的命令里出现了真换行符：\n${cmd}`)
    assert.equal(cmd, cmd.trim(), `${os} 的命令首尾有多余空白`)
  }
})

test('slug / agent 会原样出现在命令里（不写死默认值）', () => {
  const a = install.cliCommand('中文技能', 'cursor', 'unix')
  assert.ok(a.includes('中文技能') && a.includes('--agent cursor'), a)
  const b = install.cliCommand('中文技能', 'cursor', 'windows')
  assert.ok(b.includes('中文技能') && b.includes('-Agent cursor'), b)
})

test('不给参数时用默认 agent', () => {
  assert.ok(install.cliCommand('x', undefined, 'unix').includes(`--agent ${site.DEFAULT_AGENT}`))
  assert.ok(install.cliCommand('x', undefined, 'windows').includes(`-Agent ${site.DEFAULT_AGENT}`))
})

/* ------------------------------------------------------------ 系统猜测 */

test('没有 navigator（Node / SSR）时猜 unix，不炸', () => {
  assert.equal(install.detectOS(), site.DEFAULT_OS)
})

test('系统只有两档，且 key 与 install.js 的分支对得上', () => {
  assert.deepEqual(
    site.oses.map((o) => o.key).sort(),
    ['unix', 'windows'],
    '多了第三档的话，installerUrl / cliCommand 会静默按 unix 处理 —— 那是最糟的失败方式',
  )
  assert.equal(site.osByKey('windows').key, 'windows')
  assert.equal(site.osByKey('瞎写的').key, 'unix', '认不出来时兜底 unix')
})

/* --------------------------------------------------------- AI 提示词 */

test('AI 提示词里带的是当前所选系统的那条命令', () => {
  const unix = install.agentPrompt(SKILL, 'claude', 'unix')
  assert.ok(unix.includes('/install.sh | bash'), unix)
  assert.ok(!unix.includes('/install.ps1'), '选 macOS/Linux 时不该出现 ps1')
  assert.ok(unix.includes('在终端（Terminal）里执行这条命令即可：'), '要告诉 agent 在哪儿执行')

  const win = install.agentPrompt(SKILL, 'claude', 'windows')
  assert.ok(win.includes('/install.ps1'), win)
  assert.ok(!win.includes('| bash'), '选 Windows 时不该出现 bash 那条')
  assert.ok(win.includes('在 PowerShell 里执行这条命令即可：'), '要告诉 agent 在 PowerShell 里跑')
  // 别拼出「在 在…」这种叠字
  assert.ok(!/在\s+在/.test(win) && !/在\s+在/.test(unix), '提示词里不该出现「在 在」')
})

test('AI 提示词里写清了落盘目录，且两处目录来自同一份配置', () => {
  const p = install.agentPrompt(SKILL, 'cursor', 'unix')
  const dir = site.agentByKey('cursor').dir
  assert.ok(p.includes(dir), `提示词里应该有 ${dir}`)
  assert.ok(p.includes(`${dir}/${SKILL.slug}`), '要写清最终落点')
})

/* ------------------------------------------------- 界面那边别写成真换行 */

test('详情页给命令行块挂了 cmd-block（不然 Windows 那条读不全）', () => {
  const vue = readFileSync(`${ROOT}src/views/SkillDetailView.vue`, 'utf8')
  assert.ok(/class="code-block cmd-block"/.test(vue), '命令行那块应该有 cmd-block 类')

  const css = readFileSync(`${ROOT}src/styles/hub.css`, 'utf8').replace(/\/\*[\s\S]*?\*\//g, '')
  assert.ok(/\.cmd-block pre\s*\{[^}]*white-space:\s*pre-wrap/.test(css), 'cmd-block 的 pre 要允许换行')
})
