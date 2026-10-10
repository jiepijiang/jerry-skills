/**
 * 解析层单元测试
 * ---------------------------------------------------------------------------
 * 跑法：npm test（= node --test scripts/tests/）
 *
 * 覆盖的都是「肉眼很难发现、但上线后一定会被用户撞到」的点：
 *   · frontmatter 的各种写法（行内数组 / 块数组 / 折叠块 / 引号）
 *   · zip 里的垃圾条目与路径穿越（zip slip）
 *   · 顶层目录剥离的边界（只有一个顶层目录时**不该**剥）
 *   · 内容哈希的稳定性（同样内容、不同条目顺序 → 同一个 hash）
 *
 * ⚠️ 按项目纪律：**没红过的绿灯没有意义**。
 *    写完这些断言后，要故意改坏源码确认它们真会红（见 README「验证」一节）。
 */
import { test } from 'node:test'
import assert from 'node:assert/strict'
import { zipSync, strToU8 } from 'fflate'

import { parseFrontmatter, parseYamlSubset } from '../../src/lib/frontmatter.js'
import {
  analyze,
  buildTree,
  extractMeta,
  formatBytes,
  isBinary,
  normalizePath,
  parseSkill,
  pickRoot,
  readZip,
  sha256Hex,
  slugify,
  SKILL_FILE,
} from '../../src/lib/parseSkill.js'

/** 与 src/data/site.js 的 limits 对齐（这里独立写一份，防止两边被一起改错） */
const LIMITS = {
  maxFiles: 200,
  maxTotalBytes: 2 * 1024 * 1024,
  maxSkillMdBytes: 256 * 1024,
  maxNameLength: 64,
  maxDescLength: 500,
}

const MD = `---
name: pdf-editor
description: 处理 PDF 文档。
version: 1.2.0
license: MIT
author: jerry
category: document
tags: [pdf, 文档处理]
---

# PDF Editor

正文。
`

/* ------------------------------------------------------------ frontmatter */

test('frontmatter：基本键值对', () => {
  const { data, body } = parseFrontmatter(MD)
  assert.equal(data.name, 'pdf-editor')
  assert.equal(data.version, '1.2.0')
  assert.equal(data.license, 'MIT')
  assert.ok(body.startsWith('\n# PDF Editor'), '正文应从 frontmatter 之后开始')
})

test('frontmatter：行内数组', () => {
  const { data } = parseFrontmatter(MD)
  assert.deepEqual(data.tags, ['pdf', '文档处理'])
})

test('frontmatter：块数组', () => {
  const data = parseYamlSubset('tags:\n  - a\n  - b\nname: x\n')
  assert.deepEqual(data.tags, ['a', 'b'])
  assert.equal(data.name, 'x')
})

test('frontmatter：折叠块（多行描述合成一段）', () => {
  const data = parseYamlSubset('description:\n  第一行\n  第二行\nversion: 1\n')
  assert.equal(data.description, '第一行 第二行')
  assert.equal(data.version, '1')
})

test('frontmatter：引号与转义', () => {
  const data = parseYamlSubset('a: "带\\"引号\\"的值"\nb: \'原样 \\n 不转义\'\n')
  assert.equal(data.a, '带"引号"的值')
  assert.equal(data.b, '原样 \\n 不转义')
})

test('frontmatter：没有 frontmatter 时不应误判正文里的分隔线', () => {
  const src = '# 标题\n\n---\n\n正文\n'
  const { data, body } = parseFrontmatter(src)
  assert.deepEqual(data, {})
  assert.equal(body, src)
})

/* ------------------------------------------------------------ 路径处理 */

test('normalizePath：去掉 ./ 与重复斜杠', () => {
  assert.equal(normalizePath('./a//b'), 'a/b')
  assert.equal(normalizePath('a\\b'), 'a/b')
})

