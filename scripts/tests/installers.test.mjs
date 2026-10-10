/**
 * 两个安装脚本（install.sh / install.ps1）生成器的回归测试
 * ---------------------------------------------------------------------------
 * 这里钉的都是**构建期完全看不出来、只有真跑一次才暴露**的缺陷。已经踩到的：
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
 *  3. PowerShell 侧同类坑：变量名会把紧跟其后的**中文字符吃进去**，结果是空串
 *     而且**不报错**。同一个道理，`$var.bak` 会被当成「取名为 bak 的属性」。
 *     所以模板里一律写 `${VAR}` —— 下面用正则把这条规则钉死。
 *
 *  4. `exit` 会关掉用户的终端。install.ps1 是被 `[scriptblock]::Create(...)` 之后
 *     用 `&` 调起来的；在**交互式** PowerShell 里 `exit` 会直接结束用户整个会话
 *     （实测：exit 之后同一条命令串里后面的语句根本不执行）。所以 install.ps1
 *     里**一个 exit 都不能有**，失败一律走 throw。
 *
 *  5. Expand-Archive 的进度条在非交互式宿主里会被渲染成文字混进输出流，
 *     而压制它必须用 `$global:ProgressPreference`（模块函数看不到调用方局部作用域）。
 *
 *  6. 模板里写了个**生成器不认识**的占位符，于是原样发布。真实案例：
 *     install-sh.tpl 的 `--help` 示例里写着 `__SITE__/install.sh`，而生成器只认
 *     `__SITE_URL__` —— 用户跑 `--help` 看到的是个连不上的地址。这类漏法能同时
 *     躲过「残留占位符」检查（不在名单里）、CI 产物核对（只查真实 URL 在不在）
 *     和语法检查（它只是个字符串字面量）。所以下面那条断言是**反向**查的：
 *     模板里出现的任何 `__XXX__` 都必须认识。
 *
 * 5 是「能跑但输出脏」，1~4、6 是「跑不起来」或「把用户终端关了」或「发布了坏地址」。
 */
import { test } from 'node:test'
import assert from 'node:assert/strict'
import { execFileSync, spawn, spawnSync } from 'node:child_process'
import { existsSync, mkdtempSync, readFileSync, readdirSync, writeFileSync } from 'node:fs'
import { createServer } from 'node:http'
import { tmpdir } from 'node:os'
import path from 'node:path'
import { fileURLToPath } from 'node:url'

import { strToU8, zipSync } from 'fflate'

// ⚠️ 用 `new URL('../..')` 而不是 path.resolve(...)：前者**带结尾斜杠**，
//    后面 `${ROOT}src/…` 才拼得对。用 path.resolve 会得到不带斜杠的路径，
//    拼出来就是 `…/jerry-skillssrc/data/site.js` 这种找不到的文件。
const ROOT = fileURLToPath(new URL('../..', import.meta.url))
const GEN = path.join(ROOT, 'scripts', 'gen-installers.mjs')

/**
 * 生成两个安装脚本到临时文件。传 null 表示该变量未配置。
 * 返回脚本内容与**落盘路径**（ps1 的端到端用例要拿路径去跑）。
 */
function generate({ url, key, site }) {
  const dir = mkdtempSync(path.join(tmpdir(), 'installers-'))
  const shPath = path.join(dir, 'install.sh')
  const ps1Path = path.join(dir, 'install.ps1')
  const env = {
    ...process.env,
    INSTALL_SH_OUT: shPath,
    INSTALL_PS1_OUT: ps1Path,
  }
  // 注意：pick() 用的是 ?? —— 空串**不会**回落到 .env.local，正好用来模拟「未配置」
  env.VITE_SUPABASE_URL = url ?? ''
  env.VITE_SUPABASE_ANON_KEY = key ?? ''
  env.VITE_SITE_URL = site ?? ''
  execFileSync(process.execPath, [GEN], { env, stdio: 'pipe' })
  return {
    sh: readFileSync(shPath, 'utf8'),
    ps1: readFileSync(ps1Path, 'utf8'),
    shPath,
    ps1Path,
  }
}

