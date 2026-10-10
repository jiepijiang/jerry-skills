/**
 * 生成 public/install.sh
 * ---------------------------------------------------------------------------
 * install.sh 里需要内联 Supabase 端点（anon key 是公开的，写进去没问题）。
 * 但端点来自**构建期环境变量**，所以脚本得在构建前生成一次。
 *
 * 运行时机：package.json 的 predev / prebuild（npm 会自动跑 pre* 钩子）。
 *
 * 为什么不用「让 install.sh 运行时再去站点上取配置」：
 *   多一次网络往返，而且站点取不到配置时脚本会静默失败 ——
 *   用户看到的是「装完了」但目录是空的。宁可构建期就把值钉死。
 *
 * 为什么 public/install.sh 进 .gitignore：
 *   它和 dist/ 是同一性质 —— 「每个部署环境一份」的产物。
 */
import { existsSync, mkdirSync, readFileSync, writeFileSync } from 'node:fs'
import path from 'node:path'
import { fileURLToPath } from 'node:url'

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..')
const TPL = path.join(ROOT, 'scripts', 'install-sh.tpl')
const OUT = path.join(ROOT, 'public', 'install.sh')

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

let sh = readFileSync(TPL, 'utf8')
sh = sh.replaceAll('__SUPABASE_URL__', url || '__SUPABASE_URL__')
sh = sh.replaceAll('__SUPABASE_ANON_KEY__', key || '')
sh = sh.replaceAll('__SITE_URL__', site)

mkdirSync(path.dirname(OUT), { recursive: true })
writeFileSync(OUT, sh, { mode: 0o755 })

if (url && key) {
  console.log(`✅ 已生成 public/install.sh（端点 ${url}，anon key 长度 ${key.length}）`)
} else {
  // 不是错误：本地没配后端时也要能 build（站点会走本地演示模式）。
  // 但要说清楚，别让人以为安装脚本能用。
  console.warn(
    '⚠️  未配置 VITE_SUPABASE_URL / VITE_SUPABASE_ANON_KEY，' +
      '生成的 install.sh 会在运行时直接报错退出（不会静默装个空目录）。',
  )
}
