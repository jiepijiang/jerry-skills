/**
 * 生成 public/install.sh 与 public/install.ps1
 * ---------------------------------------------------------------------------
 * 两个安装器里都要内联 Supabase 端点（anon key 是公开的，写进去没问题）。
 * 端点来自**构建期环境变量**，所以脚本得在构建前生成一次。
 *
 * 运行时机：package.json 的 predev / prebuild（npm 会自动跑 pre* 钩子）。
 *
 * 为什么两个安装器共用一个生成器：
 *   读 .env、替换占位符、「替换不干净就报错」这套逻辑，两处各写一份迟早会漂移。
 *   漂移的症状特别难查 —— 表现为「macOS 能装、Windows 装不了」。
 *   所以**模板分开、生成逻辑只有这一份**。
 *
 * 为什么不用「让安装器运行时再去站点上取配置」：
 *   多一次网络往返，而且站点取不到配置时脚本会静默失败 ——
 *   用户看到的是「装完了」但目录是空的。宁可构建期就把值钉死。
 *
 * 为什么生成物进 .gitignore：
 *   它们和 dist/ 是同一性质 —— 「每个部署环境一份」的产物。
 */
import { existsSync, mkdirSync, readFileSync, writeFileSync } from 'node:fs'
import path from 'node:path'
import { fileURLToPath } from 'node:url'

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..')

/**
 * 模板 → 产物。`env` 用来覆盖输出路径，好让单测生成到临时文件、
 * 不去动 public/ 下的真实产物（正常构建时不会设置这些变量）。
 */
const TARGETS = [
  { tpl: 'install-sh.tpl', out: 'public/install.sh', mode: 0o755, env: 'INSTALL_SH_OUT' },
  { tpl: 'install-ps1.tpl', out: 'public/install.ps1', mode: 0o644, env: 'INSTALL_PS1_OUT' },
]

/** 模板里的占位符。缺一个都会让线上安装器报错，所以下面要逐个核对替换干净。 */
const TOKENS = ['__SUPABASE_URL__', '__SUPABASE_ANON_KEY__', '__SITE_URL__']

const DEFAULT_SITE = 'https://jiepijiang.github.io/jerry-skills'

/** 极简 .env 解析：KEY=VALUE，支持 # 注释与成对引号。够用就行，不引 dotenv。 */
function readEnvFile(file) {
  if (!existsSync(file)) return {}
  const out = {}
  for (const line of readFileSync(file, 'utf8').split(/\r?\n/)) {
    const m = /^\s*([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(.*)$/.exec(line)
    if (!m) continue
    let v = m[2].trim()
    if (
      (v.startsWith('"') && v.endsWith('"') && v.length >= 2) ||
      (v.startsWith("'") && v.endsWith("'") && v.length >= 2)
    ) {
      v = v.slice(1, -1)
    }
    out[m[1]] = v
  }
  return out
}

// 优先级：进程环境变量（CI） > .env.local（本地）
const fileEnv = readEnvFile(path.join(ROOT, '.env.local'))
const pick = (key) => (process.env[key] ?? fileEnv[key] ?? '').trim()

const url = pick('VITE_SUPABASE_URL')
const key = pick('VITE_SUPABASE_ANON_KEY')
const site = (pick('VITE_SITE_URL') || DEFAULT_SITE).replace(/\/$/, '')

/**
 * 渲染一个模板。
 *
 * 🔴 缺失值一律替换成**空串**，不要「留着占位符当哨兵」。
 *    曾经的写法是 `url || '__SUPABASE_URL__'`，想用「脚本里还有占位符」来标记未注入，
 *    但 replaceAll 是全局的 —— 它把**守卫里那个哨兵**也一并替换成了真实端点，
 *    于是守卫恒真，线上每个 `curl | bash` 都直接退出 1。
 *    空串方案 + 下面的残留断言，才能同时兜住「没配」和「配了但没替换干净」。
 */
function render(tplName) {
  const src = readFileSync(path.join(ROOT, 'scripts', tplName), 'utf8')
  const out = src
    .replaceAll('__SUPABASE_URL__', url)
    .replaceAll('__SUPABASE_ANON_KEY__', key)
    .replaceAll('__SITE_URL__', site)

  // 构建期兜底：替换完不该再有任何占位符残留。留着就是「静默装个空目录」的前兆。
  const leftovers = TOKENS.filter((t) => out.includes(t))
  if (leftovers.length) {
    console.error(`❌ ${tplName} 渲染后仍有未替换的占位符：${leftovers.join(', ')}`)
    process.exit(1)
  }
  return out
}

for (const target of TARGETS) {
  const out = process.env[target.env] || path.join(ROOT, target.out)
  mkdirSync(path.dirname(out), { recursive: true })
  writeFileSync(out, render(target.tpl), { mode: target.mode })
  console.log(`✅ 已生成 ${path.relative(ROOT, out)}`)
}

if (url && key) {
  console.log(`   （端点 ${url}，anon key 长度 ${key.length}，站点 ${site}）`)
} else {
  // 不是错误：本地没配后端时也要能 build（站点会走本地演示模式）。
  // 但要说清楚，别让人以为安装脚本能用。
  console.warn(
    '⚠️  未配置 VITE_SUPABASE_URL / VITE_SUPABASE_ANON_KEY，' +
      '生成的安装器会在运行时直接报错退出（不会静默装个空目录）。',
  )
}