/** 用假端点执行生成的 bash 脚本，返回 { rc, out }。端点指向 127.0.0.1:1 会立刻连接失败 */
function runInstaller(out, args, home) {
  const r = spawnSync('bash', [out, ...args], {
    env: { ...process.env, HOME: home },
    encoding: 'utf8',
    timeout: 20000,
  })
  return { rc: r.status, out: `${r.stdout ?? ''}${r.stderr ?? ''}` }
}

/**
 * 本机的 PowerShell。没有就跳过依赖运行时的用例 ——
 * 但**不依赖运行时的那些（正则 / 源码断言）永远会跑**，
 * 上面 1~4 号坑里有一半是靠正则就能钉死的。
 *
 * 本地想跑完整用例：export PWSH_PATH=/path/to/pwsh
 * （这台机器上 pwsh 不在 PATH 里，是从官方 tarball 解到 ~/.workbuddy-ai/binaries/pwsh 的。）
 */
const PWSH = (() => {
  for (const cand of [process.env.PWSH_PATH, 'pwsh'].filter(Boolean)) {
    const r = spawnSync(cand, ['-NoProfile', '-Command', '$PSVersionTable.PSVersion.Major'], {
      encoding: 'utf8',
    })
    if (r.status === 0) return cand
  }
  return null
})()

const NO_PWSH = PWSH ? false : '本机没有 pwsh（可设 PWSH_PATH 指定）'

/**
 * 跑生成的 ps1。`args` 是**拼好的参数串**（参数名不加引号，值自己带引号），
 * 例如 `-Slug 'demo' -Agent 'claude'`。
 *
 * ⚠️ 这里必须用**异步**的 spawn，不能图省事用 spawnSync。
 *    靶场（假 Supabase）就跑在同一个 node 进程里 —— spawnSync 会把事件循环堵死，
 *    服务端永远 accept 不到那个请求，pwsh 一路等到超时。
 *    症状特别有迷惑性：用例全在 30 秒后失败，看起来像「脚本连不上网」，
 *    其实是「测试自己把服务器掐住了」。
 */
function runPs1(ps1Path, args, home) {
  const q = (s) => `'${String(s).replace(/'/g, "''")}'`
  return spawnPs1(`& ([scriptblock]::Create((Get-Content -Raw ${q(ps1Path)}))) ${args}`, home)
}

/** 跑一条任意的 PowerShell 命令（异步），返回 { rc, out } */
function spawnPs1(cmd, home) {
  return new Promise((resolve) => {
    const env = { ...process.env, HOME: home, NO_PROXY: '127.0.0.1,localhost' }
    // 本地/CI 可能带着代理变量（这个沙箱就注入了 HTTP_PROXY），会拦掉 127.0.0.1 的请求
    for (const k of ['http_proxy', 'https_proxy', 'HTTP_PROXY', 'HTTPS_PROXY', 'ALL_PROXY']) {
      delete env[k]
    }

    const child = spawn(PWSH, ['-NoProfile', '-Command', cmd], { env })
    let out = ''
    const timer = setTimeout(() => child.kill('SIGKILL'), 30000)
    child.stdout.on('data', (d) => (out += d))
    child.stderr.on('data', (d) => (out += d))
    child.on('close', (code) => {
      clearTimeout(timer)
      resolve({ rc: code, out })
    })
  })
}

const GOOD = {
  url: 'http://127.0.0.1:1',
  key: 'eyJhbGciOiJIUzI1NiJ9.fake-anon-key-for-test.sig',
  site: 'https://example.test/jerry-skills',
}

/* ============================================================ install.sh */

test('生成的 install.sh 语法合法', () => {
  const { shPath } = generate(GOOD)
  execFileSync('bash', ['-n', shPath]) // 语法错会抛
})