test('normalizePath：拒绝路径穿越与绝对路径', () => {
  assert.equal(normalizePath('a/../b'), null)
  assert.equal(normalizePath('../x'), null)
  assert.equal(normalizePath('/etc/passwd'), null)
  assert.equal(normalizePath('C:/x'), null)
  assert.equal(normalizePath(''), null)
})

test('pickRoot：所有条目同在一个顶层目录下才剥', () => {
  assert.equal(pickRoot(['my-skill/SKILL.md', 'my-skill/a.py']), 'my-skill')
  assert.equal(pickRoot(['SKILL.md', 'scripts/a.py']), '')
  assert.equal(pickRoot(['a/x', 'b/y']), '')
  // 只有一个顶层条目时**不该**剥 —— 那可能就是技能本身的目录名
  assert.equal(pickRoot(['scripts/a.py']), '')
})

test('slugify：只保留字母数字与中文', () => {
  assert.equal(slugify('PDF Editor!'), 'pdf-editor')
  assert.equal(slugify('  My  Skill  '), 'my-skill')
  assert.equal(slugify('中文技能'), '中文技能')
  assert.equal(slugify('!!!'), 'skill')
})

test('formatBytes：三个量级', () => {
  assert.equal(formatBytes(512), '512 B')
  assert.equal(formatBytes(2048), '2.0 KB')
  assert.equal(formatBytes(2 * 1024 * 1024), '2.00 MB')
})

test('isBinary：含 NUL 字节判为二进制', () => {
  assert.equal(isBinary(strToU8('hello')), false)
  assert.equal(isBinary(new Uint8Array([104, 0, 105])), true)
})

/* ------------------------------------------------------------------ zip */

test('readZip：丢弃 __MACOSX / .DS_Store，并剥掉顶层目录', () => {
  const zip = zipSync({
    '__MACOSX/._x': strToU8('junk'),
    'my-skill/.DS_Store': strToU8('junk'),
    'my-skill/SKILL.md': strToU8(MD),
    'my-skill/scripts/a.py': strToU8('print(1)'),
  })
  const { files, warnings } = readZip(zip)
  assert.deepEqual(
    files.map((f) => f.path),
    ['SKILL.md', 'scripts/a.py'],
  )
  assert.ok(warnings.some((w) => w.includes('my-skill')), '剥目录应当留下说明')
})

test('readZip：路径穿越条目被丢弃并给出警告', () => {
  const zip = zipSync({ '../evil.sh': strToU8('rm -rf /'), 'SKILL.md': strToU8(MD) })
  const { files, warnings } = readZip(zip)
  assert.deepEqual(
    files.map((f) => f.path),
    ['SKILL.md'],
  )
  assert.ok(warnings.some((w) => w.includes('不安全路径')))
})

test('readZip：非法 zip 不抛异常，返回可读的错误', () => {
  const { files, warnings } = readZip(strToU8('这不是一个 zip'))
  assert.equal(files.length, 0)
  assert.ok(warnings[0].includes('不是有效的 zip'))
})

test('extractMeta：从 SKILL.md 里取出元信息', () => {
  const { files } = readZip(zipSync({ 'SKILL.md': strToU8(MD) }))
  const { readme, meta } = extractMeta(files)
  assert.equal(meta.name, 'pdf-editor')
  assert.deepEqual(meta.tags, ['pdf', '文档处理'])
  assert.ok(readme.includes('# PDF Editor'))
})

/* ------------------------------------------------------------ parseSkill */

test('parseSkill：完整走通一个技能包', async () => {
  const zip = zipSync({
    'my-skill/SKILL.md': strToU8(MD),
    'my-skill/scripts/a.py': strToU8('print(1)'),
  })
  const r = await parseSkill({ name: 'my-skill.zip', bytes: zip }, LIMITS)

  assert.equal(r.ok, true, `不该有错误：${r.errors.join('；')}`)
  assert.equal(r.skill.slug, 'pdf-editor')
  assert.equal(r.skill.name, 'pdf-editor')
  assert.equal(r.skill.category, 'document')
  assert.equal(r.skill.fileCount, 2)
  assert.equal(r.skill.files[0].path, SKILL_FILE, '文件表应按路径排序')
  assert.equal(r.skill.bundle[0], 0x50, 'bundle 应当是 zip（以 P 开头）')
  assert.equal(r.skill.hash.length, 64)
})

