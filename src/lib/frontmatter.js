/**
 * SKILL.md 的 YAML frontmatter 解析（最小子集）
 * ---------------------------------------------------------------------------
 * 为什么不引 js-yaml：我们只需要 frontmatter 这一小块，而它是**不可信的输入**
 * （任何人都能上传）。js-yaml 完整实现要处理锚点 / 标签 / 类型推断，
 * 攻击面比需求大得多；这里只认下面这几种子集，认不出来的一律当普通字符串。
 *
 * 支持：
 *   key: value
 *   key: "带转义的值"   /   key: '原样值'
 *   key: [a, b, c]              ← 行内数组
 *   key:                        ← 折叠块（缩进多行合成一段）
 *     line1
 *     line2
 *   key:                        ← 块数组
 *     - a
 *     - b
 *   # 注释行
 *
 * 不支持（按普通字符串处理，不报错）：嵌套对象、锚点 &x / *x、多文档 ---。
 */

/** 去掉成对引号并还原转义（只处理双引号里的转义） */
function unquote(raw) {
  const s = String(raw ?? '').trim()
  if (s.length >= 2 && s[0] === '"' && s[s.length - 1] === '"') {
    return s
      .slice(1, -1)
      .replace(/\\(.)/g, (_, c) => ({ n: '\n', t: '\t', r: '\r', '"': '"', '\\': '\\' }[c] ?? c))
  }
  if (s.length >= 2 && s[0] === "'" && s[s.length - 1] === "'") {
    return s.slice(1, -1).replace(/''/g, "'")
  }
  return s
}

/** 折叠块：连续非空行合成一段（空格连接），空行分段 */
function foldBlock(lines) {
  const paras = []
  let cur = []
  for (const l of lines) {
    const t = l.trim()
    if (t === '') {
      if (cur.length) {
        paras.push(cur.join(' '))
        cur = []
      }
    } else {
      cur.push(t)
    }
  }
  if (cur.length) paras.push(cur.join(' '))
  return paras.join('\n\n')
}

const indentOf = (s) => s.length - s.trimStart().length

/**
 * 解析 YAML 子集 → 普通对象。
 * 容错优先：不认识的行直接跳过，绝不抛异常 —— 上传的 SKILL.md 五花八门，
 * 为一行怪东西让整个上传失败是不划算的。
 */
export function parseYamlSubset(raw) {
  const out = {}
  const lines = String(raw ?? '').split(/\r?\n/)
  let i = 0

  while (i < lines.length) {
    const line = lines[i]
    const stripped = line.trim()
    if (!stripped || stripped.startsWith('#')) {
      i++
      continue
    }

    const m = /^([A-Za-z0-9_.\-]+)\s*:\s*(.*)$/.exec(line)
    if (!m) {
      i++
      continue
    }

    const key = m[1]
    const rest = m[2].trim()
    i++

    // 收集紧随其后的缩进块（空行也算，用于分段）
    const block = []
    while (i < lines.length) {
      const l = lines[i]
      if (l.trim() === '') {
        block.push(l)
        i++
        continue
      }
      if (indentOf(l) > 0) {
        block.push(l)
        i++
        continue
      }
      break
    }
    while (block.length && block[block.length - 1].trim() === '') block.pop()

    if (rest === '' && block.length) {
      const isList = block.every((l) => l.trim() === '' || /^\s*-\s*/.test(l))
      if (isList) {
        out[key] = block
          .filter((l) => l.trim() !== '')
          .map((l) => unquote(l.replace(/^\s*-\s*/, '').trim()))
      } else {
        out[key] = foldBlock(block)
      }
    } else if (rest === '>' || rest === '|' || rest === '>-' || rest === '|-') {
      out[key] = foldBlock(block)
    } else if (rest.startsWith('[') && rest.endsWith(']')) {
      out[key] = rest
        .slice(1, -1)
        .split(',')
        .map((s) => unquote(s))
        .filter(Boolean)
    } else {
      out[key] = unquote(rest)
    }
  }

  return out
}

/**
 * 从 Markdown 文本里切出 frontmatter。
 *
 * 判据：**必须**同时有开头的 `---` 和后面独立一行的 `---` 才算。
 * 只认开头（允许前面有空白行）—— 正文里的一条分隔线不该被当成 frontmatter 起点。
 */
export function parseFrontmatter(text) {
  const src = String(text ?? '').replace(/^\uFEFF/, '')
  const m = /^[ \t]*---[ \t]*\r?\n([\s\S]*?)\r?\n---[ \t]*(?:\r?\n|$)/.exec(src)
  if (!m) return { data: {}, body: src, raw: '' }
  return { data: parseYamlSubset(m[1]), body: src.slice(m[0].length), raw: m[1] }
}