test('生成后没有残留占位符（两个脚本都要查）', () => {
  const { sh, ps1 } = generate(GOOD)
  for (const token of ['__SUPABASE_URL__', '__SUPABASE_ANON_KEY__', '__SITE_URL__']) {
    assert.ok(!sh.includes(token), `install.sh 里不该残留 ${token}`)
    assert.ok(!ps1.includes(token), `install.ps1 里不该残留 ${token}`)
  }
})

test('★ 模板里出现的每一个 __TOKEN__ 都必须在替换名单里（否则会原样发布）', () => {
  // 真实踩到（上一版就有，一直漏到线上）：install-sh.tpl 的 `--help` 示例里写着
  // `curl -fsSL __SITE__/install.sh`，而生成器只替换 `__SITE_URL__` ——
  // 于是那串 `__SITE__` 原封不动进了产物，用户跑 `install.sh --help` 看到的
  // 是一个连不上的地址。
  //
  // 为什么别的检查都没拦住它：
  //   - 上面那条「没有残留占位符」只查 TOKENS 里那三个，`__SITE__` 不在名单里；
  //   - CI 的产物核对查的是「真实 URL 在不在」，不看有没有别的怪 token；
  //   - 语法完全合法（它只是个字符串字面量），`bash -n` / PS 解析器都过。
  // 所以必须**反过来查**：模板里出现的任何 `__XXX__` 都得是认识的。
  const TOKENS = ['__SUPABASE_URL__', '__SUPABASE_ANON_KEY__', '__SITE_URL__']
  for (const tpl of ['install-sh.tpl', 'install-ps1.tpl']) {
    const src = readFileSync(path.join(ROOT, 'scripts', tpl), 'utf8')
    const found = [...new Set([...src.matchAll(/__[A-Za-z0-9_]+__/g)].map((m) => m[0]))]
    const unknown = found.filter((t) => !TOKENS.includes(t))
    assert.deepEqual(
      unknown,
      [],
      `${tpl} 里有生成器不认识的占位符：${JSON.stringify(unknown)}\n` +
        `要么改用 ${TOKENS.join(' / ')} 之一，要么把它加进 gen-installers.mjs 的 TOKENS。`,
    )
  }
})

test('端点已注入时，守卫不会误报「没有注入后端地址」', () => {
  // 🔴 这条就是那个线上 bug 的哨兵。旧写法（哨兵被替换）会在这里红。
  const { sh, shPath } = generate(GOOD)
  assert.ok(sh.includes('ENDPOINT="http://127.0.0.1:1"'), '端点应被注入')

  const home = mkdtempSync(path.join(tmpdir(), 'install-home-'))
  const r = runInstaller(shPath, ['some-slug', '--agent', 'workbuddy'], home)
  assert.ok(
    !r.out.includes('没有注入后端地址'),
    `端点已注入却触发了守卫，说明哨兵被替换掉了。输出：\n${r.out}`,
  )
})

test('未配置端点时，守卫必须拦住（不能静默装个空目录）', () => {
  const { sh, shPath } = generate({ url: null, key: null, site: null })
  assert.ok(sh.includes('ENDPOINT=""'), '未配置时端点应为空串')

  const home = mkdtempSync(path.join(tmpdir(), 'install-home-'))
  const r = runInstaller(shPath, ['some-slug', '--agent', 'workbuddy'], home)
  assert.notEqual(r.rc, 0, '未配置时应当退出非 0')
  assert.ok(r.out.includes('没有注入后端地址'), `应当给出明确提示，实际：\n${r.out}`)
})

