/**
 * 本地演示模式的种子技能
 * ---------------------------------------------------------------------------
 * 未配置 Supabase 时（或断网），站点仍然要能完整浏览 —— 否则一打开就是空白页，
 * 连「这个站长什么样」都看不出来。
 *
 * 这里刻意**不写死解析结果**，而是存「原始文件」，运行时走真实的 parseSkill()：
 * 这样演示模式同时也验证了解析链路，而不是绕过它。
 */

export const SEED_SKILLS = [
  {
    name: 'pdf-editor.zip',
    files: {
      'SKILL.md': `---
name: pdf-editor
description: 处理 PDF 文档：旋转、合并、拆分、提取文本、压缩与表单填充。当用户需要对 PDF 做这些操作时使用。
version: 1.2.0
license: MIT
author: jerry
category: document
tags: [pdf, 文档处理, python]
---

# PDF Editor

## 何时使用

当用户提出以下需求时使用本技能：

- 旋转 / 合并 / 拆分 PDF 页面
- 从扫描件里提取文本（OCR）
- 压缩体积以便邮件发送
- 在表单模板上填充字段

## 快速开始

1. 先确认操作类型，选对应的脚本
2. 检查输入文件是否存在、能否读取
3. 执行脚本，输出到用户指定路径

## 脚本

| 脚本 | 用途 |
| --- | --- |
| \`scripts/rotate_pdf.py\` | 按角度旋转 |
| \`scripts/merge_pdfs.py\` | 合并多个文件 |

## 注意

- 处理前先备份原文件
- 扫描件走 OCR 分支，不要直接 extract_text
`,
      'scripts/rotate_pdf.py': `import sys
import PyPDF2


def rotate_pdf(src, dst, angle):
    """按角度旋转 PDF 的每一页（angle 取 90 / 180 / 270）。"""
    with open(src, 'rb') as fh:
        reader = PyPDF2.PdfReader(fh)
        writer = PyPDF2.PdfWriter()
        for page in reader.pages:
            page.rotate(angle)
            writer.add_page(page)
        with open(dst, 'wb') as out:
            writer.write(out)


if __name__ == '__main__':
    if len(sys.argv) != 4:
        print('用法: rotate_pdf.py <输入.pdf> <输出.pdf> <角度>')
        sys.exit(1)
    rotate_pdf(sys.argv[1], sys.argv[2], int(sys.argv[3]))
`,
      'scripts/merge_pdfs.py': `import sys
import PyPDF2


def merge(paths, dst):
    writer = PyPDF2.PdfWriter()
    for p in paths:
        with open(p, 'rb') as fh:
            writer.append(fh)
    with open(dst, 'wb') as out:
        writer.write(out)


if __name__ == '__main__':
    merge(sys.argv[2:], sys.argv[1])
`,
      'references/pdf-standards.md': `# PDF 处理约定

- 默认输出到源文件同目录，文件名加 \`-out\` 后缀
- 不覆盖原文件
- 单次操作页数上限 2000 页
`,
    },
  },
  {
    name: 'skill-creator.zip',
    files: {
      'SKILL.md': `---
name: skill-creator
description: 创建或更新 AI Agent 技能时使用，提供 SKILL.md 规范、目录结构模板与打包校验脚本。
version: 2.0.1
license: MIT
author: jerry
category: development
tags: [skill, 脚手架, 规范]
---

# Skill Creator

## 何时使用

- 用户想新建一个技能
- 用户想改造已有技能的结构
- 需要把散落的脚本整理成标准技能包

## 目录结构

\`\`\`
my-skill/
├── SKILL.md
├── scripts/
├── references/
└── assets/
\`\`\`

## 渐进式披露

SKILL.md 只写「什么时候用、怎么开始」；细节沉到 references/ 里，
需要时再读 —— 避免一次性把上下文塞满。

## 打包

\`\`\`bash
python scripts/package_skill.py ./my-skill
\`\`\`

会校验 frontmatter 完整性、脚本可执行位、引用文件是否存在。
`,
      'scripts/init_skill.py': `import os
import sys

TEMPLATE = """---
name: {name}
description: 在这里写「什么时候用这个技能」。
version: 0.1.0
---

# {title}

## 何时使用

## 怎么用
"""


def init(name):
    os.makedirs(os.path.join(name, 'scripts'), exist_ok=True)
    os.makedirs(os.path.join(name, 'references'), exist_ok=True)
    with open(os.path.join(name, 'SKILL.md'), 'w', encoding='utf-8') as fh:
        fh.write(TEMPLATE.format(name=name, title=name.replace('-', ' ').title()))
    print(f'已创建 {name}/')


if __name__ == '__main__':
    init(sys.argv[1] if len(sys.argv) > 1 else 'my-skill')
`,
      'scripts/package_skill.py': `import sys
import zipfile
from pathlib import Path


def pack(root):
    root = Path(root)
    out = root.with_suffix('.zip')
    with zipfile.ZipFile(out, 'w', zipfile.ZIP_DEFLATED) as zf:
        for p in sorted(root.rglob('*')):
            if p.is_file():
                zf.write(p, p.relative_to(root.parent))
    print(f'已打包 {out}')


if __name__ == '__main__':
    pack(sys.argv[1])
`,
      'references/conventions.md': `# 技能写作约定

- description 用祈使句，写「什么时候用」，不要写「这个技能是什么」
- 不要在 SKILL.md 里贴大段代码，沉到 scripts/
- 单文件超过 500 行就该拆分
`,
    },
  },
  {
    name: 'frontend-design.zip',
    files: {
      'SKILL.md': `---
name: frontend-design
description: 生成有设计感的前端界面时使用，给出配色、排版、间距、动效与响应式的具体取舍。
version: 1.0.3
license: MIT
author: jerry
category: design
tags: [设计, css, ui, 排版]
---

# Frontend Design

## 何时使用

用户让你「做个好看的页面」「优化一下 UI」「这个界面太丑了」的时候。

## 四条硬规则

1. **先定层级，再定颜色** —— 字号/字重拉开三级，颜色只做辅助
2. **间距用一套刻度**（4 / 8 / 12 / 16 / 24 / 32），不要随手写 13px
3. **动效只用来解释状态变化**，时长 150–300ms，不要炫技
4. **对比度至少 4.5:1** —— 浅灰字配白底是最常见的翻车点

## 常见翻车

- 卡片阴影过重，页面看起来脏
- 圆角半径混用（8px / 10px / 12px 同时出现）
- 移动端直接压缩桌面布局，而不是重新排版
`,
      'references/color.md': `# 配色速查

- 主色只用于「主操作」和「当前选中」
- 中性色准备 6 档：背景 / 卡片 / 描边 / 次要文字 / 正文 / 标题
- 状态色固定：成功绿、警告黄、错误红，不要自创
`,
    },
  },
  {
    name: 'commit-helper.zip',
    files: {
      'SKILL.md': `---
name: commit-helper
description: 根据 git diff 生成符合 Conventional Commits 规范的中文提交信息，并在提交前做自检。
version: 1.1.0
license: MIT
author: jerry
category: productivity
tags: [git, 提交规范, 效率]
---

# Commit Helper

## 何时使用

- 用户说「帮我提交一下」「写个 commit message」
- 提交前需要自检（有没有漏文件、有没有调试代码）

## 步骤

1. \`git status\` + \`git diff --staged\` 看真实改动
2. 判断类型：feat / fix / docs / refactor / chore / test / style
3. 生成 \`type(scope): 一句话说清做了什么\`
4. 正文写「为什么」，不写「改了什么」—— 改了什么 diff 里有

## 提交前自检

- [ ] 没有 console.log / debugger 残留
- [ ] 没有把 .env、密钥提交进去
- [ ] 改动的文件都在预期范围内
`,
    },
  },
  {
    name: 'data-cleaner.zip',
    files: {
      'SKILL.md': `---
name: data-cleaner
description: 清洗 CSV / Excel 数据：去重、缺失值处理、类型规整、异常值检测，并输出清洗报告。
version: 0.9.2
license: Apache-2.0
author: jerry
category: data
tags: [数据清洗, csv, pandas]
---

# Data Cleaner

## 何时使用

用户拿来一份「脏数据」，想要能用 —— 或者想知道它到底有多脏。

## 流程

1. **先诊断，别急着改** —— 输出行数、列类型、缺失率、重复率
2. 和用户确认清洗策略（缺失值填什么？重复怎么算重复？）
3. 执行清洗，**保留原始文件**
4. 输出清洗报告：改了什么、影响多少行

## 铁律

- 永远不要静默丢数据 —— 每丢掉一行都要能被解释
- 清洗后的文件另存，不要覆盖源文件
`,
      'scripts/profile.py': `import sys
import pandas as pd


def profile(path):
    df = pd.read_csv(path)
    print(f'行数: {len(df)}  列数: {len(df.columns)}')
    print('--- 缺失率 ---')
    print((df.isna().mean() * 100).round(2).to_string())
    print('--- 重复行 ---')
    print(int(df.duplicated().sum()))


if __name__ == '__main__':
    profile(sys.argv[1])
`,
    },
  },
]
