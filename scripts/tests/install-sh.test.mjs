/**
 * install.sh 生成器的回归测试
 * ---------------------------------------------------------------------------
 * 这里钉的是两个**只在运行时才暴露、构建期完全看不出来**的缺陷：
 *
 *  1. 哨兵被自己替换掉。生成器是 `replaceAll('__SUPABASE_URL__', url)`，
 *     而守卫里原本写着 `[ "$ENDPOINT" = "__SUPABASE_URL__" ]` —— 那个哨兵
 *     会被一并替换成真实端点，于是守卫恒真，**线上每个 curl|bash 都直接退出 1**。
 *     构建能过、CI 能绿，只有真跑一次才发现。
 *
 *  2. `$VAR` 后面紧跟中文全角括号。bash 在部分版本 / locale 下会把多字节字符
 *     并进变量名，报 `bash: line N: AGENT<乱码>: unbound variable`，
 *     用户看到的是天书而不是那句友好的错误提示。
 *
 * 两个都是「错误路径 / 边界」上的问题，happy path 走一遍是发现不了的。
 */
import { test } from 'node:test'
import assert from 'node:assert/strict'
import { execFileSync, spawnSync } from 'node:child_process'
import { mkdtempSync, readFileSync, writeFileSync } from 'node:fs'
import { tmpdir } from 'node:os'
import path from 'node:path'
import { fileURLToPath } from 'node:url'

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..', '..')
const GEN = path.join(ROOT, 'scripts', 'gen-install-sh.mjs')

/** 生成一份 install.sh 到临时文件。传 null 表示该变量未配置。 */
function generate({ url, key, site }) {
  const dir = mkdtempSync(path.join(tmpdir(), 'install-sh-'))
  const out = path.join(dir, 'install.sh')
  const env = { ...process.env, INSTALL_SH_OUT: out }
  // 注意：pick() 用的是 ?? —— 空串**不会**回落到 .env.local，正好用来模拟「未配置」
  env.VITE_SUPABASE_URL = url ?? ''
  env.VITE_SUPABASE_ANON_KEY = key ?? ''
  env.VITE_SITE_URL = site ?? ''
  execFileSync(process.execPath, [GEN], { env, stdio: 'pipe' })
  return { sh: readFileSync(out, 'utf8'), out }
}

/** 用假端点执行生成的脚本，返回 { rc, out }。端点指向 127.0.0.1:1 会立刻连接失败 */
function runInstaller(out, args, home) {
  const r = spawnSync('bash', [out, ...args], {
    env: { ...process.env, HOME: home },
    encoding: 'utf8',
    timeout: 20000,
  })
  return { rc: r.status, out: `${r.stdout ?? ''}${r.stderr ?? ''}` }
}

const GOOD = {
  url: 'http://127.0.0.1:1',
  key: 'eyJhbGciOiJIUzI1NiJ9.fake-anon-key-for-test.sig',
  site: 'https://example.test/jerry-skills',
}

test('生成的 install.sh 语法合法', () => {
  const { out } = generate(GOOD)
  execFileSync('bash', ['-n', out]) // 语法错会抛
})

test('生成后没有残留占位符', () => {
  const { sh } = generate(GOOD)
  for (const token of ['__SUPABASE_URL__', '__SUPABASE_ANON_KEY__', '__SITE_URL__']) {
    assert.ok(!sh.includes(token), `不该残留 ${token}`)
  }
})

test('端点已注入时，守卫不会误报「没有注入后端地址」', () => {
  // 🔴 这条就是那个线上 bug 的哨兵。旧写法（哨兵被替换）会在这里红。
  const { sh, out } = generate(GOOD)
  assert.ok(sh.includes('ENDPOINT="http://127.0.0.1:1"'), '端点应被注入')

  const home = mkdtempSync(path.join(tmpdir(), 'install-home-'))
  const r = runInstaller(out, ['some-slug', '--agent', 'workbuddy'], home)
  assert.ok(
    !r.out.includes('没有注入后端地址'),
    `端点已注入却触发了守卫，说明哨兵被替换掉了。输出：\n${r.out}`,
  )
})

test('未配置端点时，守卫必须拦住（不能静默装个空目录）', () => {
  const { sh, out } = generate({ url: null, key: null, site: null })
  assert.ok(sh.includes('ENDPOINT=""'), '未配置时端点应为空串')

  const home = mkdtempSync(path.join(tmpdir(), 'install-home-'))
  const r = runInstaller(out, ['some-slug', '--agent', 'workbuddy'], home)
  assert.notEqual(r.rc, 0, '未配置时应当退出非 0')
  assert.ok(r.out.includes('没有注入后端地址'), `应当给出明确提示，实际：\n${r.out}`)
})

test('守卫只判空，不去跟某个具体 URL 比', () => {
  const { sh } = generate(GOOD)
  // 形如 [ "$ENDPOINT" = "http..." ] 的写法一律视为回归
  assert.ok(
    !/\[\s*"\$ENDPOINT"\s*=\s*"https?:/.test(sh),
    '守卫不该拿具体 URL 当哨兵 —— 那会被 replaceAll 一起替换掉',
  )
})

test('没有「变量后紧跟多字节字符」的写法', () => {
  // $VAR 后面直接跟中文（全角括号等）时，bash 会把多字节字符并进变量名
  const { sh } = generate(GOOD)
  const hits = [...sh.matchAll(/\$[A-Za-z_][A-Za-z0-9_]*(?=[^\x00-\x7F])/g)]
  assert.deepEqual(
    hits.map((m) => m[0]),
    [],
    '变量后紧跟多字节字符，必须写成 ${VAR}',
  )
})

test('未注入时错误提示可读，且不会误伤正常用法', () => {
  const { out } = generate(GOOD)
  const home = mkdtempSync(path.join(tmpdir(), 'install-home-'))

  // 缺 slug → 打印用法
  const noSlug = runInstaller(out, [], home)
  assert.notEqual(noSlug.rc, 0)
  assert.ok(noSlug.out.includes('缺少技能标识'), noSlug.out)

  // 非法 agent → 友好提示（旧写法这里会吐 bash 的 unbound variable）
  const badAgent = runInstaller(out, ['some-slug', '--agent', '瞎写的助手'], home)
  assert.notEqual(badAgent.rc, 0)
  assert.ok(badAgent.out.includes('不认识的 --agent'), `应当是友好提示，实际：\n${badAgent.out}`)
  assert.ok(!badAgent.out.includes('unbound variable'), '不该出现 bash 的 unbound variable')

  // 非法 slug（含引号，会破坏 JSON 请求体）→ 被挡下
  const badSlug = runInstaller(out, ['x","p_slug":"y', '--agent', 'workbuddy'], home)
  assert.notEqual(badSlug.rc, 0)
  assert.ok(badSlug.out.includes('非法的技能标识'), badSlug.out)
})

test('未配置时也不会误伤：用法与参数校验先于守卫', () => {
  // 参数校验在守卫之前，所以未配置时「缺 slug」仍应报缺 slug，而不是报未注入
  const { out } = generate({ url: null, key: null, site: null })
  const home = mkdtempSync(path.join(tmpdir(), 'install-home-'))
  const r = runInstaller(out, [], home)
  assert.ok(r.out.includes('缺少技能标识'), r.out)
})

// 防止「生成了却没人用」：真实构建产物的路径必须仍是 public/install.sh
test('默认输出路径仍是 public/install.sh', () => {
  const src = readFileSync(GEN, 'utf8')
  assert.ok(
    src.includes("path.join(ROOT, 'public', 'install.sh')"),
    '默认输出路径被改动了，CI 的产物校验会失配',
  )
})