test('守卫只判空，不去跟某个具体 URL 比（两个脚本都适用）', () => {
  const { sh, ps1 } = generate(GOOD)
  // 形如 [ "$ENDPOINT" = "http..." ] 的写法一律视为回归
  assert.ok(
    !/\[\s*"\$ENDPOINT"\s*=\s*"https?:/.test(sh),
    '守卫不该拿具体 URL 当哨兵 —— 那会被 replaceAll 一起替换掉',
  )
  // PowerShell 侧同理：不能出现 -eq '__SUPABASE_URL__' 之类
  assert.ok(
    !/\$Endpoint\s+-eq\s+['"]https?:/.test(ps1),
    'install.ps1 的守卫也不该拿具体 URL 当哨兵',
  )
  assert.ok(
    /IsNullOrEmpty\(\$Endpoint\)/.test(ps1),
    'install.ps1 的守卫应该是判空',
  )
})

test('没有「变量后紧跟多字节字符」的写法（bash 与 PowerShell 同一个坑）', () => {
  const { sh, ps1 } = generate(GOOD)
  for (const [name, src] of [
    ['install.sh', sh],
    ['install.ps1', ps1],
  ]) {
    // $VAR 后面直接跟中文（全角括号等）时，两个 shell 都会把它并进变量名
    const hits = [...src.matchAll(/\$[A-Za-z_][A-Za-z0-9_]*(?=[^\x00-\x7F])/g)]
    assert.deepEqual(
      hits.map((m) => m[0]),
      [],
      `${name} 里有变量后紧跟多字节字符，必须写成 \${VAR} 或 \${VAR}`,
    )
  }
})

test('install.ps1 里一个 exit 都不能有（exit 会关掉用户的终端）', () => {
  const { ps1 } = generate(GOOD)
  // 🔴 实测：`& ([scriptblock]::Create(...))` 起的脚本里执行 exit，
  //    交互式 PowerShell 会**直接结束整个会话**（用户终端窗口消失）。
  //    失败路径必须走 throw。
  const hits = [...ps1.matchAll(/^\s*exit\b.*$/gm)].map((m) => m[0].trim())
  assert.deepEqual(hits, [], 'install.ps1 里出现 exit 会关掉用户终端，必须改成 throw')
})

test('install.ps1 用 $global:ProgressPreference 压制进度条，并且用完还原', () => {
  const { ps1 } = generate(GOOD)
  // 普通赋值**不管用**：Expand-Archive 来自 Microsoft.PowerShell.Archive 模块，
  // 模块函数看不到调用方的局部作用域，只认全局那个偏好变量。
  assert.ok(
    /\$global:ProgressPreference\s*=\s*'SilentlyContinue'/.test(ps1),
    '必须用 $global:ProgressPreference，否则 Expand-Archive 的进度条会混进输出',
  )
  assert.ok(
    /\$global:ProgressPreference\s*=\s*\$PrevProgressPreference/.test(ps1),
    '改过全局偏好变量就必须还原 —— 别把用户会话的设置改掉',
  )
})

test('未注入时错误提示可读，且不会误伤正常用法', () => {
  const { shPath } = generate(GOOD)
  const home = mkdtempSync(path.join(tmpdir(), 'install-home-'))

  // 缺 slug → 打印用法
  const noSlug = runInstaller(shPath, [], home)
  assert.notEqual(noSlug.rc, 0)
  assert.ok(noSlug.out.includes('缺少技能标识'), noSlug.out)

  // 非法 agent → 友好提示（旧写法这里会吐 bash 的 unbound variable）
  const badAgent = runInstaller(shPath, ['some-slug', '--agent', '瞎写的助手'], home)
  assert.notEqual(badAgent.rc, 0)
  assert.ok(badAgent.out.includes('不认识的 --agent'), `应当是友好提示，实际：\n${badAgent.out}`)
  assert.ok(!badAgent.out.includes('unbound variable'), '不该出现 bash 的 unbound variable')

  // 非法 slug（含引号，会破坏 JSON 请求体）→ 被挡下
  const badSlug = runInstaller(shPath, ['x","p_slug":"y', '--agent', 'workbuddy'], home)
  assert.notEqual(badSlug.rc, 0)
  assert.ok(badSlug.out.includes('非法的技能标识'), badSlug.out)
})

test('未配置时也不会误伤：用法与参数校验先于守卫', () => {
  // 参数校验在守卫之前，所以未配置时「缺 slug」仍应报缺 slug，而不是报未注入
  const { shPath } = generate({ url: null, key: null, site: null })
  const home = mkdtempSync(path.join(tmpdir(), 'install-home-'))
  const r = runInstaller(shPath, [], home)
  assert.ok(r.out.includes('缺少技能标识'), r.out)
})

/* ========================================================== install.ps1 */

test('生成的 install.ps1 能通过 PowerShell 解析器', { skip: NO_PWSH }, () => {
  const { ps1Path } = generate(GOOD)
  const r = spawnSync(
    PWSH,
    [
      '-NoProfile',
      '-Command',
      `$e = $null; [void][System.Management.Automation.Language.Parser]::ParseFile('${ps1Path}', [ref]$null, [ref]$e); if ($e.Count) { $e | ForEach-Object { $_.Message }; exit 9 }`,
    ],
    { encoding: 'utf8' },
  )
  assert.equal(r.status, 0, `语法有错：\n${r.stdout}${r.stderr}`)
})

test('install.ps1：端点已注入时守卫不误报；未注入时必须拦住', { skip: NO_PWSH }, async () => {
  const home = mkdtempSync(path.join(tmpdir(), 'install-home-'))

  // ⚠️ 这里必须指向一个**真在听的**端点，不能像 bash 那样用 127.0.0.1:1 图省事。
  //    .NET 的 HttpClient 连一个没人听的端口不会立刻 ECONNREFUSED，而是一路等到
  //    -TimeoutSec —— 实测每个用例白等 60 秒，整个套件从 10 秒涨到 150 秒。
  const site = await startFakeSupabase()
  try {
    const injected = generate({
      url: `http://127.0.0.1:${site.port}`,
      key: 'fake-anon-key',
      site: `http://127.0.0.1:${site.port}`,
    })
    const ok = await runPs1(injected.ps1Path, `-Slug 'demo' -Agent 'workbuddy'`, home)
    assert.ok(
      !ok.out.includes('没有注入后端地址'),
      `端点已注入却触发了守卫，说明哨兵被替换掉了。输出：\n${ok.out}`,
    )
    assert.ok(ok.out.includes('已安装到'), `端点已注入时应该能装成功，实际：\n${ok.out}`)
  } finally {
    await site.close()
  }

  const empty = generate({ url: null, key: null, site: null })
  const blocked = await runPs1(empty.ps1Path, `-Slug 'demo'`, home)
  assert.notEqual(blocked.rc, 0, '未配置时应当退出非 0')
  assert.ok(
    blocked.out.includes('没有注入后端地址'),
    `应当给出明确提示，实际：\n${blocked.out}`,
  )
})

test('install.ps1：参数校验的提示可读，且退出码非 0', { skip: NO_PWSH }, async () => {
  const { ps1Path } = generate(GOOD)
  const home = mkdtempSync(path.join(tmpdir(), 'install-home-'))

  // 缺 slug
  const noSlug = await runPs1(ps1Path, '', home)
  assert.notEqual(noSlug.rc, 0)
  assert.ok(noSlug.out.includes('缺少技能标识'), noSlug.out)
  assert.ok(noSlug.out.includes('用法'), '缺 slug 时应该把用法打出来')

  // 瞎写的 agent → 友好提示，而不是 PowerShell 的参数绑定报错
  const badAgent = await runPs1(ps1Path, `-Slug 'demo' -Agent '瞎写的助手'`, home)
  assert.notEqual(badAgent.rc, 0)
  assert.ok(badAgent.out.includes('不认识的 -Agent'), `应当是友好提示，实际：\n${badAgent.out}`)
  assert.ok(!badAgent.out.includes('ParameterBindingException'), '不该抛 PowerShell 的参数绑定异常')

  // 含引号 / 反斜杠的 slug（能构造畸形 JSON）→ 被挡下
  const badSlug = await runPs1(ps1Path, `-Slug 'x","p_slug":"y'`, home)
  assert.notEqual(badSlug.rc, 0)
  assert.ok(badSlug.out.includes('非法的技能标识'), badSlug.out)
})

test('install.ps1：-Help 打印用法并且不报错', { skip: NO_PWSH }, async () => {
  const { ps1Path } = generate(GOOD)
  const home = mkdtempSync(path.join(tmpdir(), 'install-home-'))
  const r = await runPs1(ps1Path, '-Help', home)
  assert.equal(r.rc, 0, r.out)
  assert.ok(r.out.includes('用法'), r.out)
  assert.ok(r.out.includes('workbuddy'), '用法里应该列出可选的安装目标')
})

test('install.ps1：改全局偏好变量之后，用户会话的设置要还原', { skip: NO_PWSH }, async () => {
  const site = await startFakeSupabase()
  try {
    const { ps1Path } = generate({
      url: `http://127.0.0.1:${site.port}`,
      key: 'fake-anon-key',
      site: `http://127.0.0.1:${site.port}`,
    })
    const home = mkdtempSync(path.join(tmpdir(), 'install-home-'))
    const q = (s) => `'${s}'`
    // 模拟交互式：同一条命令串里，脚本跑完之后再读一次偏好变量。
    // 这正是「exit 会关掉终端」那个坑的形态 —— 如果脚本里写了 exit，
    // 后面这句 Write-Host 根本不会执行，测试就会红。
    const cmd =
      `$before = $global:ProgressPreference; ` +
      `& ([scriptblock]::Create((Get-Content -Raw ${q(ps1Path)}))) -Slug 'demo' -Agent 'claude' | Out-Null; ` +
      `Write-Host "RESTORED:$($before -eq $global:ProgressPreference)"`
    const r = await spawnPs1(cmd, home)
    assert.ok(
      r.out.includes('RESTORED:True'),
      `脚本跑完应该把 ProgressPreference 还原，实际输出：\n${r.out}`,
    )
  } finally {
    await site.close()
  }
})

/* ================================================= install.ps1 端到端 */

/** 起一个只实现 download_skill 的假 Supabase，返回端口和收到的 slug 列表 */
async function startFakeSupabase() {
  const zip = Buffer.from(
    zipSync({
      'SKILL.md': strToU8('---\nname: demo\nversion: 1.0.0\n---\n# demo\n'),
      'scripts/run.sh': strToU8('echo hi\n'),
    }),
  )
  const b64 = zip.toString('base64')
  const hits = []

  const server = createServer((req, res) => {
    let raw = ''
    req.on('data', (c) => (raw += c))
    req.on('end', () => {
      let slug = null
      try {
        slug = JSON.parse(raw).p_slug
      } catch {
        /* 按 null 处理 */
      }
      hits.push(slug)
      const payload = !slug
        ? { ok: false, code: 'invalid_payload' }
        : slug === 'nope'
          ? { ok: false, code: 'not_found' }
          : { ok: true, code: 'created', bundle_b64: b64, filename: `${slug}.zip` }
      const body = Buffer.from(JSON.stringify(payload), 'utf8')
      res.writeHead(200, { 'Content-Type': 'application/json', 'Content-Length': body.length })
      res.end(body)
    })
  })

  await new Promise((resolve) => server.listen(0, '127.0.0.1', resolve))
  return {
    port: server.address().port,
    hits,
    close: () => new Promise((resolve) => server.close(resolve)),
  }
}

test('端到端：install.ps1 真能把技能装到目标目录，且再装一次会先备份', { skip: NO_PWSH }, async () => {
  const site = await startFakeSupabase()
  try {
    const { ps1Path } = generate({
      url: `http://127.0.0.1:${site.port}`,
      key: 'fake-anon-key',
      site: `http://127.0.0.1:${site.port}`,
    })
    const home = mkdtempSync(path.join(tmpdir(), 'install-home-'))
    const target = path.join(home, '.claude', 'skills', 'demo')

    const first = await runPs1(ps1Path, `-Slug 'demo' -Agent 'claude'`, home)
    assert.equal(first.rc, 0, `第一次安装应当成功，实际：\n${first.out}`)
    assert.ok(existsSync(path.join(target, 'SKILL.md')), `SKILL.md 应该落盘，实际输出：\n${first.out}`)
    assert.ok(existsSync(path.join(target, 'scripts', 'run.sh')), '子目录里的文件也要在')
    assert.deepEqual(site.hits, ['demo'], '服务端收到的 p_slug 应该原样不变')

    // 用户改过内容之后再装一次 —— 必须备份而不是直接删
    writeFileSync(path.join(target, 'SKILL.md'), '我改过的内容\n')
    const second = await runPs1(ps1Path, `-Slug 'demo' -Agent 'claude'`, home)
    assert.equal(second.rc, 0, `第二次安装应当成功，实际：\n${second.out}`)
    assert.ok(second.out.includes('已备份原目录到'), `应当提示备份了，实际：\n${second.out}`)

    const backups = readdirSync(path.join(home, '.claude', 'skills')).filter((n) =>
      n.startsWith('demo.bak.'),
    )
    assert.equal(backups.length, 1, '应当产生一个 .bak 目录')
    assert.ok(
      readFileSync(path.join(home, '.claude', 'skills', backups[0], 'SKILL.md'), 'utf8').includes(
        '我改过的内容',
      ),
      '备份里必须留着用户改过的内容',
    )
  } finally {
    await site.close()
  }
})

test('端到端：中文 slug 不会被编码弄坏', { skip: NO_PWSH }, async () => {
  const site = await startFakeSupabase()
  try {
    const { ps1Path } = generate({
      url: `http://127.0.0.1:${site.port}`,
      key: 'fake-anon-key',
      site: `http://127.0.0.1:${site.port}`,
    })
    const home = mkdtempSync(path.join(tmpdir(), 'install-home-'))
    const r = await runPs1(ps1Path, `-Slug '中文技能' -Agent 'cursor'`, home)

    assert.equal(r.rc, 0, `中文 slug 应当能装成功，实际：\n${r.out}`)
    assert.deepEqual(site.hits, ['中文技能'], '服务端收到的应该是完整的中文 slug，不是乱码')
    assert.ok(existsSync(path.join(home, '.cursor', 'skills', '中文技能', 'SKILL.md')), r.out)
  } finally {
    await site.close()
  }
})

test('端到端：服务端说 not_found 时，给出可操作的提示', { skip: NO_PWSH }, async () => {
  const site = await startFakeSupabase()
  try {
    const { ps1Path } = generate({
      url: `http://127.0.0.1:${site.port}`,
      key: 'fake-anon-key',
      site: `http://127.0.0.1:${site.port}`,
    })
    const home = mkdtempSync(path.join(tmpdir(), 'install-home-'))
    const r = await runPs1(ps1Path, `-Slug 'nope' -Agent 'claude'`, home)

    assert.notEqual(r.rc, 0)
    assert.ok(r.out.includes('没有找到这个技能'), r.out)
    // 中文技能名在 Windows 上还有第二个失败原因（终端代码页），要顺带提一句
    assert.ok(r.out.includes('编码'), `应当提示可能是编码问题，实际：\n${r.out}`)
  } finally {
    await site.close()
  }
})

/* ==================================================== 三处目录必须一致 */

/**
 * 「网页写着装到 A、实际装到 B」是最难解释的一类故障。
 * agents 表出现在**三个地方**，这里把它们抓出来比对：
 *   src/data/site.js（页面渲染用）
 *   scripts/install-sh.tpl（bash 落盘用）
 *   scripts/install-ps1.tpl（PowerShell 落盘用）
 */
test('两个安装脚本的 agent 目录表与 src/data/site.js 三处一致', () => {
  const site = readFileSync(`${ROOT}src/data/site.js`, 'utf8')
  const sh = readFileSync(`${ROOT}scripts/install-sh.tpl`, 'utf8')
  const ps1 = readFileSync(`${ROOT}scripts/install-ps1.tpl`, 'utf8')

  /**
   * 统一成 `.claude/skills` 这种相对形态，好比对。
   *
   * ⚠️ 别写成 `/^~?\$?\{?HOME\}?\/?/` 这种「每个部分都可选」的式子 ——
   *    那样它在 `~/.claude/skills` 上**一个字符都匹配不到**（`HOME` 是必选字面量，
   *    而 `~` 后面跟的是 `/`），于是「归一化」等于没做，三边比对全部失配。
   *    老老实实把三种前缀分开写。
   */
  const norm = (dir) =>
    String(dir)
      .replace(/^(?:~|\$HOME|\$\{HOME\})\//, '')
      .replace(/^\.\//, '')

  const fromSite = new Map(
    [...site.matchAll(/\{\s*key:\s*'([a-z0-9]+)',\s*label:\s*'[^']*',\s*dir:\s*'([^']+)'/g)].map(
      (m) => [m[1], norm(m[2])],
    ),
  )
  const fromSh = new Map(
    [...sh.matchAll(/^\s*([a-z0-9]+)\)\s+echo "\$HOME\/([^"]+)"\s*;;/gm)].map((m) => [
      m[1],
      norm(m[2]),
    ]),
  )
  const fromPs1 = new Map(
    [...ps1.matchAll(/'([a-z0-9]+)'\s*=\s*'([^']+)'/g)]
      .filter((m) => m[2].includes('/skills'))
      .map((m) => [m[1], norm(m[2])]),
  )

  // 先确认真的抓到了东西 —— 正则写歪了会让下面三条断言「空对空」地全绿
  assert.ok(fromSite.size >= 8, `site.js 里应该抓到至少 8 个 agent，实际 ${fromSite.size}`)
  assert.ok(fromSh.size >= 8, `install-sh.tpl 里应该抓到至少 8 个 agent，实际 ${fromSh.size}`)
  assert.ok(fromPs1.size >= 8, `install-ps1.tpl 里应该抓到至少 8 个 agent，实际 ${fromPs1.size}`)

  assert.deepEqual(
    [...fromSh.entries()].sort(),
    [...fromSite.entries()].sort(),
    'install-sh.tpl 的目录表与 site.js 不一致',
  )
  assert.deepEqual(
    [...fromPs1.entries()].sort(),
    [...fromSite.entries()].sort(),
    'install-ps1.tpl 的目录表与 site.js 不一致',
  )
})

/* ============================================== 生成器自身的产物路径 */

// 防止「生成了却没人用」：真实构建产物的路径必须仍是 public/ 下这两个文件名。
// 前端 src/lib/install.js 里拼的就是这两个名字，改了这里要同步改那边。
test('默认输出路径仍是 public/install.sh 与 public/install.ps1', () => {
  const src = readFileSync(GEN, 'utf8')
  for (const p of ['public/install.sh', 'public/install.ps1']) {
    assert.ok(src.includes(`'${p}'`), `生成器里找不到默认输出 ${p}，CI 的产物校验会失配`)
  }
  // 没设 env 覆盖时必须落回 ROOT 下的 public/，而不是相对当前工作目录
  assert.ok(
    src.includes('path.join(ROOT, target.out)'),
    '默认输出应该用 path.join(ROOT, target.out) 拼绝对路径',
  )
})

test('前端拼出来的脚本地址与生成器的产物名对得上', () => {
  const lib = readFileSync(`${ROOT}src/lib/install.js`, 'utf8')
  assert.ok(lib.includes("'install.ps1'"), 'install.js 应该会拼出 install.ps1')
  assert.ok(lib.includes("'install.sh'"), 'install.js 应该会拼出 install.sh')
})
