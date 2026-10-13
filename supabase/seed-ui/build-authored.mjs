/**
 * 构建 27 个「自建」UI 技能包。
 * 自建的不需要署名转载来源，但仍补一份 ATTRIBUTION.md 说明「本站原创」——
 * 站上每个技能包都有这一份，缺了会让「这包哪来的」变成一个要翻 git 才能回答的问题。
 */
import { writeFileSync, readdirSync, mkdirSync } from 'node:fs'
import { join } from 'node:path'
import { strFromU8 } from 'fflate'
import { pack, readDir } from './pack.mjs'

const ROOT = new URL('./authored/', import.meta.url)
const OUT = new URL('./out/authored.json', import.meta.url)

/** slug → 维度（决定它在 UI 分类下属于哪一类） */
const DIM = {
  'desktop-layout-system': 'pc',
  'data-dense-ui': 'pc',
  'h5-viewport-adaptation': 'h5',
  'mobile-web-gestures': 'h5',
  'h5-performance': 'h5',
  'wechat-h5-guide': 'h5',
  'mobile-form-ux': 'h5',
  'h5-touch-accessibility': 'h5',
  'material-design-3': 'app',
  'mobile-app-navigation': 'app',
  'mobile-onboarding': 'app',
  'hero-section-design': 'landing',
  'pricing-page-design': 'landing',
  'social-proof-blocks': 'landing',
  'ecommerce-ui': 'biz',
  'fintech-ui': 'biz',
  'saas-app-ui': 'biz',
  'healthcare-ui': 'biz',
  'admin-dashboard-layout': 'admin',
  'crud-page-patterns': 'admin',
  'data-table-design': 'admin',
  'filter-and-search-ui': 'admin',
  'admin-empty-error-states': 'admin',
  'glassmorphism-ui': 'style',
  'neumorphism-ui': 'style',
  'bento-grid-ui': 'style',
  'dark-mode-oled': 'style',
}

const LICENSE = `MIT License

Copyright (c) 2026 Jerry (Skill Hub)

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
`

const ATTRIBUTION = `# 来源与署名

本技能是**本站原创**（Skill Hub 编写），不是转载。

| 项 | 内容 |
| --- | --- |
| 来源 | Skill Hub 原创 |
| 许可证 | MIT License |
| 版权 | Copyright (c) 2026 Jerry (Skill Hub) |

## 说明

内容依据公开的设计规范与工程实践整理（CSS 标准、WCAG 2.2、Material Design 3、
Apple HIG 公开条款等），不包含任何厂商的私有设计资产。

可自由使用、修改与再分发，保留本文件即可。
`

// 枚举 authored/ 下的目录
const dirs = readdirSync(ROOT).filter((n) => !n.startsWith('.'))

const out = []
const problems = []

for (const slug of dirs) {
  try {
    const files = readDir(join(ROOT.pathname, slug))
    if (!files['SKILL.md']) throw new Error('缺 SKILL.md')
    files['LICENSE'] = new TextEncoder().encode(LICENSE)
    files['ATTRIBUTION.md'] = new TextEncoder().encode(ATTRIBUTION)

    const md = strFromU8(files['SKILL.md'])
    const fm = /^---\n([\s\S]*?)\n---\n/.exec(md)[1]
    const g = (k) => (new RegExp(`^${k}:\\s*"([^"]+)"`, 'm').exec(fm) || [null, ''])[1]
    const tagBody = (/^tags:\s*\[(.*?)\]/m.exec(fm) || [null, ''])[1]
    const tags = (tagBody.match(/"([^"]+)"/g) || []).map((s) => s.replace(/"/g, ''))

    const { bundle, hash, list, totalBytes } = pack(files)
    if (totalBytes > 2 * 1024 * 1024) throw new Error('超过 2MB')

    out.push({
      slug,
      name: slug,
      description: g('description'),
      category: 'ui',
      tags,
      version: g('version'),
      license: 'MIT',
      author: 'Skill Hub',
      readme: md,
      files: list,
      file_count: list.length,
      total_bytes: totalBytes,
      hash,
      bundle_b64: Buffer.from(bundle).toString('base64'),
      dim: DIM[slug] || 'other',
      origin: '本站原创',
    })
    console.log(`ok  ${slug.padEnd(26)} ${String(list.length).padStart(2)} 文件 ${(totalBytes / 1024).toFixed(1).padStart(6)}KB  ${DIM[slug] || '?'}`)
  } catch (e) {
    problems.push(`${slug}: ${e.message}`)
    console.log(`ERR ${slug}: ${e.message}`)
  }
}

mkdirSync(new URL('./out/', import.meta.url), { recursive: true })
writeFileSync(OUT, JSON.stringify(out, null, 1))
console.log(`\n成功 ${out.length} / ${dirs.length}`)
if (problems.length) console.log(problems.map((p) => '  - ' + p).join('\n'))