test('parseSkill：哈希稳定 —— 条目顺序不同、内容相同 → 同一个 hash', async () => {
  const a = zipSync({ 'SKILL.md': strToU8(MD), 'a.py': strToU8('x') })
  const b = zipSync({ 'a.py': strToU8('x'), 'SKILL.md': strToU8(MD) })
  const ra = await parseSkill({ name: 'a.zip', bytes: a }, LIMITS)
  const rb = await parseSkill({ name: 'b.zip', bytes: b }, LIMITS)
  assert.equal(ra.skill.hash, rb.skill.hash)
})

test('parseSkill：内容不同 → hash 不同（否则去重会把两个技能合成一个）', async () => {
  const a = zipSync({ 'SKILL.md': strToU8(MD) })
  const b = zipSync({ 'SKILL.md': strToU8(MD.replace('1.2.0', '1.2.1')) })
  const ra = await parseSkill({ name: 'a.zip', bytes: a }, LIMITS)
  const rb = await parseSkill({ name: 'b.zip', bytes: b }, LIMITS)
  assert.notEqual(ra.skill.hash, rb.skill.hash)
})

test('parseSkill：缺 SKILL.md → 不通过，且错误里说清原因', async () => {
  const zip = zipSync({ 'scripts/a.py': strToU8('print(1)') })
  const r = await parseSkill({ name: 'x.zip', bytes: zip }, LIMITS)
  assert.equal(r.ok, false)
  assert.ok(r.errors.some((e) => e.includes('SKILL.md')))
})

test('parseSkill：单文件 Markdown 也能当技能', async () => {
  const r = await parseSkill({ name: 'SKILL.md', bytes: strToU8(MD) }, LIMITS)
  assert.equal(r.ok, true)
  assert.equal(r.skill.files.length, 1)
  assert.equal(r.skill.files[0].path, SKILL_FILE)
})

test('parseSkill：空文件被挡下', async () => {
  const r = await parseSkill({ name: 'empty.zip', bytes: new Uint8Array(0) }, LIMITS)
  assert.equal(r.ok, false)
})

test('analyze：文件数超限', () => {
  const files = Array.from({ length: LIMITS.maxFiles + 1 }, (_, i) => ({
    path: `f${i}.txt`,
    size: 1,
    kind: 'text',
  }))
  const r = analyze(files, LIMITS)
  assert.equal(r.ok, false)
  assert.ok(r.errors.some((e) => e.includes('文件数')))
})

test('analyze：解压后总体积超限', () => {
  const files = [
    { path: SKILL_FILE, size: 10, kind: 'text' },
    { path: 'big.bin', size: LIMITS.maxTotalBytes + 1, kind: 'binary' },
  ]
  const r = analyze(files, LIMITS)
  assert.equal(r.ok, false)
  assert.ok(r.errors.some((e) => e.includes('总大小')))
})

test('sha256Hex：已知向量的前若干位对得上', async () => {
  // echo -n "abc" | sha256sum
  const hex = await sha256Hex(strToU8('abc'))
  assert.equal(hex, 'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad')
})

/* --------------------------------------------------------------- 文件树 */

test('buildTree：目录大小 = 子项之和，且目录在前', () => {
  const tree = buildTree([
    { path: 'SKILL.md', size: 100, kind: 'text' },
    { path: 'scripts/a.py', size: 30, kind: 'text' },
    { path: 'scripts/b.py', size: 20, kind: 'text' },
  ])
  assert.equal(tree.size, 150)
  const scripts = tree.children.find((c) => c.name === 'scripts')
  assert.equal(scripts.type, 'dir')
  assert.equal(scripts.size, 50)
  assert.equal(scripts.children.length, 2)
})
