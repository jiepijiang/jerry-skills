/**
 * 构建 15 个「真实转载」的 UI 技能包。
 * 输出 out/real.json —— 每个技能含元信息 + readme + files + hash + bundle_b64。
 */
import { readFileSync, writeFileSync, existsSync, mkdirSync } from 'node:fs'
import { join } from 'node:path'
import { strFromU8 } from 'fflate'
import { pack, readDir, replaceFrontmatter, buildFrontmatter, buildAttribution } from './pack.mjs'

const META = JSON.parse(readFileSync(new URL('./meta-real.json', import.meta.url), 'utf8'))

const out = []
const problems = []

for (const m of META) {
  try {
    const files = readDir(m.src)

    // 1. 重写 SKILL.md 的 frontmatter
    const skillKey = Object.keys(files).find((p) => p.toLowerCase() === 'skill.md')
    if (!skillKey) throw new Error('源目录里没有 SKILL.md')
    const md = strFromU8(files[skillKey])
    const fm = buildFrontmatter({
      slug: m.slug,
      description: m.description,
      version: m.version,
      license: m.license,
      author: m.author,
      tags: m.tags,
    })
    const newMd = replaceFrontmatter(md, fm)
    files['SKILL.md'] = new TextEncoder().encode(newMd)

    // 2. LICENSE —— 源目录自带的优先，否则取仓库根的那份
    const ownLicense = Object.keys(files).find((p) => /^LICENSE(\.txt)?$/i.test(p))
    if (ownLicense && ownLicense !== 'LICENSE') {
      files['LICENSE'] = files[ownLicense]
      delete files[ownLicense]
    } else if (!ownLicense) {
      if (!existsSync(m.licenseFile)) throw new Error(`找不到许可证文件 ${m.licenseFile}`)
      files['LICENSE'] = new Uint8Array(readFileSync(m.licenseFile))
    }

    // 3. ATTRIBUTION.md
    files['ATTRIBUTION.md'] = new TextEncoder().encode(buildAttribution(m))

    // 4. 打包
    const { bundle, hash, list, totalBytes } = pack(files)
    if (totalBytes > 2 * 1024 * 1024) throw new Error(`解压后 ${totalBytes} 字节，超过 2MB 上限`)

    out.push({
      slug: m.slug,
      name: m.slug,
      description: m.description,
      category: 'ui',
      tags: m.tags,
      version: m.version,
      license: m.license,
      author: m.author,
      readme: newMd,
      files: list,
      file_count: list.length,
      total_bytes: totalBytes,
      hash,
      bundle_b64: Buffer.from(bundle).toString('base64'),
      dim: m.dim,
      origin: `${m.srcRepo} · ${m.srcPath}`,
    })
    console.log(`ok  ${m.slug.padEnd(26)} ${list.length} 文件 ${(totalBytes / 1024).toFixed(1)}KB  hash=${hash.slice(0, 12)}`)
  } catch (e) {
    problems.push(`${m.slug}: ${e.message}`)
    console.log(`ERR ${m.slug}: ${e.message}`)
  }
}

mkdirSync(new URL('./out/', import.meta.url), { recursive: true })
writeFileSync(new URL('./out/real.json', import.meta.url), JSON.stringify(out, null, 1))
console.log(`\n成功 ${out.length} / ${META.length}`)
if (problems.length) console.log('问题:\n' + problems.map((p) => '  - ' + p).join('\n'))
