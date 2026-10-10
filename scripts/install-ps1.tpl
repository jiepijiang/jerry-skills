#Requires -Version 5.1
<#
============================================================================
 jerry-skills 安装器（Windows / PowerShell）
----------------------------------------------------------------------------
 用法：
   [Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12; & ([scriptblock]::Create((New-Object Net.WebClient).DownloadString('<站点>/install.ps1'))) -Slug <slug> [-Agent <名称>]

   -Slug  <slug>     技能的唯一标识（在技能详情页能看到）
   -Agent <名称>     安装目标，默认 workbuddy
   -Help             打印这段用法

 这个文件是**模板**：scripts/gen-installers.mjs 会把 __SUPABASE_*__ 替换成真实
 端点后写进 public/install.ps1。别直接改 public/install.ps1 —— 它每次构建都会被
 覆盖。

 ⚠️ 这里出现的目录必须和 src/data/site.js 的 agents、scripts/install-sh.tpl 的
    dir_for_agent **三处**一致。不一致会出现「网页写着装到 A、实际装到 B」。

 ⚠️ 整篇一律写 ${VAR} 这种带花括号的形式，不写裸变量。PowerShell 和 bash 有同一个坑：
    变量名会把紧跟其后的**中文字符也吃进去**，结果是空串，而且**不报错**。
    （已实测：赋值 'X' 之后，写 美元符+a+中文 得到的是空串，写 ${a}+中文 才对。）
    同一个道理，`美元符+变量+.bak` 会被当成「取名为 bak 的属性」也是空串。
    所以只要变量后面不是 ASCII 分隔符，就一律加花括号。
============================================================================
#>
[CmdletBinding()]
param(
  [Parameter(Position = 0)]
  [string]$Slug,

  [string]$Agent = 'workbuddy',

  [switch]$Help
)

$ErrorActionPreference = 'Stop'

$Endpoint = '__SUPABASE_URL__'
$AnonKey = '__SUPABASE_ANON_KEY__'
$Site = '__SITE_URL__'

# agent → skills 目录（相对用户主目录）。
# ⚠️ 这份表和 install.sh 的 dir_for_agent()、src/data/site.js 的 agents 必须一致。
$AgentDirs = [ordered]@{
  'workbuddy' = '.workbuddy-ai/skills'
  'claude'    = '.claude/skills'
  'cursor'    = '.cursor/skills'
  'codex'     = '.codex/skills'
  'gemini'    = '.gemini/skills'
  'copilot'   = '.copilot/skills'
  'windsurf'  = '.windsurf/skills'
  'cline'     = '.cline/skills'
}

function Show-Usage {
  Write-Host @'
jerry-skills 安装器（Windows / PowerShell）

用法:
  & ([scriptblock]::Create((New-Object Net.WebClient).DownloadString('<站点>/install.ps1'))) -Slug <slug> [-Agent <名称>]

参数:
  -Slug  <slug>     技能的唯一标识（在技能详情页能看到）
  -Agent <名称>     安装目标，默认 workbuddy

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
  ... -Slug pdf-editor -Agent claude
'@
}

function Stop-Install {
  param([string]$Message, [string]$Hint)

  Write-Host "❌ ${Message}" -ForegroundColor Red
  if ($Hint) {
    Write-Host "   ${Hint}" -ForegroundColor DarkGray
  }

  # 为什么是「打个友好的消息 + throw 一个空异常」，而不是 exit、也不是 throw 消息：
  #
  #   1. 这个脚本是被 `[scriptblock]::Create(...)` 之后用 `&` 调起来的。
  #      在**交互式** PowerShell 里 `exit` 会把用户整个终端窗口关掉（已实测：
  #      exit 之后同一条命令串里后面的语句根本不执行）。绝对不能这么干。
  #   2. 但退出码还是得有 —— 详情页给的「AI Agent 提示词」就是让 agent 照着跑这条
  #      命令，agent 靠退出码判断成败。`throw` 只终止这一条管道、回到提示符，
  #      同时让 `pwsh -Command` 的退出码变成 1。
  #   3. 消息上面已经用 Write-Host 打过了，所以抛一个**空消息**的异常，
  #      免得同一句话被打印两遍（PowerShell 还会附上出错位置那一堆波浪线）。
  throw ''
}

if ($Help) {
  Show-Usage
  return
}

if (-not $Slug) {
  Show-Usage
  Stop-Install '缺少技能标识（slug）。'
}

# slug 会被拼进 JSON 请求体。引号其实由 ConvertTo-Json 负责转义、不会出事，
# 但还是和 install.sh 用**同一套**校验 —— 两个平台的输入规则不一样的话，
# 会出现「macOS 报错、Windows 装上了」这种没人能解释的差异。
if ($Slug -match '[\x00-\x1f"\\]') {
  Stop-Install "非法的技能标识：${Slug}"
}

$Rel = $AgentDirs[$Agent]
if (-not $Rel) {
  Stop-Install "不认识的 -Agent：${Agent}（用 -Help 看可选值）"
}

# ⚠️ 这里只能判空，**不能**拿「URL 的占位符」当「未注入」的哨兵。
#    生成器是 replaceAll(占位符, 真实端点)，守卫里那个哨兵会被一起替换掉 ——
#    结果就是「注入成功反而触发守卫」，线上所有人都会安装失败。
#    （install.sh 上真踩过这个坑，见 scripts/tests/installers.test.mjs。）
if ([string]::IsNullOrEmpty($Endpoint) -or [string]::IsNullOrEmpty($AnonKey)) {
  Write-Host '这个 install.ps1 没有注入后端地址（构建时未配置 Supabase）。' -ForegroundColor Red
  Write-Host '请到技能详情页用「下载 .zip」手动安装。' -ForegroundColor Red
  throw ''
}

if ([string]::IsNullOrEmpty($HOME)) {
  Stop-Install '取不到用户主目录（HOME 是空的），不知道该把技能装到哪里。'
}

# 逐段 Join-Path，别直接把 '.claude/skills' 拼上去 —— 那样在 Windows 上会得到
# `C:\Users\x\.claude/skills` 这种混用分隔符的路径（能用，但看着像 bug）。
$TargetRoot = $HOME
foreach ($seg in ($Rel -split '/')) {
  $TargetRoot = Join-Path $TargetRoot $seg
}

$Tmp = Join-Path ([IO.Path]::GetTempPath()) ('jerry-skills-' + [Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $Tmp -Force | Out-Null

# 关掉进度条。
#   ① 非交互式宿主会把进度条**渲染成文字**塞进输出流。Expand-Archive 尤其吵，实测
#      打出 `Expand-Archive [The archive file '/tmp/…']Expand-Archive […` 一堆半截
#      句子，把真正的结果淹掉。它也是 Invoke-* 慢的常见原因。
#   ② 必须写 `$global:`。Expand-Archive 来自 Microsoft.PowerShell.Archive **模块**，
#      模块函数看不到调用方的局部作用域，只认全局那个偏好变量 ——
#      实测：脚本内普通赋值**完全不管用**（噪音照旧），$global: 才管用。
#   ③ 正因为是全局的，用完必须还原，否则会把用户当前会话的设置改掉。
$PrevProgressPreference = $global:ProgressPreference

try {
  $global:ProgressPreference = 'SilentlyContinue'

  Write-Host "→ 正在获取 ${Slug} …"

  $Body = @{ p_slug = $Slug } | ConvertTo-Json -Compress
  $Headers = @{
    'apikey'        = $AnonKey
    'Authorization' = "Bearer ${AnonKey}"
    'Content-Type'  = 'application/json'
  }

  try {
    # -Body 传 UTF-8 字节，不传字符串：Windows PowerShell 5.1 会把字符串请求体按
    # ASCII/Latin-1 编码，中文 slug 会被写坏，服务端看到的是乱码 → 报 not_found。
    $Resp = Invoke-RestMethod -Uri "${Endpoint}/rest/v1/rpc/download_skill" -Method Post `
      -Headers $Headers -Body ([Text.Encoding]::UTF8.GetBytes($Body)) -TimeoutSec 60
  } catch {
    Stop-Install "网络请求失败：$($_.Exception.Message)"
  }

  if (-not $Resp.ok) {
    $Code = if ($Resp.code) { $Resp.code } else { 'unknown' }
    $Msg = switch ($Code) {
      'not_found' { '没有找到这个技能（slug 写错了？）' }
      'invalid_payload' { '请求参数不对' }
      default { "下载失败（${Code}）" }
    }
    # 中文技能名在 Windows 上还有**第二个**失败原因：终端的代码页把命令行参数
    # 传坏了。这个提示能省掉一轮「我明明复制对了」的排查。
    $Hint = if ($Code -eq 'not_found') {
      '如果技能名是中文，也可能是终端的编码把参数传坏了 —— 可以改用「下载 .zip」或 AI Agent 安装。'
    } else { '' }
    Stop-Install $Msg -Hint $Hint
  }

  try {
    $Raw = [Convert]::FromBase64String($Resp.bundle_b64)
  } catch {
    Stop-Install "技能包解码失败：$($_.Exception.Message)"
  }

  # 真·zip 检查：前两字节必须是 PK（否则就是在往磁盘上写垃圾）
  if ($Raw.Length -lt 2 -or $Raw[0] -ne 0x50 -or $Raw[1] -ne 0x4B) {
    Stop-Install '下载到的内容不是 zip，已中止。'
  }

  $Zip = Join-Path $Tmp 'skill.zip'
  [IO.File]::WriteAllBytes($Zip, $Raw)

  $Target = Join-Path $TargetRoot $Slug

  # 已存在先备份，不直接删 —— 用户可能改过里面的东西
  if (Test-Path -LiteralPath $Target) {
    $Backup = "${Target}.bak." + (Get-Date -Format 'yyyyMMddHHmmss')
    Move-Item -LiteralPath $Target -Destination $Backup
    Write-Host "→ 已备份原目录到 ${Backup}"
  }

  New-Item -ItemType Directory -Path $Target -Force | Out-Null

  try {
    Expand-Archive -LiteralPath $Zip -DestinationPath $Target -Force
  } catch {
    Stop-Install "解压失败：$($_.Exception.Message)"
  }

  if (-not (Test-Path -LiteralPath (Join-Path $Target 'SKILL.md'))) {
    Write-Host '⚠️  装完了，但目录里没有 SKILL.md —— 这个技能包可能不完整。' -ForegroundColor Yellow
  }

  $Count = (Get-ChildItem -LiteralPath $Target -Recurse -File).Count
  Write-Host "✅ 已安装到 ${Target}" -ForegroundColor Green
  Write-Host "   文件：${Count} 个"
  Write-Host "   技能主页：${Site}/skills/${Slug}"
} finally {
  $global:ProgressPreference = $PrevProgressPreference
  # 临时目录一定要清掉：里面是完整的技能包，留着既占地方又容易让人误以为是正式安装
  Remove-Item -LiteralPath $Tmp -Recurse -Force -ErrorAction SilentlyContinue
}
