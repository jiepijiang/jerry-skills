-- ============================================================================
-- UI 技能包入库 · 后台管理系统（6 个）
-- ----------------------------------------------------------------------------
-- 跑法：Supabase → SQL Editor → 新建查询 → 粘贴本文件 → Run。
--
-- ⚠️ 幂等：末尾是 `on conflict do nothing`，重复跑不会插重复，
--    也不会覆盖已经攒下的下载量 / 安装量 / 评分。
-- ⚠️ 需要先跑过 001-skills.sql（本文件只 insert，不建表）。
-- ============================================================================

insert into public.skills
  (slug, name, description, category, tags, version, license, author,
   readme, files, file_count, total_bytes, hash, bundle_b64, status)
values (
  'ui-design-system', 'ui-design-system', 'UI 设计系统工具包：生成设计令牌、构建调色板与字号阶梯、编写组件文档、做响应式尺寸计算，并产出开发交接文档。', 'ui',
  array['设计系统', '设计令牌', '组件文档', '调色板', '字号阶梯', '响应式', '开发交接']::text[], '1.0.0', 'MIT', 'Alireza Rezvani',
  $md$---
name: "ui-design-system"
description: "UI 设计系统工具包：生成设计令牌、构建调色板与字号阶梯、编写组件文档、做响应式尺寸计算，并产出开发交接文档。"
version: "1.0.0"
license: "MIT"
author: "Alireza Rezvani"
category: ui
tags: ["设计系统", "设计令牌", "组件文档", "调色板", "字号阶梯", "响应式", "开发交接"]
---

# UI Design System

Generate design tokens, create color palettes, calculate typography scales, build component systems, and prepare developer handoff documentation.

---

## Table of Contents

- [Trigger Terms](#trigger-terms)
- [Workflows](#workflows)
  - [Workflow 1: Generate Design Tokens](#workflow-1-generate-design-tokens)
  - [Workflow 2: Create Component System](#workflow-2-create-component-system)
  - [Workflow 3: Responsive Design](#workflow-3-responsive-design)
  - [Workflow 4: Developer Handoff](#workflow-4-developer-handoff)
- [Tool Reference](#tool-reference)
- [Quick Reference Tables](#quick-reference-tables)
- [Knowledge Base](#knowledge-base)

---

## Trigger Terms

Use this skill when you need to:

- "generate design tokens"
- "create color palette"
- "build typography scale"
- "calculate spacing system"
- "create design system"
- "generate CSS variables"
- "export SCSS tokens"
- "set up component architecture"
- "document component library"
- "calculate responsive breakpoints"
- "prepare developer handoff"
- "convert brand color to palette"
- "check WCAG contrast"
- "build 8pt grid system"

---

## Workflows

### Workflow 1: Generate Design Tokens

**Situation:** You have a brand color and need a complete design token system.

**Steps:**

1. **Identify brand color and style**
   - Brand primary color (hex format)
   - Style preference: `modern` | `classic` | `playful`

2. **Generate tokens using script**
   ```bash
   python scripts/design_token_generator.py "#0066CC" modern json
   ```

3. **Review generated categories**
   - Colors: primary, secondary, neutral, semantic, surface
   - Typography: fontFamily, fontSize, fontWeight, lineHeight
   - Spacing: 8pt grid-based scale (0-64)
   - Borders: radius, width
   - Shadows: none through 2xl
   - Animation: duration, easing
   - Breakpoints: xs through 2xl

4. **Export in target format**
   ```bash
   # CSS custom properties
   python scripts/design_token_generator.py "#0066CC" modern css > design-tokens.css

   # SCSS variables
   python scripts/design_token_generator.py "#0066CC" modern scss > _design-tokens.scss

   # JSON for Figma/tooling
   python scripts/design_token_generator.py "#0066CC" modern json > design-tokens.json
   ```

5. **Validate accessibility**
   - Check color contrast meets WCAG AA (4.5:1 normal, 3:1 large text)
   - Verify semantic colors have contrast colors defined

---

### Workflow 2: Create Component System

**Situation:** You need to structure a component library using design tokens.

**Steps:**

1. **Define component hierarchy**
   - Atoms: Button, Input, Icon, Label, Badge
   - Molecules: FormField, SearchBar, Card, ListItem
   - Organisms: Header, Footer, DataTable, Modal
   - Templates: DashboardLayout, AuthLayout

2. **Map tokens to components**

   | Component | Tokens Used |
   |-----------|-------------|
   | Button | colors, sizing, borders, shadows, typography |
   | Input | colors, sizing, borders, spacing |
   | Card | colors, borders, shadows, spacing |
   | Modal | colors, shadows, spacing, z-index, animation |

3. **Define variant patterns**

   Size variants:
   ```
   sm: height 32px, paddingX 12px, fontSize 14px
   md: height 40px, paddingX 16px, fontSize 16px
   lg: height 48px, paddingX 20px, fontSize 18px
   ```

   Color variants:
   ```
   primary: background primary-500, text white
   secondary: background neutral-100, text neutral-900
   ghost: background transparent, text neutral-700
   ```

4. **Document component API**
   - Props interface with types
   - Variant options
   - State handling (hover, active, focus, disabled)
   - Accessibility requirements

5. **Reference:** See `references/component-architecture.md`

---

### Workflow 3: Responsive Design

**Situation:** You need breakpoints, fluid typography, or responsive spacing.

**Steps:**

1. **Define breakpoints**

   | Name | Width | Target |
   |------|-------|--------|
   | xs | 0 | Small phones |
   | sm | 480px | Large phones |
   | md | 640px | Tablets |
   | lg | 768px | Small laptops |
   | xl | 1024px | Desktops |
   | 2xl | 1280px | Large screens |

2. **Calculate fluid typography**

   Formula: `clamp(min, preferred, max)`

   ```css
   /* 16px to 24px between 320px and 1200px viewport */
   font-size: clamp(1rem, 0.5rem + 2vw, 1.5rem);
   ```

   Pre-calculated scales:
   ```css
   --fluid-h1: clamp(2rem, 1rem + 3.6vw, 4rem);
   --fluid-h2: clamp(1.75rem, 1rem + 2.3vw, 3rem);
   --fluid-h3: clamp(1.5rem, 1rem + 1.4vw, 2.25rem);
   --fluid-body: clamp(1rem, 0.95rem + 0.2vw, 1.125rem);
   ```

3. **Set up responsive spacing**

   | Token | Mobile | Tablet | Desktop |
   |-------|--------|--------|---------|
   | --space-md | 12px | 16px | 16px |
   | --space-lg | 16px | 24px | 32px |
   | --space-xl | 24px | 32px | 48px |
   | --space-section | 48px | 80px | 120px |

4. **Reference:** See `references/responsive-calculations.md`

---

### Workflow 4: Developer Handoff

**Situation:** You need to hand off design tokens to development team.

**Steps:**

1. **Export tokens in required formats**
   ```bash
   # For CSS projects
   python scripts/design_token_generator.py "#0066CC" modern css

   # For SCSS projects
   python scripts/design_token_generator.py "#0066CC" modern scss

   # For JavaScript/TypeScript
   python scripts/design_token_generator.py "#0066CC" modern json
   ```

2. **Prepare framework integration**

   **React + CSS Variables:**
   ```tsx
   import './design-tokens.css';

   <button className="btn btn-primary">Click</button>
   ```

   **Tailwind Config:**
   ```javascript
   const tokens = require('./design-tokens.json');

   module.exports = {
     theme: {
       colors: tokens.colors,
       fontFamily: tokens.typography.fontFamily
     }
   };
   ```

   **styled-components:**
   ```typescript
   import tokens from './design-tokens.json';

   const Button = styled.button`
     background: ${tokens.colors.primary['500']};
     padding: ${tokens.spacing['2']} ${tokens.spacing['4']};
   `;
   ```

3. **Sync with Figma**
   - Install Tokens Studio plugin
   - Import design-tokens.json
   - Tokens sync automatically with Figma styles

4. **Handoff checklist**
   - [ ] Token files added to project
   - [ ] Build pipeline configured
   - [ ] Theme/CSS variables imported
   - [ ] Component library aligned
   - [ ] Documentation generated

5. **Reference:** See `references/developer-handoff.md`

---

## Tool Reference

### design_token_generator.py

Generates complete design token system from brand color.

| Argument | Values | Default | Description |
|----------|--------|---------|-------------|
| brand_color | Hex color | #0066CC | Primary brand color |
| style | modern, classic, playful | modern | Design style preset |
| format | json, css, scss, summary | json | Output format |

**Examples:**

```bash
# Generate JSON tokens (default)
python scripts/design_token_generator.py "#0066CC"

# Classic style with CSS output
python scripts/design_token_generator.py "#8B4513" classic css

# Playful style summary view
python scripts/design_token_generator.py "#FF6B6B" playful summary
```

**Output Categories:**

| Category | Description | Key Values |
|----------|-------------|------------|
| colors | Color palettes | primary, secondary, neutral, semantic, surface |
| typography | Font system | fontFamily, fontSize, fontWeight, lineHeight |
| spacing | 8pt grid | 0-64 scale, semantic (xs-3xl) |
| sizing | Component sizes | container, button, input, icon |
| borders | Border values | radius (per style), width |
| shadows | Shadow styles | none through 2xl, inner |
| animation | Motion tokens | duration, easing, keyframes |
| breakpoints | Responsive | xs, sm, md, lg, xl, 2xl |
| z-index | Layer system | base through notification |

---

## Quick Reference Tables

### Color Scale Generation

| Step | Brightness | Saturation | Use Case |
|------|------------|------------|----------|
| 50 | 95% fixed | 30% | Subtle backgrounds |
| 100 | 95% fixed | 38% | Light backgrounds |
| 200 | 95% fixed | 46% | Hover states |
| 300 | 95% fixed | 54% | Borders |
| 400 | 95% fixed | 62% | Disabled states |
| 500 | Original | 70% | Base/default color |
| 600 | Original × 0.8 | 78% | Hover (dark) |
| 700 | Original × 0.6 | 86% | Active states |
| 800 | Original × 0.4 | 94% | Text |
| 900 | Original × 0.2 | 100% | Headings |

### Typography Scale (1.25x Ratio)

| Size | Value | Calculation |
|------|-------|-------------|
| xs | 10px | 16 ÷ 1.25² |
| sm | 13px | 16 ÷ 1.25¹ |
| base | 16px | Base |
| lg | 20px | 16 × 1.25¹ |
| xl | 25px | 16 × 1.25² |
| 2xl | 31px | 16 × 1.25³ |
| 3xl | 39px | 16 × 1.25⁴ |
| 4xl | 49px | 16 × 1.25⁵ |
| 5xl | 61px | 16 × 1.25⁶ |

### WCAG Contrast Requirements

| Level | Normal Text | Large Text |
|-------|-------------|------------|
| AA | 4.5:1 | 3:1 |
| AAA | 7:1 | 4.5:1 |

Large text: ≥18pt regular or ≥14pt bold

### Style Presets

| Aspect | Modern | Classic | Playful |
|--------|--------|---------|---------|
| Font Sans | Inter | Helvetica | Poppins |
| Font Mono | Fira Code | Courier | Source Code Pro |
| Radius Default | 8px | 4px | 16px |
| Shadows | Layered, subtle | Single layer | Soft, pronounced |

---

## Knowledge Base

Detailed reference guides in `references/`:

| File | Content |
|------|---------|
| `token-generation.md` | Color algorithms, HSV space, WCAG contrast, type scales |
| `component-architecture.md` | Atomic design, naming conventions, props patterns |
| `responsive-calculations.md` | Breakpoints, fluid typography, grid systems |
| `developer-handoff.md` | Export formats, framework setup, Figma sync |

---

## Validation Checklist

### Token Generation
- [ ] Brand color provided in hex format
- [ ] Style matches project requirements
- [ ] All token categories generated
- [ ] Semantic colors include contrast values

### Component System
- [ ] All sizes implemented (sm, md, lg)
- [ ] All variants implemented (primary, secondary, ghost)
- [ ] All states working (hover, active, focus, disabled)
- [ ] Uses only design tokens (no hardcoded values)

### Accessibility
- [ ] Color contrast meets WCAG AA
- [ ] Focus indicators visible
- [ ] Touch targets ≥ 44×44px
- [ ] Semantic HTML elements used

### Developer Handoff
- [ ] Tokens exported in required format
- [ ] Framework integration documented
- [ ] Design tool synced
- [ ] Component documentation complete
$md$,
  '[{"path":"ATTRIBUTION.md","size":965,"kind":"text"},{"path":"LICENSE","size":1072,"kind":"text"},{"path":"SKILL.md","size":10810,"kind":"text"},{"path":"assets/design_system_doc_template.md","size":6906,"kind":"text"},{"path":"references/component-architecture.md","size":10129,"kind":"text"},{"path":"references/developer-handoff.md","size":10244,"kind":"text"},{"path":"references/responsive-calculations.md","size":8766,"kind":"text"},{"path":"references/token-generation.md","size":8530,"kind":"text"},{"path":"scripts/design_token_generator.py","size":20582,"kind":"text"}]'::jsonb, 9, 78004, '2f389d099647cddc678a1c8e08ad1ed74198f93749efc105f03d5e096482a1c7',
  $b64$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$b64$,
  'published'
)
on conflict do nothing;

insert into public.skills
  (slug, name, description, category, tags, version, license, author,
   readme, files, file_count, total_bytes, hash, bundle_b64, status)
values (
  'admin-dashboard-layout', 'admin-dashboard-layout', '搭建或重构后台管理系统的整体布局骨架时使用：侧栏档位、顶栏高度、内容区留白、面包屑时机、多标签页上限与滚动分工。', 'ui',
  array['后台管理', '布局骨架', '侧边栏', '多标签页', '滚动分工', '面包屑', '响应式']::text[], '1.0.0', 'MIT', 'Skill Hub',
  $md$---
name: "admin-dashboard-layout"
description: "搭建或重构后台管理系统的整体布局骨架时使用：侧栏档位、顶栏高度、内容区留白、面包屑时机、多标签页上限与滚动分工。"
version: "1.0.0"
license: "MIT"
author: "Skill Hub"
category: ui
tags: ["后台管理", "布局骨架", "侧边栏", "多标签页", "滚动分工", "面包屑", "响应式"]
---

# 后台管理系统布局骨架

后台不是「把官网塞进侧栏」。它的第一诉求是**信息密度**和**长时间使用的疲劳度**，
视觉表现力排在后面。一个后台如果让人每天点 200 次、每次都要「跳页 → 找位置 → 滚回去」，
再好看的渐变也救不回来。本技能把布局骨架拆成可量化的尺寸与分工规则。

## 何时使用

- 从零搭一个后台的布局骨架（侧栏 + 顶栏 + 内容区）
- 现有后台「点哪都要跳页、切回来就找不到自己刚才在干嘛」
- 侧栏、顶栏、内容区的宽度 / 高度互相打架，折叠后出现 1px 缝隙或重叠
- 用户抱怨「标签页开了 30 个，关都关不完」
- 内容区滚动时顶栏跟着滚走了，或者两层 sticky 互相抢层级导致抖动
- 要决定「面包屑到底要不要做」却各说各话

## 核心规则

1. **侧栏宽度取 200 / 240 / 280 三档**，不要随手写 220。
   200 适合纯图标 + 短词的一级菜单；240 是通用默认（中文菜单项 6–8 字）；280 适合有二级缩进 + 徽标数字的复杂菜单。
   折叠态固定 `64px` —— 这个数字来自图标 24 + 左右各 20 的内边距，不是拍脑袋。

2. **顶栏高度 56 或 64px，全站统一**。56 适合工具型后台（只有面包屑 + 头像）；
   64 适合顶栏里放了全局搜索框或标签页的。两个值不要混用，混用会让页面切换时内容区跳动 8px。

3. **内容区不设最大宽度上限**，只给左右各 24px 的最小留白。
   设上限（比如 1440）在大屏上会让两侧出现大片空白，而后台恰恰是靠横向空间吃饭的。
   如果确实担心超宽屏难读，限制的是**单个表单/正文**的宽度（如 720px 居中），不是整个内容区。

4. **面包屑只在层级 ≥ 3 时出现**。二级页面的标题本身就是位置信息，再加面包屑是纯噪音。
   三级及以上（列表 → 详情 → 子详情）才需要面包屑把「我怎么进来的」补回来。

5. **多标签页（tab）最多同时开 8 个**，超出时关掉最久未访问的那个并给一次 toast。
   不设上限的话，一周后没人能在那排标签里找到东西，横向滚动条会变成一条缩略的地铁图。

6. **滚动职责必须单一**：顶栏吸顶（`position: sticky; top: 0`），侧栏独立滚动，
   内容区自己滚动。三者不要同时 sticky，否则层级互抢、滚动时抖动。

7. **1280 宽是后台的最低可用宽度**。低于 1280 时侧栏自动折叠为 64px 图标态，
   低于 1024 时侧栏改为抽屉（覆盖式，`z-index` 高于内容区），不再挤压内容。

## 怎么做

### 第 1 步：定外层 flex 结构（唯一正确骨架）

```css
.app { display: flex; min-height: 100vh; }
.sidebar {
  flex: 0 0 var(--sidebar-w, 240px);   /* 折叠时改 64px */
  transition: flex-basis .2s ease;
  overflow-y: auto;                    /* 侧栏自己滚 */
  position: sticky; top: 0;
  height: 100vh;
}
.main { flex: 1 1 auto; min-width: 0; display: flex; flex-direction: column; }
.topbar { position: sticky; top: 0; height: 56px; z-index: 20; }
.content { flex: 1 1 auto; padding: 24px; overflow-y: auto; }
```

- `min-width: 0` 加在 `.main` 上是必须的：flex 子项默认 `min-width: auto`，
  表格会把它撑破，导致整页横向滚动。
- 侧栏折叠只改 `--sidebar-w` 一个变量，**不要**用 `margin-left` 顶内容区。
  用 margin 的方案在折叠动画里会出现 1px 缝隙或重叠。

### 第 2 步：定尺寸刻度

| 元素 | 取值 | 说明 |
| --- | --- | --- |
| 侧栏展开 | 200 / 240 / 280 | 三档，全站取一档 |
| 侧栏折叠 | 64 | 图标 24 + 左右 20 |
| 顶栏 | 56 / 64 | 全站统一 |
| 内容区左右留白 | ≥ 24 | 大屏可 32 |
| 内容区上下留白 | 24 | 顶部不要再叠顶栏的 padding |
| 菜单项高度 | 40（一级）/ 36（二级） | 触屏 44 |
| 菜单图标 | 20 或 24 | 与字号 14 搭配取 20 |
| 侧栏分组标题 | 32 | 字号 12，字重 500，颜色弱化 |
| 多标签页条 | 40 | 超出走横向滚动 |

### 第 3 步：菜单的层级与折叠态

- 一级菜单最多 2 层，不要出现三级缩进 —— 三级缩进后每层只剩 12px 可用，中文直接换行。
- 折叠态只显示图标，但**必须**保留：
  1. `title` 或 tooltip 显示完整名称（hover 200ms 后出现）
  2. 当前项的高亮（背景色 + 左侧 3px 主色条）
  3. 有子菜单时图标右下角一个小三角或圆点
- 折叠态点击有子菜单的项时，弹出二级浮层（宽 200px）而不是直接跳转。

### 第 4 步：面包屑的时机与形态

```html
<nav aria-label="面包屑">
  <a href="/orders">订单管理</a> /
  <a href="/orders/1024">订单 1024</a> /
  <span aria-current="page">退款记录</span>
</nav>
```

- 层级 < 3 不渲染这个 `<nav>`。
- 最后一段用 `aria-current="page"` 且不可点击，前面每一段都要能点。
- 分隔符统一用 `/` 或 `>`，不要混用。
- 面包屑里**不要**放「首页」以外的顶级入口 —— 侧栏已经在做这件事了。

### 第 5 步：多标签页的淘汰策略

```ts
const MAX_TABS = 8;
function openTab(tab: Tab) {
  setTabs(prev => {
    const exists = prev.find(t => t.path === tab.path);
    if (exists) return [...prev.filter(t => t.path !== tab.path), tab]; // 命中则置顶
    const next = [...prev, tab];
    if (next.length > MAX_TABS) {
      const evictable = next.filter(t => !t.pinned && t.path !== tab.path);
      evictable.sort((a, b) => a.lastVisited - b.lastVisited);
      const victim = evictable[0];
      if (victim) toast(`已关闭最久未访问的「${victim.title}」`);
      return next.filter(t => t !== victim);
    }
    return next;
  });
}
```

淘汰规则的三个硬约束：
1. **固定标签（pinned）永不淘汰**，比如首页 / 当前工作台。
2. **当前标签永不淘汰**，否则用户会看到自己被弹走。
3. 淘汰必须给**可见反馈**（toast），静默关掉会让人以为是自己误操作。
4. 关闭当前标签后，激活它**左边**那个，而不是跳回首页 —— 跳首页会打断工作流。

### 第 6 步：响应式三档

| 断点 | 侧栏 | 顶栏 | 内容区 |
| --- | --- | --- | --- |
| ≥ 1440 | 280 / 240 展开 | 64 | 留白 32 |
| 1280–1439 | 240 展开 | 56 | 留白 24 |
| 1024–1279 | 64 图标态（可 hover 展开） | 56 | 留白 24 |
| < 1024 | 抽屉（覆盖），默认收起 | 56 | 留白 16 |

```css
@media (max-width: 1279.98px) { :root { --sidebar-w: 64px; } }
@media (max-width: 1023.98px) {
  .sidebar { position: fixed; inset-block: 0; inset-inline-start: 0;
             transform: translateX(-100%); transition: transform .2s; }
  .sidebar[data-open="true"] { transform: none; box-shadow: 4px 0 24px rgba(0,0,0,.15); }
}
```

抽屉态必须给内容区加遮罩（`rgba(0,0,0,.4)`），点击遮罩关闭，且 `Esc` 也能关。

## 检查清单

- [ ] 侧栏、顶栏在 1280 / 1440 / 1920 三个宽度下都不变形
- [ ] 侧栏折叠只改一个 CSS 变量，折叠动画中不出现缝隙或重叠
- [ ] `.main` 上有 `min-width: 0`，超宽表格不会撑破整页
- [ ] 内容区滚动时顶栏保持吸顶，侧栏独立滚动，两者不互相抢 sticky
- [ ] 折叠侧栏后，当前菜单项仍能看出处于哪一层（高亮 + tooltip）
- [ ] 面包屑只在层级 ≥ 3 时渲染，最后一段不可点
- [ ] 多标签页上限 8，固定标签与当前标签不被淘汰，淘汰有 toast
- [ ] 关闭当前标签后激活左邻标签，而不是跳回首页
- [ ] 表格页在 1280 宽下不出现整页横向滚动（超宽表格走固定列 + 局部横向滚动）
- [ ] < 1024 时侧栏为抽屉，有遮罩且 `Esc` 可关
- [ ] 键盘可完整操作侧栏（Tab 聚焦、Enter 进入、左右键展开/收起子菜单）

## 常见错误

| 错误做法 | 为什么错 | 正确做法 |
| --- | --- | --- |
| 侧栏 `position: fixed` + 内容区 `margin-left` | 折叠时两者不同步，出现 1px 缝隙或重叠 | 外层 flex，侧栏 `flex: 0 0 auto` |
| 顶栏和侧栏都做吸顶 | 两层 sticky 互相抢层级，滚动时抖动 | 只让顶栏吸顶，侧栏用固定高度内滚动 |
| flex 子项忘记 `min-width: 0` | 表格把容器撑破，整页出现横向滚动条 | 滚动容器 / 主区加 `min-width: 0` |
| 侧栏写死 220px | 与全站其他页面宽度不齐，折叠态无规律 | 从 200/240/280 里取一档 |
| 多标签页不设上限 | 开满 30 个后无法定位，关起来像扫雷 | 上限 8 + LRU 淘汰 + toast |
| 面包屑每页都做 | 二级页面标题已说明位置，面包屑是噪音 | 层级 ≥ 3 才出现 |
| 内容区设 `max-width: 1440px` | 大屏两侧留白，浪费后台最需要的横向空间 | 不限制内容区，只限制正文/表单列宽 |
| 菜单做三级缩进 | 每层可用宽度不足，中文换行、图标错位 | 一级最多两层，第三层用标签页或详情承载 |
| 关闭当前标签跳回首页 | 打断用户连续操作，需要重新找回列表 | 激活左邻标签 |

## 参考

- 需要完整的断点策略、超宽屏（2560+）如何分配留白、侧栏抽屉与键盘可达性细节时，读 `references/responsive-shell.md`
- 需要多标签页的完整状态模型（固定、持久化到 sessionStorage、与路由同步、跨刷新恢复）时，读 `references/multi-tab-policy.md`
$md$,
  '[{"path":"ATTRIBUTION.md","size":484,"kind":"text"},{"path":"LICENSE","size":1074,"kind":"text"},{"path":"SKILL.md","size":9893,"kind":"text"},{"path":"references/multi-tab-policy.md","size":4407,"kind":"text"},{"path":"references/responsive-shell.md","size":4031,"kind":"text"}]'::jsonb, 5, 19889, '9c31edd2e2329f00fe1d449efaa98042ed7d0f35d29452c4a61faf9bd34e5718',
  $b64$UEsDBBQAAAAIAAAAIQBT7NwTjwEAAOQBAAAOAAAAQVRUUklCVVRJT04ubWRFUU1LAlEU3c+vuOCmBCMM2odBH9TKoHXFUENSYrUIWmjqqOWYgUZWU7kIo2ykD/NrRn+M7773WvkXuqNSm8e75957znnneYCbT7ydZ82ccD4wbygKv6vys6iMO/y65vVSJV5LmHvA9K3XO7DTwV0tFILFo00Q9hXqpYGdGdhZ1jRoXDpV6Tj96KminMBPuQUngHoSLboQ4PP5CBieVI10CfgnHKkMu9Jq4kVN1mI0sLq0Bivalrp3oA57IpPmZpwagf3wcUTb3jmEia1J8E/7Z2FZjUSOYeKPc5I2FI8HZO2LX+cUZWSHdU1uWJisoh0VNwlpdaVVlpWEzMYpCGw8iedztO5lo86LXyKv07MDwSDwxxSm9H40th6YWwD/lJ+uqxuHakTbCMG8eqBt78EMYcpcOBxSYXFpAUYa3Czzale8UVLjsDCbxPwr63SYU8TcKRZ18iEqMX6XGbupJ1i7MozSDSL1IgrvzOmJwjMJsJ7FCy3Xqm5gWseLS5e1Z4piyf29qxTrfKPxSYsuwS9QSwMEFAAAAAgAAAAhAEXy6+uDAgAAMgQAAAcAAABMSUNFTlNFXVLNjtowEL77KUacdqVoW+2hh95MYjZuQxI5ZinH/DjEbYiR7RTx9h0H2KqVkNCMZ76/yZZLyHSrJqcIic35avVx8PDUPsPr59cv8E1Ze4Wn6pceR0jn5pmQUtmTdk6bCbSDQVnVXOFo68mrLoLeKgWmh3ao7VFF4A3U0xXOyjpcMI2v9aSnI9TQIhvBST8gjDO9v9RW4XAHtXOm1TXiQWfa+aQmX/vA1+tROXjyg4JVdd9YPS8knapHoidEU/B4gov2g5k9WOW81W3AiEBP7Th3QcPjedQnfWcI60sEjiDo7NBB0BnByXS6D/9qsXWem1G7IYJOB+hm9th0oblkGQUfn4wFp8aRIIJG3YvXv+qWmSAds0H+e0QudC6DOf3rRDvSz3ZCSgwl2DUY2cL4U7U+dMJ4b8bRXIK11kydDo7cV0IkPtWN+a0WL7cLT8aj1JuEcIBFxO2q9yc31HjzBrmXwJAX48XWhx10NzfO4+F1PcLZ2IXvf5svyJ8yqIqN3FPBgFdQiuKdJyyBFa2wXkWw5zItdhJwQtBcHqDYAM0P8J3nSQTsRylYVUEhCN+WGWfY43mc7RKev8Ea9/ICP2OOHzOCygIC4R2KM9zbwJaJOMWSrnnG5SEiGy7zgLkpBFAoqZA83mVUQLkTZVExpE8QNuf5RiAL27JcviAr9oC9YwFVSrMsUBG6Q/Ui6IO4KA+Cv6US0iJLGDbXDJXRdcZuVGgqzijfRpDQLX0L6gQUiCJIGLupg33KQivwUfzFkhd5sBEXuRRYRuhSyI/VPa9YBFTwKgSyEcU2IiFO3MARBMG9nN1QQtRLQB8XwZFQ79D0AxASRjPEwvPki8XH8Av5A1BLAwQUAAAACAAAACEADZjxC6ETAAClJgAACAAAAFNLSUxMLm1khVptT1tJlv7uX1FD744I08ZASDoNCdrZ1Ui70s6XTe9qpKi1NuAEq41t2Sad3k4kAwFssDFJeH9JMOEtJNgQCBgbw3/pdtW9/pS/sM+pc325BDLTidLXvlWnzvt5zim73W5XyNfv7xANvt7+QMjd64v1dYd90V530PdLeCDe4Or1x3qigUg8EA5hlZraleWSSs7WxjLq9XM5NSmze0Y+Z0yNGgdlo/zGWHyuZg6rlVeyOCz3E7WdbfX6SM0dVSvnxvT259PF6tmWWs2q3NtqJfN7YrCWO8LH2vt5WdrERzk6IvMnMl0yZhaMhQotWFmT6RG5/wJE1HKJ1qwvqtUxY/eslvtULY7XFqaqxUlVXpTj2zI5Ko83fk8MNbge+6Mx5rm1uaW5pcEVDPT4QzES9a//8UODyzcQ7wtH8en+T4FgUPz7QHeDq8cX9z8KR3/pEAMBV9z3KNYhHjQ4ZWz4VjQ4BaPPEMg8O4EQ+qWDN/rsZIs+29Loxa8ysjQtT7MNP7rIEq5vxFWFOo9zufh9tZhR84XfE2k1Pi7z80blhcy9Ns+XWLe/J6DYIZkfhi2MDx+qxYRZSKn9IWxpaqqe59RgQRZGoe+mJvky3dRUmzmHbmtzsBrZiHbNfpTjB3rF59O0y9waNbdSZm7bmNyT40tq8qVc3gYnEAYHgX61uMOMyc0h9XrZzL+rlkqqkJXr74yhE9HW0iLUhxxMh+/wUBuumJuDYN88PoCexG+jL4VKncEhjEqeP0FtS6/lZBmyEAdyNCM3KsbyBLlXcUpm56snb9TMCygC69QKmVwtf1DjCXO4QkpxOt/EqEpiS6E2lpXpWVCQeyVZKMJp2C7m1nOZXAAFGOAbUa3M2O7qcrlFtTxZWzqC3zvlJCKOIz6fJln14k+CHRoPtit/Pk2BDnSnllO8HaJDL/LVDmuC1UCenRxjceTePikE0iX3zLEdebwvk4sqlSG9n3yU80vQC/Fm2duKokvxAw7zFZhQeARHV7X00lgqqtQrzTBcZ15mV4mfsRJ4E62RJ8I4XaktLnB04yVxPb2tksdqfF8ltsnf6r4tTxPV0qi42SKgE1CTIweQBf8Sz/k0s2czw1FATqb5NI/fGCsJfGl+2gMVYiY5ayZGqsV1uT8kYvFAz0+/CIvf8TV8Z5S2ZOHUHDtU47OgBNpQmxw9kPlFcGUHFbQlSzN4BS5owSDeZmTmUE49Nwv874o2slotyvNhNrzL1dosEBhal6wzmZ3VTusRbe363zskZwpJSwcEU68tZlVqQo4uiLa2FvIeIfSmGmJvKmmUCnLpDPqCJxhvds1CBhaBC0ESM7ssMzOfT5eIOIKylliEmmvleTO/Tp5U3FWzY7yoljsRt39LvLoj5O4c/Ig2gRc+Au5ULaVB0Dh9h+Anlzur4EQ1s4fV5ADrGbUyxJQsBtnqCo6yVILyhPd2e+SJV/yWmMZfYZ4vwJy8H15InscytLUT9WMo5gBahJiCyI+OIPGZxyusEkiiJjLm8xfm2oQOpjZSqzO/i1u3BSwt6EztM9vG+wWkOKilqQlb8JolQ1DKkWP5eoLDBUqR2R2IaxuauFk/lMNZ1glJdrvd2mydOJZW02fwLpyCOFVTy8bhmsohFczaTgwZdP5ap7hOnLJZ1fGxLlRpfqieLiKdYTGdnRxTmTW4se3YiFy4o7gTeaIlvkkS2y+JXv5MLSfk+hb7FVcr7UMQyCgvOFQKnZBSafletl79tM1AhDdCD6owjRwrWtvbWyA6pQPQ3s/iPTNKwpxtcUjjlZEaM96VQAonmok0q1MN6r9wvJVVtY2M9gJrkP7l1HBtY5eVQudyMjdyeZl/rSZGKGCOIFoF59UWz8xCGUTBlUweEd9UXOBnUCUKBR48avct/Lipyc5EZEbw/l1bC0SV+wj3XW2+uvMANsAOde1phbZrF7LDO7tDEut0IH5LbYibgoyhhdUOxOHAxiKeVsdqa/OoC2bpPWXU+QKXGK6BZASUlfHVC4QxX6CwXdipvTmwdICop9yTHa+WN6BkEiE5BwF1lTILm2p4RD/K3Sn+BImQp2vLCcoQNuHxcUqeyRcqMVk9SSJYEV1a0Rkzt2FXMJfrlnYgB4bAgXFfNxElN1qUU2mS+DQh7lDi1Z5ERhkr0dcjB2qSFlZPRtTyjpk/r83lcUpt6C0p9uQIDodQQwEW8bAvFrdFJDdlD8NqpEhtkoR8QTVefcyhlqOqQvMghNpv8Yb4Sp0h4VaLy+bGOcWLdiUr1a/k4I8o06i8dORKDjnKmCGZ5fJe7RXSz5kW+DYJzHvMwbR5+Faej9RyZe1ISArAixzOcqqIB2jDGwnHAgxGuU50QphIh2jxWr6k07gx8cF4P8F0CT+QN9sxq+spv9Phn9KlRxcMrV6LMPnH1CYKBDscyhFqEWGYejHjWqTF+I7EaKXUDFeHG9kogaxRwXMBqYSjgB21MlktTQq9g9CGZpoYA2GdoavFkk6TghMwErYlRn1nC1KyvVNNn2CDGkdoQgdJc3PUWJoFrsQe7/+5A6FeP3I8cjB2OlEJhx6CQKXX5SRKGb2q4yB2VZRQ+vSNAJAUrULtbsAkKBxyfZZK9cOgH1mrDEjxnEJjukDG3n2LnFEHRimXy+v19sRirmZfJCJ+Fb2BWAS9RYfe2ymo6ejzBx71xTsgVMvjvk7xzNUcC/T6u31R8StEpnWwL/489kUb3W7rnfvnb6k6R57c6IRaPE310ga7TKNoku6aPNgej/pCdY8hUu5uXywQE81tMeH3xfydWBJGr/AwGP7ZDa7QFoSJ4JX/cMKFmbT/MP2v+SMRviyYC4L1+wIhKIFlasUfPo+08HOgN95HG79Ukea6NxD19/A5PeHgQH9I6wlHaTV9nQubh1u3I6BleUMHSrgm0BMOxf2h+DUsRXy9vYHQI6yEKjuv0dEzMiwhZK+Te69ARkWuEF4tqxfpZZwCQoc1AgLuo50GCRPghkHPJQpEHLFMzo48q1ZPkUh0mzOsXr4wVg8pLBkKzhwiQTqzDrluHRRb8BawAd7gdXgNcaSBfHYeDQGoAfrp4Eelmgbb/b7oI3AT9D+MI2ZyF7We0yWt4SW6Ws+eqFwS4lrHjW8b02WkRkp+X4XVVoRxTLU5Ykq3JTJZRpZwuZ4KOTJsHK4KPGRnAU/wABCr5ifFU7xEv4gvHP/iOwvC7s9QgXh6BcFigcawNvQCXYrX3FvHbhYEa4GncPIV+EfYj1Zbbc5TwnQea7EDz+k1tup4K4MaLKTSDZJYoMELsqO42XZ5BwGa4oS9Q6/GkbXhbStTo3JnV5kJ2KHurZqIDZ0t1PlUEFgCribwjYzkETdv02cNFvCZFLu1CUZEO46xCViykx41atU8UNO4Oyezx4BgAk1hbQR8ULPgNEBy1Chb4ANbSDSC73pTGyl/dw6OIG61gKt0bW3ZTH2Up/toTVkFjuqPuqm5Jw51lUfD5HR4bLAdCVhIOxIzT4WWyxZGI3XMr9tZRwvCmAIuiKV2W8N+y7jHaiys7sD5HSED9Pf7Q4TJUu8gGNUqXeY0JWphjKVDNbkBxGzm0BBSaF50H4jL+TNjvcRKpi2VUSAfnSVoSLEC00MYBByaM288EA/6vdoK8XA4GA9E0Dfp7fk00oCcyhhb1CX0UZYiv++P6UmKFoVqEDqzZiExlAI0y50QJqJimKdaOZxWCwWYgD0cFhQ3IUq1WMZ30D/vBrCn5h0gjxUHsKUZh1fDTc2tl1ZO2QMST+EjOJXLo+jxnUJTyz9WdtIhRnInoEZecYq3JXZK9SmvTZIEZCBxqF0CSrGAMusVrYdZ+XApl8AjtQvYuJMylJ6akdtW1rQLIGn3xfuDrrsh32PhiwZ8mPR1+4P3HKOpLkh81yf6ov6H9xo84WgvRmkNXWZ+jVjWo6m7Hl+XoOr35TIPAZP6Wo1SLpbGIr4Qn9gzEI2i6txriPge+Ru6agmA0jMzvycrM3c9tKzLddcD/rrqJcbC/Hfh5aSD4kf15hU3q8JLgnR5LQeDR09NUlLLf9LZ/JrjqABME+6Bt2qLkPLhFytr8Gjeao1lhitYwIQR07XFaePDJqc3TdvDHuntonLlbB55i61P1IOLGoOmlCYWm7N64pNBWwEopf3giBqNkQ2ZfWsHHKeT449GOUuNz+AiyVw+qpYm0NheMv2tehlxZA+y/vG82t8zdmeBvbXp4zEXSn4sLv7657/97w9//tf74p640+l6OBDS4EKEI/7QD77uRjQdHQIPNzQEi/njeI41RqL+x+Jel/5OAIcQIf+TQCweAxl62fwQ8KIxTmvizRFfvE/cu3dPgJj+cIMwkRCBh6KRd90QUX98IBoSD5qbm639wbg/eonCH5wUvqXHHzuFxyPkiwryDPA5Ojpoz8FSyP8EBGyi1h77bHrdHPSHHoF4l60IltQh1+NAD/YF/aCkdzhZ+wN4C4RC/l7xxz9eyyefJi6oNMfC0Xhjo+9bAZ2Cgq85iBbsfwKAbaDiFt3Oz/Z2ZoVoBPrBh03tQYslD0vEC25wW9fohcfQPG5u92ovCN/7p195ebPOqs/ghF77PMscV+SNa+msY3jxM/2vYwN9/QwvLVzIrscjNj36SiFajdwHo7SpVt5QbtdjN55Dsc8i4bFWqd/dw4A2w0R0m8uTDw4cIA5O5hgUVSvLeqI6xPMm/p7pXaHB/RzPNAHRME+256vm2ntkYNRXokTpXu+yYGt5AYSzBXMLhStT20wSsaRWNndRtZUFIFnuv605TKmkJwYl5GvrgEJBvcqAWzoAcw22kJNdZC6S8zyhDsuAuzjyeBMDNgxAdAPPIxwuATR3WnptKaM+vMMUWX9BgBlT3tld1o76hFG7I1VgBsepon77wKiQECf20Ly+DmQYc/GDjcyuR582BiVsR9Mpwk3AnIw/bUiqcaKF6izIRz0wJpyt7Te/10DPsRrQ0l5N6ItWo6LQ6rbvaDXIOfpjDAkLgiEAk2Bsdw2Vu9w/Q+DLLbNlTd2UqOkj89PxF/tb8Ww3tP/S7+8N+ERjv+9JvXkhvpq/xzgQ2UR0RMNh6qwczUeHbkzROyF8rtve0nazvh3RdNEGO/q7h4En/t5OEcBVVtzdHQz3/KTbPP4cCAUDIb87FvdF0fLpHtTxn26FH4aj/R38GMR1198a3ehO/xlNtLNRtldSn0yt3gUzD3p9cZ+b6sS9hnh0wN/wI9hzUA6FQ/5O0R1+4o71+XrDEJla8RYecEYfdfsaW76lP82tt3DoMztdaEsQNKyH3EX3gBHdYN6ovKPxj5NC+w1r6MN1nBdxXOmKPC28f4n1oN6fvKEB1oge6unZxtuEerOhiiMAKQQvHogfv7xLoRZWj2c87M743/dA+ZzG6tPcCQAFjSTmga4u0XG2n4wNxb/dvw+EbDWdzn4RVYyIaLB69QaGaDp76eXUFw23NQLMV6x2uZihBKB7ZW6RLSJfu40B2FZpjL54wHb9AA1jZR6S2Zcy1pzBom0NrRiv6DTGic1uxarlDMEpJNyxklx/ToOoVzs0ZNQwl9E4ELiF7vnGjAj/g9kvI0HSpwP42diuLviV+2Jxhzh0VB6Njy8yMYG1tfdcAvRNAD2Q5nXOr5O9LoFb2ft4szZUrhe169O2RYWNRjdqdYeDJeFZtkdcHXNQunIYHDWLRcFkmpoYXEoOb19eX9emlffsuaFjaAgNpjiALuIGWoSQdUtM540lWLnAPRfXMiYDhgAPhTm4aDynS/y/YKYUxWXSEuAs3Unq7h/7OSt7OLPaTZCeESIoZbGIAlubXkClpGLETwC96mBGd96oqIAzSXxPmVtPGetv/+5ARDhmxjp7ep23s19MfKgmWHNE2+lpLEwlM/31mY4eZtgjUTuMhPdieqkHW47ZCe7eeRFdnA5itE8BqAX9O7egZKjL82c9HwLAwx2Vc1Bej2OMnbVz8CwEUtuTg6c8veVBnDxHzdv7cpSHsYN2MT1/O5EL2/YIjr3S8tDLg39SIf/qQW9B5kQzzWn8Cv2Lmcnogtot000qdMtjFh5RjRxVyxQulAisrJupVXAVZqVQVAw1t0ow82yCNpYnqWH2AEd49E3pGG7anFOuy8ng4uaD1HiKO+mcdadNsTy3CueC7nBrxFfccFu6nB/Gxe/72hKBg3o+gUf953/9t4UadSJDomBj25dAhSzJoY1NOx13VTwrAmznAR/fUmlceXEzxddSxOalHAgMzE55aXwGscivL4AFShjd89ZHbnxNyKCGVPlpxzw8sW4HlxN8e0Xto+N2UAub4fs+xyUCXWTyl3zf5+HbP+Qiml04pmmDi5dmSnASa350cTVC9jg6sOdH9ckRXRaRhqYXoBjNBo2weHjFwUIQgH7okiLdAN3b8zP8rEDfyqnUuVlhdq6m7UtgGnxp7MxNgnn+2ijvcq4je/C1Hn76NLtHt1/4iQrfBmLXlcTPwzkE55CZGCaUwbs5ferZMYFt7s0hpH23imzadut2y5/ofncTN0XQ5SjGjPYPouoAg/I24sTOy+bZmUpsGeVRc3yIR0q4ohVeTGf8mH70+GOeqD8WQUMZeAyE2OcPBpv7e70XfF2eHFhsjh9RgG3ncBdPAFunEroDSw+iscTIEv0TpgMx+qXV/Xg4ivkKcVicNI9h1n1OnCTcMX4DdUxaG1zDrxKov7uWw/4BlH83Wlx3JIzfa/2iOfx/UEsDBBQAAAAIAAAAIQCbEdLq+QkAADcRAAAeAAAAcmVmZXJlbmNlcy9tdWx0aS10YWItcG9saWN5Lm1kbVhbcxrJFX7nV3TKlaxNLN/W3nLscvYpD0mlklQ2yTNIAi9VMlJg5Kwr3ioQQoDEzboBAsmgRUgriUGyZHEXD/kn6+memSf/hXynGyTsssoFTE/3uX7nO6d9g/HqlijHzPqlXXn/sRf/h3vyYy9hbi1yPSk2zs3lCxEKi4MK31lxOMb3inyDZ9M8cyJKIa63RX7tQyhpllas902xvWfqIZ7a+BAK8/CWWuHVU5He/xBKQbbZXTS6Fx9CC1yP8GxS5C74atJqNsz1Uxwxe2u8nscPkQwb7ShPbhqtBPYbnRWzUzZ7ZRx0iNKx2IyZ3QKPdXimYRbPRXrPyvZ56YQUjJlttNKimRenJ9b+Io8X6LDjxg1mtEJQYXRDRjtOBoQKVmMP1o776HA4nWrV6fzY2zLXD0S8aZdCVi3MSwfYabQOeTxnVQ7uWo2aiESN9oqdOydvizu80Taj+wgp13dFKcWbeyoilr6LH1yviHKLAlTd4p2cvdYx9YqZXULwyUKn02ilxlTTidMFkhFtwicVeZKdOUTMzeIbGdswHnECronjih1NmX1dyTMrx3y5PO4adhoktizSCfbw3twPzD7K807NGuQt/Wej0+HFExF5I6PF41WxWcdRHoN9W7y2IHZKKhiItVhLGf0SsscvF+1Y0t59Y7bDyIqZPgEiKBDxExUkvpSyBkWeqZGB2xVg4WMvyU9OlZ8fe0XHuGj2u3u/ZiQ/d4GY8nAJIcdBhBzm29u70KWOX0XqKrWdJGIBJNNxXs8J/f0IwS6XSws6tFdzHkbvn7H/Ohibc2vfP2FBLeDzP3/Khn937zK+3oBCex1BTMIm4MdKRgBHRB+CFV7lYSQCRvDsEfv3vCfwitSa9aIdSvDMgthAnhLQovm0Gc/naqBF5C/NaodnZTAym1bscCj5hUdzY43cq4VF/JByEM+ybwDdQ3hlHtcg1Tc16//2C1JRE9Avj6eNy31RzvDiJVIIh6zYOa1fDoxOmg+O7NBbrm8Z/RRFwuf3e6afsMnZ2RmP26/kkbRiB3twSpy0YI+qJ+yfmpkNuifJrbET2G/XNpEks54AxvkgIvHWsPRL5nXPBD04OOMOav/yBX0aafPPv5j0BJ7KYMhki/iZCjksZH/++z/ZUOGPTymBVJU8eoa8mAttWR0uSoILPh/yZBRpAO4URqzOkdHtK6CpDKm83OXxJexQ6SLYuO7OBqY9geC3Qc2tzQefzbl907+Zcz/3PPsacleT7PMNAY933j+Nd511gA9kCJuy0EH4JGiRXUkHz9ZAOQrPYr1ttKoozCE0Tk55L4Q6oWJIr9qxFK+mVHlSwco9isb46Q7ioBziS1E7cqDWhz7JtxLNI29HBIfKD49TH2BKwfwtXlVRf9ZpmEcRmYQsCwcYECrVfru4hNrg0QMoI9HI2NXfL/HVIU4I55+/4f01nkiJQUicd7/0Or4lEmtwnApoUECwHCKZGIcD46kY72RQCebxsYrnMPsy9RMwftkuZPGeOZ2PnU64a/TTFAIURm8L5EW83O3y5cqQryUhWbtHwAw4BjRHm+/fYyhjFW/EglKxvyIODnn2jehu8eUDSh9j6jex0GinaKyLdxVRArRHK8Vze+sSyijyE0OsAshoTkybhWeEUN58R5jN1dEu0dRE6dDSB3ZOh2igVfUEGPXgIcDqgiB7u2B38+oIuQXz+2tU/pPzz5UexZWfZc1odcyfO0g0zMQG9liSRfQAAB0mDfkmookXqIjQjFrWRRTxlHjl7QuxvHwdlHhMpHYhcjwuxKS9zAhkvFiktiPNtCrAY8fheM1US2Cvmdldg43sNdYmJiawID/xpE7Y2zsKLxK+WL1+IGRn8sQCizWUuWojqDT1sk+tbUzQJ1IU+OBes2Yv4JuWKSIya2oR7qtdPHOGRxUTIrZ8Q1HXmGyab7Lp68qGBqt5BmvUThHfRFuGu2jIn5xKIMfGYBujDIoWExIyPXKz1zYruqVXRQX9NG7th9lUYH56gvgGH5rmCfiDsonUugCmWKmB/WGjFG+06or5eKw7kqfCr4JDnr7PWPtxXjgw2mURaSgqRSUAR6L0ll9GlSzVKtfHBy3q9U2xeTIkm6ziFcVxmAzQgSEMdUvD39gwIeuDiN7oNnmoJ8GhOi31jqUCj+6xoCcY9M36v9NmA3BTdUz0NTYzO+WeuVpNOD7ddyfo0f6oeV7c/Mo9/cLnv6O5J4Nf3WZ/+u6vf7mjep7P++omNXF680R+3vH6ZhDCmxp79nv2K+2OFnD7gz6PX7t1W3UnSvTIYxSf0TpHtaLulD80VaG03mZB1SJbMs9RAXU0JTkfUyN3T2m+l2h56vtvaD23HT/eujXsTRMMwWauT91wMYv0EL6Ya9xjF7hB1pjkuVHerqc00NJw1EtedRq1mbff8RjRKNJFBNHYHtLPyDP4hBpAS6zn5ZAC3pcjCL4VE8iSpzqr51W+MaqIlA4x6oe9XVaTCHoTlIgVjDObOGKHB+gbOGV0lqxBDJC6Okj6w7vUyHIXNLSUK/ZhUmxHQDBX87N6pHkg0keJQwjNFfIUuiHdHYaFYq3sgTVFrowTiiwJyXLQ54l1u1AluspkMTxdsVG0Tmw0ukvQ9IfbRX2PsqLaznDqU++hXcWJQL2yZxZ1BF69orCUZOtDy6LZFRhQtIlI8N2dIQXLwhvKNLpptdXc78I4tBpyIHpGKUK5SIaSGEryaJy5/O6XvuduDdCg+Vix0lJqdHYU5NEYrawSyRh4+KqVkGJ1oVIIxUyg7FKlRQ645oOeP3i9ninNxTAwI5jW4hvi+EYG8B4Pg41sLJcxnysSSdoLPxFfLC/jdvCQwXC6mRW6vL+B30b7rdrM011SycD052K5qqDpdJqFPgZatDSnE/yIS9T1RMsoxvoJgS/uogWqaRRuYJ6KQV5+1PQSobvS/pK1n8D0Iso9aix2pU18l9kEy3yhq1x1LnWXwRt5s5GsnNoY8TcRenWf6328v/8YGyj9F1HEmrk0zw/axOxLT8A7M/ufJ8wzM+ObC/qCLilDomEpal22reY22dGsoX+w+w9GOhTzJxP2qm5G6jzZwaYH9/6Xe3APKr4nsYAhSIAGfmWwbELIGzWVSFIUQA83vF6vC0XKOxs0fZFwo9W1Eu/gF5F7fPNqp8fjfYjNo9aAhvNlgQ+8X3sfYVsSV2bcHLD0cPLRo28w2kqz5XA/6iXNGq4Lw24nPcO9wV5NqNsDiciVx/1UEtBF13UrU6Ih5jWja994W0YPUI/RC6O7ef2YOYMq+Uhz5hDTo8sGgE09alw0dWeMyZ3a9d1zI26mY2gvPPMTbLtWLDVBxLB17R4BERgEjf6A2PmX0Dr+DScozAW47mKZYNA4F/nrqRD/yYCZGvcWS6/wyxyRQqNNCP0/UEsDBBQAAAAIAAAAIQBvRJkJgAkAAL8PAAAeAAAAcmVmZXJlbmNlcy9yZXNwb25zaXZlLXNoZWxsLm1kdVddUxpZGr7nV5yaVKoyzKBANDFuJrWp2andrZ2tvchW7V6C0GSoKFhgMtmaTBVoUFAEjKggmpHE+BUFzYdiI/hfkj6nu6/yF/Z5z2kxu5tNLG1Ov+d5v573gyuMlwq8eMg3l/nLt+bqU744z/UyPysaLZw3rW5XpLbN9jTPVl0usbYvlmes+iueybB7f/nzjz/2jYWZPZMXb+r8aImfpYBgT+3w7PSns1WxfGBOnpoHy+bSK0IuLlvZ+Y+ptHWc4Y0OPyqaS1Wz2oGwnaFzo7stNopiFq9yUt7R/jE16XJducKMVgpSCtVo6UY7ZZxmRaXJfF7/AOtnPv+Ql/4MDHhdLuUWYJQ8f5bnjYrZWTBa87yUB6T6qN5aJ7/xaRh1KgrPzFzWen/46SyvEHoCbvfHVN6a6gAAv0W5a7TmYJHR2oOhZnkHqqz6jtg4+5iad7sBIc1+whQAe8J4dlPMN/Bgtheths6e4KXH48HBZ79xJr15wlQ0mH/Ay75hyjp2c2gAhik1vLjHc7tsELgrhH6esettUT527kkkCsiXkXzeAe9nUE34w4YcKLGWMjqUfHhFidK3FBri+v/Q/F5CwxVQQOQ3eWEODLKaW2IqY6+/EOvnZGGxabRmGdnkYHzDbgwwu37cs/eWnzRcgN4YIlCjtQlx4PLtOVHp8u6KuYvgMT67ccGfQ3bdT+qzr3Gobiu7oc+uliS2f/DGZ9j+635p8PySVc+D0iA2WGmdzzDfkNdLNWFXMlazLZ6n7dUuxeTgJcR4Xie8m/KyE7u8DkYoLS63m9ixlaa/uqFPgzG9euKvOubaHMjB13ZUZvjhkZidvWB9RWRLvNYVGzMilQZ3pAjYzWef88y+uV+2GocwEzQzWm3xPo2ysbo7ZmEGpriQKZE9AbJ1XiVGOt7PGe158+mxvZaCUdCOUPFGXiy9s4pr8J08OljplZeOsrgszk9n2Q+5VzInn85yIlVAsalSVWFHiXWzfHPV0HVzfx+VwIvkKSw221UnCXkdCWGBseBjz8/R8MRPAeiChZCxy1V4gibRq9OL4iE7QRh6qC2IwjZiYk91lAtiZ4+XFpB/e+UdmY2smPUG9Yr0qni7BFy3W+RzpHd9BcaCEcgMzx673VDlcgUCgVAy6eoLxWMTWmyC/cLGg+FwNHbfE42NRmPaMGg9/vh37FfW+9fvZuRJdYcy20DRS0a5+119kXhizDMevK99y/qCiYloaFTzjMTD/wJqz+Fh4oqDSEjFPbGWU1zqh8PIAdnX6EjAieAIIBzEkXgwEZYf/hMvFo9pjoEAVEHrVyHjGSpXgoKfLpeH3ioNygqGQJmlabN8RHGX1DdaB9TQJfVN1PktsPJgBTkBqcy1M7M0xWvPRe61yDntDndUKRqdebPTMNDlKwUqy2JFZF5QTjxMWQP+PAjGRoIxsAfEVMYBRDSLaDMgJm/rVqNB/eBDahH1OP6Yigr0m9HVCFHZFu1VPrsjGwGVlpjLGWctIJCrH1Jl/DDnrFQgFmZX0J4V16lWzusi3QQ1rVRe1N7xwwVlI9+aFM/XVFcA2ZFWp5wBfPLGbBdhL6ywF3XRrlvnFaTN6FRhBVVsp2rPFMFyFCLk4WjAF0kE4Cc5kCJDqW7X0S5gzjQERS4FAMhejrLcfw08oNyWrR8wnw8/DF35Hk2BQMvooZiCeXXV2po2a8uq2NBZ6N6aLqpNsmP7KUa2aJbVXKbrtXdG65WsA18fc7vNp1sYTHb1xK4cyfpwFOUWSX7lGCCBvwdHAox398xCUxUSMqnEoPTTWY1n3torB4i8AgNZEHZre4sXF1CH9rMGOewnbSqNdhm98X9VIUQscJuK5w7UUcuIP9ISkdH4z8Psp2g4rMUQ3bxSRuLbbbu6STO8tAUnrak8fMaINtdTUCOdnxRPf6P+dCItuE4W2OmG2dmV6gOJ+yPBa95v6X/fwNcETtbPtJUKOKaEaSzor4l45zWGWDCuE3kJcoAgf0iGJJ7RbhudJVjGU3AEp/BCGSv9JPlBkg8EE9GgR3s8HoyFtXAAy4o6oX6UiI8mA243E/lJCjIivFFXMQQ5KRcQ0L77KhwNjsbvfxXA8FR3x+Lh4Oh3X00kHmo4dW5LtbhHmm+QZsTeLLcZ5vRYkkzOByYSwViSetgwk4+jwQntn9c8Pq/3qgpIeYcFxhNaREskPQkt/DCkhaFsIhqPQc3KsSjTEsaAJ0nttNbfj2mwkF378sVhpj5/zX5xMdaXjIa1kWAC3c558owEQw/Cifg4ep40KqpuOU3P9avqbCggXquhgOxyw6xVePPMyu7RqicXF2oSR7BITRZ7BlNpS81HNuS9Sk0Q1mOAIE44VhDEpdYUP0rZezvi+bFapozzdauZlgXjYaoU7LoOCuDIOnmLlqnywz5MP7tYaejR2WjosTcHoUBJOF2s3KU14A9/+yttWzw3jy2JT+P3Bvv+3j1kcQ/9FUmwJ1+ixVqNXck+pR2j0zg9Um3MaQNymsuE3Y4FH6GGQI7bD0edh+AdyqdSDCFqkhvTOA9HH7F4LDQaDT24Q5MZZlipDN/cxcpA/Se9iqpGlOn5xWtsQ2iUVpOGqtNDZWfpx85pvT/hByVlBpUXXEcFyNe4j48lUEaKqY8L/R+mFyGBsVCCYSl+NImaBkfp9Z/iY1r/DzGUB3qJvbXMD7vOXJE9RmycYJuSzg5H4qGHSc+jaDKKyUlOBuIPJ5xBjnmXjI9GAYMYOMeeeCSS1Cbk28uY9F4rokEvTZJ5fM0RtXOj/VJpVDao3NqvK7QVD96gQqB+I0OFJqkAEa0vdDBmvUyLAs0IWpDkToFNShrqbCGXm1iZwt48pfZNe1zBXjqHJqNzDr+JjWqFUPsb5FQH7F1gtLgN9A0O+zBV/vH93T8yf5+f3b2L0SKbpvzC12ph0JqFQxa4cuvWrQCYgKdIJIK4ZGkV8PcN0X2yl7zCMNqYUTEQ+3WisFQOYaub4bO7VvMdNgH6fiaLS2Tf0tYoC/LClEsKQlMoFCLOXXJYukBfOi9KRp1QuVYKcAqtnLZBOYLYwFXsDENXaY85afDNPeyhfAq1tUnLr16GCpoX6tXhAoYwzeRWxuqemkvyy1+rpcyI3IwMRYLkszIDRmPDVZFwgqEMUrEjBshUwEWVDTuNvWve1Jt2e0FZTBuy3sSG3IvQZWL8PhkItY/wrI4dSwGLkyMr98ZZhqVl3ojP5xsEayQokfiKNqjd1NCFLvf2fwNQSwECFAAUAAAACAAAACEAU+zcE48BAADkAQAADgAAAAAAAAAAAAAAAAAAAAAAQVRUUklCVVRJT04ubWRQSwECFAAUAAAACAAAACEARfLr64MCAAAyBAAABwAAAAAAAAAAAAAAAAC7AQAATElDRU5TRVBLAQIUABQAAAAIAAAAIQANmPELoRMAAKUmAAAIAAAAAAAAAAAAAAAAAGMEAABTS0lMTC5tZFBLAQIUABQAAAAIAAAAIQCbEdLq+QkAADcRAAAeAAAAAAAAAAAAAAAAACoYAAByZWZlcmVuY2VzL211bHRpLXRhYi1wb2xpY3kubWRQSwECFAAUAAAACAAAACEAb0SZCYAJAAC/DwAAHgAAAAAAAAAAAAAAAABfIgAAcmVmZXJlbmNlcy9yZXNwb25zaXZlLXNoZWxsLm1kUEsFBgAAAAAFAAUAPwEAABssAAAAAA==$b64$,
  'published'
)
on conflict do nothing;

insert into public.skills
  (slug, name, description, category, tags, version, license, author,
   readme, files, file_count, total_bytes, hash, bundle_b64, status)
values (
  'admin-empty-error-states', 'admin-empty-error-states', '处理后台的空状态、加载态与错误态时使用：首次无数据与筛选无结果的区分、骨架屏时机、局部失败与整页失败、错误文案与权限区分。', 'ui',
  array['后台管理', '空状态', '错误处理', '骨架屏', '局部失败', '权限不足', '错误文案']::text[], '1.0.0', 'MIT', 'Skill Hub',
  $md$---
name: "admin-empty-error-states"
description: "处理后台的空状态、加载态与错误态时使用：首次无数据与筛选无结果的区分、骨架屏时机、局部失败与整页失败、错误文案与权限区分。"
version: "1.0.0"
license: "MIT"
author: "Skill Hub"
category: ui
tags: ["后台管理", "空状态", "错误处理", "骨架屏", "局部失败", "权限不足", "错误文案"]
---

# 后台的空状态与错误处理

后台最常被跳过的三类界面是：**空、加载中、出错**。它们只占开发时间的 5%，
却出现在用户 30% 的会话里。做不好就三种后果：
看到空白以为系统坏了、看到转圈以为卡死了、看到「操作失败」不知道该找谁。

本技能把这三态拆成可判定的规则与可直接用的文案。

## 何时使用

- 列表页首次进入没有任何数据，页面一片空白
- 筛选后无结果，用户不知道是没数据还是筛选太严
- 接口慢或失败，用户看到全屏转圈或白屏
- 一个页面里某块数据（如统计卡片）加载失败，要不要整页报错
- 错误提示只写「请求失败」「系统错误」，用户不知道该重试还是找客服
- 需要区分「没权限看」和「资源不存在」

## 核心规则

1. **空状态分三种，文案和动作必须不同**：

   | 场景 | 标题 | 动作 |
   | --- | --- | --- |
   | 首次无数据 | 「还没有订单」 | 「新建订单」（主操作） |
   | 筛选无结果 | 「没有符合条件的订单」 | 「清空筛选条件」+ 回显条件 |
   | 搜索无结果 | 「没有找到「张伟」」 | 「清空搜索」+ 建议搜索范围 |

   **绝不能**三种都用「暂无数据」四个字。那等于告诉用户「我也不知道怎么了」。

2. **骨架屏延迟 200ms 出现，最快 400ms 后消失**。
   200ms 内返回的请求不显示骨架屏（否则会闪一下，比不显示更糟）；
   显示后至少停留 200ms 再消失，避免「闪一下又没了」。

3. **局部失败不整页报错**。页面上有 3 个独立数据块（统计卡、图表、表格），
   某一块失败只在**那一块**显示错误 + 重试按钮，其余正常渲染。
   整页报错会把已经加载成功的内容也一起藏起来。

4. **错误提示必须回答三个问题**：谁的问题、能不能重试、下一步做什么。
   「加载失败，请重试」只回答了第二个，不合格。
   合格示例：「订单列表加载失败（网络超时）。请检查网络后重试。」

5. **权限不足（403）与资源不存在（404）必须区分**：
   - 403：「你没有查看该订单的权限」+ 申请权限入口。**不要**伪装成 404。
   - 404：「订单不存在或已被删除」+ 返回列表。
   把 403 伪装成 404 会让人以为数据丢了，反而增加支持成本。

6. **加载态要保留布局**。用骨架屏占住真实内容的位置，而不是把内容替换成一句话，
   否则加载完成时页面会跳一下（布局偏移），长时使用很累。

7. **重试按钮必须真的重试**，且点击后立即进入 loading 态。
   点了没反应的重试按钮，比没有重试按钮更伤信任。

## 怎么做

### 第 1 步：先建立「三态」的判定树

```
请求开始
  ├─ 200 且有数据        → 正常渲染
  ├─ 200 但数据为空
  │    ├─ 无任何筛选/搜索  → 首次空状态（引导创建）
  │    └─ 有筛选/搜索      → 筛选空状态（回显条件 + 清空）
  ├─ 403                → 权限不足（申请权限）
  ├─ 404                → 资源不存在（返回列表）
  ├─ 4xx 其他           → 请求有误（提示具体原因，通常不该重试）
  ├─ 5xx                → 服务端错误（可重试 + 报错编号）
  └─ 网络错误/超时        → 网络问题（检查网络 + 重试）
```

**关键**：403/404 不要在 catch 里被当成通用错误吞掉。先按 `status` 分流，再决定 UI。

### 第 2 步：空状态的组件规格

```tsx
<EmptyState
  icon={<InboxIcon />}            // 64×64，颜色 #d0d5dd
  title="还没有订单"                // 16px / 600 / #101828
  description="创建第一笔订单后，这里会显示订单列表。"  // 14px / #667085
  action={<Button variant="primary">新建订单</Button>}
/>
```

- 容器垂直居中，上下留白 ≥ 64px，`min-height: 240px`。
- 图标 64px，**不要**用 200px 的巨型插画占满屏幕 —— 后台用户要的是「快速做下一件事」。
- 标题一行、说明最多两行。说明要讲「为什么空」和「接下来做什么」。
- 主操作最多 1 个，次操作最多 1 个（如「导入」）。三个以上按钮等于没有主操作。
- 空状态**必须**有一个动作。没有任何按钮的空状态 = 死胡同。

### 第 3 步：筛选无结果的特殊处理

```tsx
<EmptyState
  icon={<SearchXIcon />}
  title="没有符合条件的订单"
  description={
    <>
      当前筛选：状态 = 已付款，时间 = 近 7 天，负责人 = 张三。
      试试放宽条件或清空筛选。
    </>
  }
  action={<Button onClick={clearFilters}>清空筛选条件</Button>}
  secondary={<Button variant="text" onClick={openAdvancedFilter}>修改筛选</Button>}
/>
```

- **必须回显当前条件**，这是这一态区别于首次空状态的核心。
- 条件里如果只有一个，直接给「清掉这一个」的快捷按钮。
- 不要自动清空 —— 用户会以为自己的数据消失了。

### 第 4 步：加载态的选择

| 场景 | 用什么 | 原因 |
| --- | --- | --- |
| 首屏列表加载 | 表格骨架屏（3–5 行灰条） | 保留布局，无跳动 |
| 翻页/换筛选 | 表格区域半透明遮罩 + 小 spinner | 已有内容不必全抹掉 |
| 详情页加载 | 字段骨架屏（label + 值的灰条） | 同上 |
| 卡片/图表 | 对应形状的骨架块 | 位置稳定 |
| 按钮提交 | 按钮内 spinner + 禁用 | 反馈紧贴动作 |
| 局部下拉/联想 | 该项位置的小 spinner | 不要全屏遮罩 |
| 全屏路由切换 | 顶部 2px 进度条（可选） | 不要全屏 loading 页 |

```tsx
const showSkeleton = useDelayedLoading(isLoading, { delay: 200, minDuration: 200 });
```

实现要点：
- `delay: 200` —— 请求在 200ms 内完成就不显示骨架屏。
- `minDuration: 200` —— 一旦显示，至少显示 200ms，避免闪烁。
- 骨架屏用 `@keyframes` 做 1.5s 的渐变扫光，或用 CSS `animation` 的透明度呼吸，
  **不要**用 JS 定时器逐块闪烁。

### 第 5 步：局部失败 vs 整页失败

```
整页失败（整页渲染错误页）：
  - 页面主数据（列表/详情）加载失败
  - 无任何可展示的缓存内容
  - 鉴权失败（401）

局部失败（该块内显示错误 + 重试）：
  - 统计卡片中某一张失败
  - 图表失败但表格正常
  - 次要关联数据（如「该客户的最近 3 笔订单」）失败
```

局部错误块的规格：

```tsx
<ErrorBlock
  message="统计数据加载失败"
  detail="服务暂时不可用（错误码 5003）"
  onRetry={refetch}
/>
```

- 高度与该块原本的高度一致，避免整页抖动。
- 必须带「重试」按钮，且重试只重试这一块。
- 错误块用弱化的背景（`#fef3f2`）和边框，不要用刺眼的整块红色。

### 第 6 步：错误文案的三段式

**公式：谁的问题 + 发生了什么 + 下一步做什么。**

| 不合格 | 合格 |
| --- | --- |
| 请求失败 | 订单列表加载失败，请检查网络后重试 |
| 系统错误 | 服务暂时不可用，已记录（错误码 5003），请稍后重试 |
| 操作失败 | 保存失败：金额必须大于 0，请修改后重试 |
| 无权限 | 你没有查看该订单的权限，可向管理员申请 |
| 参数错误 | 提交的时间范围不合法（开始晚于结束），请重新选择 |

错误提示的结构：

```tsx
<Alert type="error" title="保存失败">
  金额必须大于 0，请修改后重试。
  <code>错误码 4001</code>
</Alert>
```

- **错误码要显示**（小字、可复制）。用户报障时说得出编号，支持效率翻倍。
- 网络类错误要**主动探测**：`navigator.onLine === false` 时提示「当前网络已断开」，
  而不是笼统的「请求失败」。
- 服务端返回的 `message` 如果是给开发者看的（如 SQL 片段），
  前端要**替换**成人话，不要直接透出。透出内部错误既是体验问题也是安全问题。
- 表单校验错误用**字段级**提示，不要弹全局 alert。全局 alert 用户还得自己找哪个字段错了。

### 第 7 步：权限不足与资源不存在

```ts
if (err.status === 403) return <NoPermission resource="订单" applyUrl="/settings/permissions" />;
if (err.status === 404) return <NotFound resource="订单" backTo="/orders" />;
```

| 状态 | 标题 | 说明 | 动作 |
| --- | --- | --- | --- |
| 401 | 登录已过期 | 请重新登录以继续 | 「重新登录」（保留当前 URL） |
| 403 | 无权访问 | 你没有查看该订单的权限 | 「申请权限」+「返回列表」 |
| 404 | 订单不存在 | 该订单不存在或已被删除 | 「返回订单列表」 |
| 410 | 已删除 | 该订单已被永久删除 | 「返回列表」 |

- **403 不要伪装成 404**。安全上有人主张「不暴露资源存在性」，
  但那适用于**公开 API**。后台内部系统里，让员工知道「你没权限」远比
  「东西不见了」更省支持成本。
- 401 跳登录时**保留当前 URL**（`?redirect=/orders/1024`），登录后回到原位。
- 404 页面不要只放一个「404」数字，要给「回列表」的出口。

## 检查清单

- [ ] 空状态区分「首次无数据」「筛选无结果」「搜索无结果」三种文案
- [ ] 每种空状态都有至少一个可点动作，没有死胡同
- [ ] 筛选空状态回显当前条件，并提供清空入口
- [ ] 骨架屏延迟 200ms 出现，最短停留 200ms，避免闪烁
- [ ] 加载态保留布局（骨架屏形状与真实内容一致），无布局偏移
- [ ] 翻页/换筛选用局部 loading，不抹掉已有内容
- [ ] 按钮提交用按钮内 spinner + 禁用，不用全屏遮罩
- [ ] 局部失败只在失败块内显示错误 + 重试，不整页报错
- [ ] 每个错误块都有可用的重试按钮，点击后立即进入 loading
- [ ] 错误文案回答「谁的问题 / 能不能重试 / 下一步做什么」三问
- [ ] 显示错误码，且服务端技术性 message 不透出给用户
- [ ] 表单校验用字段级提示，不用全局 alert
- [ ] 401 / 403 / 404 / 5xx / 网络错误分别有不同 UI
- [ ] 401 跳登录保留原 URL，登录后回到原位
- [ ] 403 与 404 不混淆，403 有申请权限入口
- [ ] 离线时提示「网络已断开」而非「请求失败」

## 常见错误

| 错误做法 | 为什么错 | 正确做法 |
| --- | --- | --- |
| 所有空状态都写「暂无数据」 | 用户分不清是没数据还是筛选太严 | 三种空状态三套文案与动作 |
| 空状态只有插画没有按钮 | 死胡同，用户不知道下一步 | 至少给一个主操作 |
| 200px 巨型插画占满屏幕 | 后台用户要的是快速做下一件事 | 图标 64px，留白 ≥ 64px |
| 骨架屏立刻显示 | 快请求会闪一下，比不显示更糟 | 延迟 200ms + 最短 200ms |
| 加载时把内容替换成一句话 | 加载完成时布局跳动，长时使用很累 | 骨架屏占住真实位置 |
| 翻页时整页 loading 遮罩 | 屏幕闪一下，已有内容被抹掉 | 表格区局部 loading |
| 一个卡片失败就整页报错 | 把已加载成功的内容也藏起来 | 局部错误块 + 局部重试 |
| 重试按钮点了没反应 | 比没有重试按钮更伤信任 | 点击立即进入 loading 并重新请求 |
| 错误只写「操作失败」 | 用户不知该重试还是找客服 | 三段式文案 + 错误码 |
| 透出后端原始报错 | 体验差且有安全风险 | 替换成人话，错误码另附 |
| 表单错误弹全局 alert | 用户还得自己找哪个字段错 | 字段级 inline 提示 |
| 403 伪装成 404 | 用户以为数据丢了，增加支持成本 | 明确提示无权 + 申请入口 |
| 401 跳登录丢原 URL | 登录后回不到刚才的页面 | 带 `redirect` 参数并还原 |
| 把超时当「服务端错误」 | 文案误导，用户去骂后端 | 按 status / error type 分流 |
| 错误提示自动消失 | 用户没看清就没了，无法复制错误码 | 错误常驻直到用户处理 |

## 参考

- 需要完整的错误分类与文案库（HTTP 状态、业务错误码、网络错误、表单错误的措辞模板）时，读 `references/error-copywriting.md`
- 需要骨架屏的实现细节（不同组件的骨架形状、扫光动画、延迟与最短展示时长的封装、避免布局偏移）时，读 `references/loading-and-skeleton.md`
$md$,
  '[{"path":"ATTRIBUTION.md","size":484,"kind":"text"},{"path":"LICENSE","size":1074,"kind":"text"},{"path":"SKILL.md","size":13013,"kind":"text"},{"path":"references/error-copywriting.md","size":6619,"kind":"text"},{"path":"references/loading-and-skeleton.md","size":6040,"kind":"text"}]'::jsonb, 5, 27230, 'c7c1c43bb13e2b0cf5d5dce5a836c4f953cbd319e21d01cec5c6965fbe6f70c2',
  $b64$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$b64$,
  'published'
)
on conflict do nothing;

insert into public.skills
  (slug, name, description, category, tags, version, license, author,
   readme, files, file_count, total_bytes, hash, bundle_b64, status)
values (
  'crud-page-patterns', 'crud-page-patterns', '设计后台的列表页、详情页、新建/编辑页时使用：三者跳转关系、抽屉弹窗独立页的取舍、必填标记、未保存拦截与批量操作位置。', 'ui',
  array['后台管理', 'CRUD', '抽屉交互', '表单校验', '未保存拦截', '批量操作', '页面模式']::text[], '1.0.0', 'MIT', 'Skill Hub',
  $md$---
name: "crud-page-patterns"
description: "设计后台的列表页、详情页、新建/编辑页时使用：三者跳转关系、抽屉弹窗独立页的取舍、必填标记、未保存拦截与批量操作位置。"
version: "1.0.0"
license: "MIT"
author: "Skill Hub"
category: ui
tags: ["后台管理", "CRUD", "抽屉交互", "表单校验", "未保存拦截", "批量操作", "页面模式"]
---

# CRUD 页面模式

一个后台 80% 的代码量在 CRUD。它的问题从来不是「能不能写出来」，而是
**同一份字段定义、同一份校验规则、同一份展示逻辑，在列表页、详情页、编辑页被抄了三遍**，
然后某天产品说要给「金额」加一位小数，你改了列表忘了改详情，线上开始出现对不上的数字。

本技能给出三个页面的职责边界、跳转关系，以及消灭重复实现的落地做法。

## 何时使用

- 从零设计一个实体的增删改查流程（列表 → 详情 → 编辑）
- 团队在争论「编辑该用抽屉、弹窗还是独立页面」
- 出现了「列表里改完，详情页还是旧数据」这类一致性问题
- 用户抱怨「填了半天的表单，点错一下全没了」
- 字段一多（> 12 个）表单就开始失控、分组混乱、必填标记满屏
- 列表页的批量操作按钮不知道该放哪，用户总是找不到

## 核心规则

1. **三个页面各有明确职责，不要混用**：
   - **列表页**：只做「浏览 + 定位 + 触发动作」，不直接编辑数据。
   - **详情页**：只读呈现全量字段 + 关联数据 + 操作入口。
   - **新建/编辑页**：唯一的写入口，承载校验与提交。

2. **表单容器按字段数决定**，不要按个人喜好：

   | 字段数 | 容器 | 理由 |
   | --- | --- | --- |
   | 1–4 | 弹窗（Modal） | 一次对话能看完，独立页太重 |
   | 5–12 | 抽屉（Drawer，宽 480–560） | 保留列表上下文，可滚动 |
   | > 12 或含富文本/表格 | 独立页面 | 抽屉塞不下，嵌套滚动体验差 |

3. **必填标记只标「非必填」或只标「必填」，二选一，全站统一**。
   推荐**只标必填**（字段名前一个红色 `*`），因为必填通常是少数。
   如果反过来必填占 90%，那就标「选填」。满屏红星星等于没有标记。

4. **保存与取消的语义必须固定**：
   - 「保存」= 提交并关闭（回到列表，刷新对应行）；「保存并继续」= 提交但不关闭（连续录入场景才提供）。
   - 「取消」= 丢弃改动并关闭，**不提交**。
   - 有未保存改动时，「取消」和「关闭（×）」都要**拦一次**确认，不要静默丢弃。

5. **批量操作条只在选中 ≥ 1 行时出现**，位置固定在表格上方（不是下方），
   显示「已选 N 项」+ 操作按钮 + 「取消选择」。选中数 ≥ 1 才可用，0 项时整条隐藏。

6. **同一份数据只定义一次**。字段的 key、label、类型、校验、格式化必须来自**一个 schema**，
   列表列、详情展示、表单控件都从它派生。这是本技能最重要的一条。

7. **列表页的行内操作 ≤ 3 个**（如「详情 / 编辑 / 删除」），更多动作收进「⋯」下拉。
   行内放 6 个文字按钮会把操作列撑到 400px，主列被挤没。

## 怎么做

### 第 1 步：先写 schema，再写页面

```ts
// schema/order.ts —— 唯一事实来源
export const orderSchema = {
  id:        { label: '订单号', type: 'text',   inList: true,  inForm: false, inDetail: true },
  customer:  { label: '客户',   type: 'text',   inList: true,  inForm: true,  inDetail: true,
               required: true, max: 40 },
  amount:    { label: '金额',   type: 'money',  inList: true,  inForm: true,  inDetail: true,
               required: true, min: 0.01, precision: 2, align: 'right' },
  status:    { label: '状态',   type: 'enum',   inList: true,  inForm: true,  inDetail: true,
               options: ORDER_STATUS, required: true },
  remark:    { label: '备注',   type: 'longtext', inList: false, inForm: true, inDetail: true, max: 500 },
  createdAt: { label: '创建时间', type: 'datetime', inList: true, inForm: false, inDetail: true,
               format: 'yyyy-MM-dd HH:mm' },
} as const;
```

三个页面都从这个 schema 生成：

- 列表列 = `Object.entries(orderSchema).filter(([,v]) => v.inList)`
- 表单字段 = `filter(v => v.inForm)`
- 详情字段 = `filter(v => v.inDetail)`
- 校验规则 = 由 `required / min / max / precision` 统一生成，三处共用

**代价说明**：schema 驱动在字段 < 5 个时会显得「过度设计」。
如果这个实体永远只有 3 个字段、且永远不会有详情页，直接写三遍更快。
但只要字段 > 8 或已经有三个页面，schema 就是净收益。

### 第 2 步：定跳转关系

```
列表页 ──点击行/详情──▶ 详情页 ──编辑──▶ 编辑页（独立或抽屉）
   │                        │
   ├──新建──▶ 新建页        └──返回──▶ 详情页（带最新数据）
   └──行内「编辑」────────▶ 编辑抽屉（保留列表上下文）
```

- **从列表直接编辑**用抽屉：用户改完还要继续看列表，跳走再回来会丢筛选和分页位置。
- **从详情编辑**：字段少用抽屉，字段多用独立页（详情页本身已经很长，再叠抽屉会双层滚动）。
- **新建**：字段 ≤ 12 用抽屉，> 12 用独立页。新建不需要「返回上一页」的上下文，独立页反而清爽。

### 第 3 步：表单分组与布局

- 字段 ≤ 6：单列，字段间距 20px。
- 字段 7–12：单列，按语义分 2–3 组，组间间距 32px，组标题 14px/600。
  分组依据是**业务语义**（基本信息 / 联系方式 / 权限设置），不是「前 6 个 / 后 6 个」。
- 字段 > 12：独立页，两列网格，`grid-template-columns: repeat(2, minmax(0, 1fr))`，
  `gap: 20px 24px`。跨列字段（备注、地址）用 `grid-column: 1 / -1`。
- label 位置：单列时**顶部对齐**（`label` 在 `input` 上方，间距 6px）；
  两列网格也用顶部对齐，不要用「label 左、input 右」——后者要求 label 固定宽度，
  中文长短不一，对齐起来很难看且窄屏会崩。
- 输入框高度 32（紧凑）/ 36（默认）/ 40（宽松），全站统一取一档。触屏 ≥ 44。

### 第 4 步：必填与校验时机

- 必填标记：label 后跟 `<span aria-hidden="true">*</span>`，颜色 `#d92d20`。
  同时给 input 加 `required` 与 `aria-required="true"`，读屏用户才知道。
- **校验时机**：字段失焦（blur）时校验该字段；提交时校验全部。
  不要在 `input` 事件里边打字边报错 —— 用户还没输完就飘红，体验很差。
- 错误文案位置：字段下方，字号 12，颜色 `#d92d20`，与字段间距 4px。
- 错误时 input 边框 `1px solid #d92d20` + `aria-invalid="true"`，并 `aria-describedby` 指向错误文案 id。
- 提交失败时：滚动到**第一个**出错字段并聚焦它，同时顶部给一条汇总提示「有 3 处需要修改」。
  只飘红不滚动，用户以为没反应。

### 第 5 步：未保存离开拦截

```ts
// 1) 表单脏检查
const isDirty = useMemo(
  () => JSON.stringify(formValues) !== JSON.stringify(initialValues),
  [formValues, initialValues]
);

// 2) 浏览器级拦截（刷新 / 关标签）
useEffect(() => {
  if (!isDirty) return;
  const handler = (e: BeforeUnloadEvent) => { e.preventDefault(); e.returnValue = ''; };
  window.addEventListener('beforeunload', handler);
  return () => window.removeEventListener('beforeunload', handler);
}, [isDirty]);

// 3) 应用内路由拦截
useBlocker(({ currentLocation, nextLocation }) =>
  isDirty && currentLocation.pathname !== nextLocation.pathname
);
```

- 应用内拦截弹确认框：「有未保存的修改，确定离开吗？」按钮为「继续编辑 / 放弃修改」。
  按钮文案要写动作，不要写「确定 / 取消」——用户不知道「确定」是确定离开还是确定留下。
- **只拦「有改动」的情况**。用户打开表单没动任何东西就关，不该被拦，那是纯骚扰。
- 多标签页场景：关闭带未保存内容的 Tab 也要走同一套拦截（见 admin-dashboard-layout）。

### 第 6 步：保存后的数据一致性

保存成功后，**不要**只关掉表单就完事。至少做其中一件：

1. 让列表页重新拉取当前页数据（最简单，代价是一次请求）。
2. 用返回的实体直接**原地更新**列表里对应那一行（更快，但要保证接口返回完整字段）。
3. 若该实体的详情页在缓存中，一并失效。

**反面教材**：保存后只关闭抽屉，列表还是旧值。用户看到「我明明改了」，
于是再点一次编辑，发现表单里是新值 —— 信任瞬间崩塌。

## 检查清单

- [ ] 三个页面（列表/详情/编辑）职责边界清晰，列表页不做内联编辑
- [ ] 字段定义只有一份 schema，列表列、表单、详情、校验都从它派生
- [ ] 表单容器按字段数选择：1–4 弹窗、5–12 抽屉、> 12 独立页
- [ ] 必填标记全站统一（只标必填 或 只标选填），且带 `aria-required`
- [ ] 字段 > 6 时按业务语义分组，组间 32px
- [ ] 校验在 blur 触发、提交时全量校验，不在输入过程中飘红
- [ ] 提交失败滚动并聚焦第一个错误字段，顶部有汇总提示
- [ ] 「保存 / 保存并继续 / 取消」语义全站一致
- [ ] 有改动时，关闭、取消、切路由、关标签都会被拦截；无改动不拦
- [ ] 保存成功后列表数据同步刷新或原地更新，不出现「改了没变」
- [ ] 批量操作条仅在选中 ≥ 1 行时出现，位置在表格上方，含「取消选择」
- [ ] 行内操作 ≤ 3 个，其余收进「⋯」菜单
- [ ] 抽屉/弹窗支持 `Esc` 关闭（有未保存时先拦截）
- [ ] 删除操作二次确认，文案含实体名称（「确定删除订单 1024？」）

## 常见错误

| 错误做法 | 为什么错 | 正确做法 |
| --- | --- | --- |
| 列表、详情、表单各写一份字段 | 改一处忘两处，线上数据对不上 | 单一 schema 派生三处 |
| 列表页做行内直接编辑 | 校验无处安放，误触即改数据 | 编辑走抽屉/独立页，列表只读 |
| 编辑一律用弹窗 | 12 个字段塞进弹窗，内部滚动 + 页面滚动双层 | 按字段数选容器 |
| 满屏必填红星 | 标记失去区分度，等于没标 | 只标必填（或只标选填） |
| 打字时实时报错 | 用户还没输完就飘红，体验差 | blur 时校验该字段 |
| 提交失败只飘红不滚动 | 错误在屏幕外，用户以为没反应 | 滚动 + 聚焦第一个错误字段 |
| 未保存直接关闭不拦截 | 用户填了 20 分钟的表单瞬间蒸发 | 脏检查 + beforeunload + 路由拦截 |
| 无改动也弹拦截 | 纯骚扰，用户开始无脑点「确定」 | 仅在有改动时拦截 |
| 保存后只关抽屉 | 列表仍显示旧值，用户以为没保存 | 刷新列表或原地更新该行 |
| 批量操作按钮放表格下方 | 表格长时按钮在屏幕外，用户找不到 | 固定在表格上方，选中即出现 |
| 行内堆 6 个操作按钮 | 操作列撑到 400px，主列被挤没 | 保留 ≤ 3 个，其余进「⋯」 |
| 删除确认只写「确定/取消」 | 用户不清楚在确认什么 | 文案含实体名与动作 |
| 详情页和编辑页各拉一次接口 | 两份数据可能不一致，切换时闪 | 共用同一份数据源 / 缓存 |

## 参考

- 需要完整的未保存拦截实现（路由 blocker、多标签页、抽屉、嵌套表单的脏值冒泡）时，读 `references/unsaved-changes-guard.md`
- 需要 schema 驱动方案的字段类型清单、校验规则映射、以及「什么时候不该用 schema」的判断时，读 `references/schema-driven-crud.md`
$md$,
  '[{"path":"ATTRIBUTION.md","size":484,"kind":"text"},{"path":"LICENSE","size":1074,"kind":"text"},{"path":"SKILL.md","size":12093,"kind":"text"},{"path":"references/schema-driven-crud.md","size":5303,"kind":"text"},{"path":"references/unsaved-changes-guard.md","size":5235,"kind":"text"}]'::jsonb, 5, 24189, 'b6a2eb3d7eaa3dfeaaadcb095c679125ebf36ba0336a7b3dd335c484e0b2e068',
  $b64$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$b64$,
  'published'
)
on conflict do nothing;

insert into public.skills
  (slug, name, description, category, tags, version, license, author,
   readme, files, file_count, total_bytes, hash, bundle_b64, status)
values (
  'data-table-design', 'data-table-design', '设计后台数据表格时使用：列宽策略、排序与多列排序、固定表头与固定列、行高密度切换、分页与虚拟滚动选型、长文本与空值显示。', 'ui',
  array['后台管理', '数据表格', '虚拟滚动', '固定列', '列宽策略', '分页', '排序']::text[], '1.0.0', 'MIT', 'Skill Hub',
  $md$---
name: "data-table-design"
description: "设计后台数据表格时使用：列宽策略、排序与多列排序、固定表头与固定列、行高密度切换、分页与虚拟滚动选型、长文本与空值显示。"
version: "1.0.0"
license: "MIT"
author: "Skill Hub"
category: ui
tags: ["后台管理", "数据表格", "虚拟滚动", "固定列", "列宽策略", "分页", "排序"]
---

# 数据表格设计

表格是后台使用频率最高的组件，也是最容易被做坏的。坏法高度统一：
**列宽写死、长文本撑破、数字左对齐、10 万行直接渲染卡死、切个筛选条件就滚回顶部**。
本技能给出每一处的可量化标准与选型判据。

## 何时使用

- 设计后台列表页的表格（订单、用户、工单、日志、商品）
- 表格出现横向滚动条，且滚到右边就忘了行对应谁
- 数据量大（> 2000 行）导致卡顿、白屏、滚动掉帧
- 产品要求「像 Excel 一样能排序、能筛选、能调列宽」
- 长文本（备注、地址、标题）把行高顶得参差不齐
- 需要决定「到底用分页还是无限滚动」

## 核心规则

1. **列宽按「主列自适应 + 其余固定」**。主列（名称/标题）设 `min-width: 200px` 且参与剩余空间分配，
   其余列固定 px。**所有列都写死 px 的表格，在 2560 屏上会出现一大片空白**。

2. **数值列右对齐 + `font-variant-numeric: tabular-nums`**。
   等宽数字让「1234.5」和「89.01」的小数点对齐，用户才能纵向比大小。左对齐的数字是没法扫读的。

3. **行高分三档，全站取一档作为默认**：紧凑 `32px` / 默认 `40px` / 宽松 `48px`。
   触屏场景最小 `48px`。行高用 `height` + 垂直居中实现，**不要用 padding 撑** ——
   单元格里有换行文本时 padding 会把整行顶高，行高参差不齐。

4. **固定表头是默认，不是可选项**。表头 `position: sticky; top: 0`，背景必须**不透明**，
   否则滚动时行内容从表头下面透出来。固定列的 `z-index` 要高于普通列，且固定列要有阴影或边框分隔。

5. **渲染方案按行数选**，不要一套走天下：

   | 行数 | 方案 |
   | --- | --- |
   | ≤ 200 | 直接渲染 + 客户端分页 |
   | 200–2000 | 虚拟滚动（只渲染视口 ± 10 行） |
   | > 2000 | 服务端分页，每页 20 / 50 / 100 三档 |
   | 时间倒序流式数据 | 无限滚动（仅此场景） |

6. **排序支持多列**，但 UI 上主推单列。`Shift + 点击` 追加第二排序键，
   表头显示 `↑1` `↑2` 这样的序号。没有序号的多列排序，用户不知道谁优先。

7. **列设置的改动要持久化**（列顺序、列显隐、列宽、密度）到 `localStorage`，按用户 + 表名作 key。
   每次进页面都要重调一遍列宽，是用户放弃使用列设置功能的直接原因。

## 怎么做

### 第 1 步：定表格基础样式

```css
.table-wrap { overflow: auto; max-height: calc(100vh - 320px); }
table { table-layout: fixed; width: 100%; border-collapse: separate; border-spacing: 0; }
th, td {
  height: 40px; padding: 0 16px;
  text-align: left; vertical-align: middle;
  white-space: nowrap; overflow: hidden; text-overflow: ellipsis;
}
thead th {
  position: sticky; top: 0; z-index: 2;
  background: #fafafa;             /* 必须不透明 */
  font-weight: 600; font-size: 13px; color: #4b5563;
  border-bottom: 1px solid #e5e7eb;
}
tbody tr:nth-child(even) { background: #fcfcfd; }   /* 斑马纹，密度高时帮助横向对齐 */
tbody tr:hover { background: #f5f7fa; }
tbody tr[aria-selected="true"] { background: #eef4ff; box-shadow: inset 3px 0 0 var(--primary); }
td.num { text-align: right; font-variant-numeric: tabular-nums; }
```

- `border-collapse: separate` 是固定表头能生效的前提之一（`collapse` 下部分浏览器的 sticky 边框会错位）。
- 斑马纹与 hover 二选一时优先 hover；两者都有也可以，但斑马纹对比度要很弱（`#fcfcfd`）。
- 行选中态用**背景色 + 左侧主色条**双保险，只有背景色时，hover 和选中容易混淆。

### 第 2 步：列宽策略

三种策略，按列的角色选，不要全用一种：

| 策略 | 适用列 | 实现 |
| --- | --- | --- |
| 固定宽 | 状态、时间、金额、操作 | `width: 96px` 等 |
| 自适应（弹性） | 名称、标题、描述 | `width: 28%; min-width: 200px` |
| 拖拽可调 | 用户要求自定义时 | 表头右缘 8px 拖拽热区，`min-width` 限制 |

常见列的推荐宽度（13px 字体）：

| 列 | 宽度 |
| --- | --- |
| 复选框 | 40 |
| 序号 | 56 |
| 状态标签 | 88–112 |
| `yyyy-MM-dd HH:mm:ss` | 168 |
| `yyyy-MM-dd` | 120 |
| 金额（带千分位） | 120，右对齐 |
| 操作（1 个） | 88 |
| 操作（2–3 个图标） | 120 |
| 操作（文字按钮 3 个） | 180 |

- 拖拽调宽要**记住用户改过的宽度**，并允许「恢复默认列宽」。
- 拖拽时给一条 2px 的垂直指示线，松开才应用；实时应用会让拖拽过程中列内容频繁重排、卡顿。
- 所有列设 `min-width`，否则用户能把主列拖到 20px 宽，内容完全不可见。

### 第 3 步：固定表头与固定列

```css
/* 固定表头 */
thead th { position: sticky; top: 0; z-index: 3; }

/* 固定左侧第一列（如复选框 + 名称） */
th.col-fix-left, td.col-fix-left {
  position: sticky; left: 0; z-index: 2;
  background: inherit;               /* 关键：跟随行的背景，否则 hover 时固定列不变色 */
  box-shadow: 1px 0 0 #e5e7eb;
}
thead th.col-fix-left { z-index: 4; }  /* 左上角交叉处最高 */

/* 固定右侧操作列 */
th.col-fix-right, td.col-fix-right {
  position: sticky; right: 0; z-index: 2;
  background: inherit;
  box-shadow: -1px 0 0 #e5e7eb;
}
```

三个必踩的坑：
1. **固定列背景必须跟着行背景走**。写死 `background: #fff` 后，hover 行时固定列不变色，
   视觉上像是两行。用 `background: inherit` 或在 hover 规则里显式覆盖固定列。
2. **固定列会遮住滚动过去的内容**，所以要给 `box-shadow` 或 1px 边框做视觉分隔。
   更好的做法是「滚动到有内容被遮住时才显示阴影」，用 IntersectionObserver 或 scroll 事件判断。
3. **`z-index` 分层**：普通单元格 1 < 固定列 2 < 表头 3 < 左上角交叉 4。

### 第 4 步：排序与多列排序

```ts
type Sort = { key: string; dir: 'asc' | 'desc' };
// 单列：点击表头循环 升 → 降 → 取消
// 多列：Shift + 点击追加，最多 3 列
```

- 表头显示当前排序：升序 `↑`、降序 `↓`、未排序显示一个淡的上下双箭头（hover 时加深）。
- 多列时在箭头后跟序号 `↑1`、`↑2`，明确优先级。
- 排序在**服务端**做（大数据量）；客户端排序只在 ≤ 200 行且无分页时用。
- 切换排序时**保持当前页码**还是回到第 1 页？回到第 1 页更符合直觉 ——
  第 5 页在新排序下可能根本不存在，会出现空列表。
- 排序状态要能**清空**（第三次点击），否则用户被锁在某个排序里出不来。

### 第 5 步：分页 / 无限滚动 / 虚拟滚动选型

| 方案 | 适用 | 代价 |
| --- | --- | --- |
| 分页 | 需要定位到具体行、需要「共 N 条」、需要跳页 | 每页一次请求，翻页有延迟 |
| 无限滚动 | 时间倒序的流式数据（日志、动态、消息） | 无法跳页、无法回到原位、总条数不明 |
| 虚拟滚动 | 单页内行数多（500–2000）但不需要翻页 | 行高必须固定，打印/搜索定位失效 |

- **分页每页条数给 20 / 50 / 100 三档**，默认 20。给 10 太碎，给 500 会让单次请求超时。
- 分页器要显示「共 N 条」和「第 X / Y 页」，并提供「跳至第 N 页」输入框（页数 > 10 时才有必要）。
- **无限滚动的替代方案**：优先考虑「加载更多」按钮而不是自动加载 ——
  自动加载会让用户永远够不到页脚，也无法「记住我停在哪」。
- 虚拟滚动的三条硬约束：① 行高固定；② 表头用独立 `<div>`（不能用 `<thead>`，否则无法与滚动容器分离）；
  ③ 键盘上下移动时手动 `scrollIntoView({ block: 'nearest' })`。
- **切换筛选/排序/分页后必须回到列表顶部**，否则用户看到的是新数据的中段，一脸茫然。

### 第 6 步：长文本、空值与超长数字

- **长文本**：默认单行截断 + `title` 属性。提供「展开」交互（点击单元格或行尾小箭头），
  展开后该行变为多行（`white-space: normal`），行高自适应。不要用 tooltip 承载长文本 ——
  tooltip 无法复制、无法滚动、鼠标移开就没了。
- **空值**：统一显示 `—`（em dash）或 `-`，**不要留空**。留空会让用户以为是加载失败。
  全站统一用一种符号。
- **超长数字**（如 19 位订单号、大额金额）：不要截断，用 `tabular-nums` 完整显示，
  必要时缩字号到 12px。截断数字比截断文字更危险 —— 用户会照着残缺的数字去核对。
- **超出范围的金额**：`1.2e9` 这种科学计数法要转成「12.0 亿」或完整千分位，不要直接显示 `1.2e+9`。

### 第 7 步：列设置的持久化

```ts
const key = `table.${tableName}.${userId}`;
localStorage.setItem(key, JSON.stringify({
  order: ['customer', 'amount', 'status'],   // 列顺序
  hidden: ['remark'],                        // 隐藏的列
  widths: { customer: 260, amount: 120 },    // 用户拖拽后的宽度
  density: 'default',                        // 密度档位
  pageSize: 50,
}));
```

- 版本化 key（如 `table.orders.v2`），列结构变更时能整体失效，避免旧配置和新列对不上。
- 提供「重置为默认」按钮，一键清掉这个 key。
- 列设置面板里要有**拖拽排序**，且「必显示列」（如复选框、操作列）不可隐藏、不可移动。

## 检查清单

- [ ] 主列自适应 + `min-width`，其余列固定宽，2560 屏无大片空白
- [ ] 数值列右对齐，使用 `tabular-nums`
- [ ] 行高从 32/40/48 三档中取一档，用 `height` 而非 padding
- [ ] 表头吸顶且背景不透明，滚动时无内容透出
- [ ] 固定列背景跟随行背景，有阴影/边框分隔，`z-index` 分层正确
- [ ] 排序状态可见（箭头 + 多列序号），可清空，切换排序回到第 1 页
- [ ] 渲染方案与行数匹配：≤200 直渲、200–2000 虚拟滚动、>2000 服务端分页
- [ ] 虚拟滚动行高固定，表头独立于滚动容器
- [ ] 长文本默认截断 + 可展开，不是只有 tooltip
- [ ] 空值统一显示为 `—`，不留白
- [ ] 超长数字完整显示，不用科学计数法
- [ ] 列顺序 / 显隐 / 宽度 / 密度 / 每页条数都持久化，且可重置
- [ ] 切换筛选、排序、分页后滚动回列表顶部
- [ ] 键盘可用：`↑/↓` 移动选中行，`Space` 勾选，`Enter` 打开详情
- [ ] 表格区域有独立 loading（骨架屏延迟 200ms），不是整页转圈

## 常见错误

| 错误做法 | 为什么错 | 正确做法 |
| --- | --- | --- |
| 所有列宽写死 px | 大屏右侧大片空白，小屏挤压变形 | 主列 `1fr` + `min-width`，其余固定 |
| 数字左对齐 | 位数不同无法纵向比较 | 右对齐 + `tabular-nums` |
| 用 `padding` 撑行高 | 换行文本把行顶高，行高参差 | 用 `height` + 垂直居中 |
| 表头背景半透明 | 滚动时行内容从表头下透出，糊成一片 | 表头用不透明背景 |
| 固定列写死白背景 | hover 时固定列不变色，像两行 | 背景 `inherit` 或显式覆盖 hover |
| 10 万行直接渲染 | 首屏卡死、滚动掉帧 | 虚拟滚动或服务端分页 |
| 虚拟滚动用变高行 | 需动态测量，滚动白屏跳动 | 虚拟滚动强制固定行高 |
| 多列排序不显示序号 | 用户不知道哪个是主排序键 | 表头显示 `↑1` `↑2` |
| 长文本只用 tooltip | 无法复制、无法滚动、移开即消失 | 单元格内展开为多行 |
| 空值留白 | 用户以为是加载失败或数据缺失 | 统一显示 `—` |
| 大额金额显示 `1.2e+9` | 用户看不懂，无法核对 | 千分位或中文单位 |
| 列设置不持久化 | 每次都要重调，用户直接放弃该功能 | localStorage 持久化 + 可重置 |
| 切换筛选后不回到顶部 | 用户看到新数据的中段，误判为空 | 数据变化时 `scrollTop = 0` |
| 整页 loading 遮罩 | 每次翻页屏幕闪一下，长时间使用很累 | 表格区局部骨架屏 |
| 无限滚动自动加载 | 用户永远够不到页脚，无法记录位置 | 优先用「加载更多」按钮 |

## 参考

- 需要虚拟滚动的具体实现（固定行高算法、动态测量降级方案、表头与滚动容器分离、与固定列共存）时，读 `references/virtual-scroll-and-fixed-columns.md`
- 需要分页 / 无限滚动 / 游标分页的服务端配合、总条数估算、以及「跳页 + 深分页」的性能取舍时，读 `references/pagination-strategies.md`
$md$,
  '[{"path":"ATTRIBUTION.md","size":484,"kind":"text"},{"path":"LICENSE","size":1074,"kind":"text"},{"path":"SKILL.md","size":13182,"kind":"text"},{"path":"references/pagination-strategies.md","size":5264,"kind":"text"},{"path":"references/virtual-scroll-and-fixed-columns.md","size":5500,"kind":"text"}]'::jsonb, 5, 25504, 'cda3503c89a6cdbcfc5ffab8d633fb1d4130a791e2fdfdc29256247448127449',
  $b64$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$b64$,
  'published'
)
on conflict do nothing;

insert into public.skills
  (slug, name, description, category, tags, version, license, author,
   readme, files, file_count, total_bytes, hash, bundle_b64, status)
values (
  'filter-and-search-ui', 'filter-and-search-ui', '设计后台的筛选与搜索交互时使用：内联与高级筛选的组织、已选条件展示、筛选状态写 URL、搜索防抖与匹配方式、无结果提示。', 'ui',
  array['后台管理', '筛选状态', '搜索防抖', 'URL 同步', '高级筛选', '模糊匹配', '已选条件']::text[], '1.0.0', 'MIT', 'Skill Hub',
  $md$---
name: "filter-and-search-ui"
description: "设计后台的筛选与搜索交互时使用：内联与高级筛选的组织、已选条件展示、筛选状态写 URL、搜索防抖与匹配方式、无结果提示。"
version: "1.0.0"
license: "MIT"
author: "Skill Hub"
category: ui
tags: ["后台管理", "筛选状态", "搜索防抖", "URL 同步", "高级筛选", "模糊匹配", "已选条件"]
---

# 筛选与搜索交互

筛选和搜索是后台用户**每天用几十次**的功能，也是「差一点点」最明显的地方：
改一个条件就滚回顶部、过了三分钟不知道列表为什么少了一半数据、
搜「张伟」搜不到「张伟明」、筛完没结果只看到一片白。

本技能给出筛选的组织方式、状态管理、搜索行为与无结果处理的量化标准。

## 何时使用

- 设计后台列表页的筛选区（内联条件 + 高级筛选面板）
- 用户抱怨「筛完不知道为什么数据变少了」
- 需要决定「筛选状态要不要写进 URL」
- 搜索框该防抖多久、该搜哪些字段、模糊还是精确，团队各说各话
- 筛选后无结果，页面只有一片空白
- 想把某个筛选后的列表分享给同事，却发现链接发过去是默认状态

## 核心规则

1. **筛选分两级：内联高频（1–3 个）+ 高级筛选面板（全部）**。
   把 12 个条件全铺在顶部，会把表格往下推 120px，等于每屏少 3 行。
   高频 = 状态、时间范围、负责人这三个最常用的。

2. **筛选生效后必须显示「已选条件」标签行**，每个标签可单独移除，最右一个「全部清空」。
   没有这一行，用户过三分钟就不知道列表为什么少了数据，只能反复重置。

3. **筛选状态写进 URL 的 query**。理由有三个：可分享、可刷新、可前进后退。
   `?status=paid&from=2026-10-01&to=2026-10-12&page=2`。
   **代价**：URL 会变长，且需要处理「用户手动改 URL」的容错。值得。

4. **搜索输入防抖 300ms**；下拉/联想的防抖 200ms；筛选下拉（非输入类）**不防抖，立即生效**。
   输入类防抖是为了少发请求，下拉类没有连续输入，防抖只会让人觉得卡。

5. **搜索默认用「前缀 + 包含」模糊匹配，但明确可搜字段**。
   `placeholder` 要写清搜什么：「搜索订单号 / 客户名」。
   全字段模糊搜索（搜什么都能中）在大表上会让数据库全表扫描，必须限制字段范围。

6. **筛选条件变化时回到第 1 页**（`page` 重置为 1）。
   不重置的话，用户在第 5 页加个筛选，新结果只有 2 页，会看到空列表并以为筛选坏了。

7. **无结果必须区分两种情况**：
   - 「本来就没有数据」（首次进入、未筛选）→ 引导去创建。
   - 「筛选后没结果」→ 提示「没有符合条件的记录」+ 「清空筛选条件」按钮 + 展示当前条件。

## 怎么做

### 第 1 步：筛选区布局

```
┌─────────────────────────────────────────────────────────┐
│ 工具栏： [搜索框 280px]              [高级筛选] [新建]   │  48px
├─────────────────────────────────────────────────────────┤
│ 内联条件： 状态 ▾   时间范围 ▾   负责人 ▾   [查询][重置] │  48px
├─────────────────────────────────────────────────────────┤
│ 已选： [状态=已付款 ×] [时间=近7天 ×]          全部清空   │  36px（有筛选才显示）
├─────────────────────────────────────────────────────────┤
│ 表格…                                                     │
└─────────────────────────────────────────────────────────┘
```

- 内联条件的控件高度统一 32px，间距 12px，整行左对齐。
- 「查询 / 重置」按钮只在**需要显式提交**时出现。若条件改动即时生效，就不要放「查询」按钮
  （放了却不生效，或者生效了按钮又没用，都会让用户困惑）。二选一，全站统一。
- 高级筛选面板：右侧抽屉，宽 400px，条件按语义分组（基础信息 / 时间 / 金额 / 标签），
  底部固定「重置 / 应用」两个按钮。条件多时抽屉内部滚动，按钮不跟着滚。

### 第 2 步：条件即时生效 vs 显式提交

| 方案 | 适用 | 注意 |
| --- | --- | --- |
| 即时生效 | 条件少（≤ 3）、下拉类、无输入框 | 每次改动都请求，需防抖或合并 |
| 显式提交 | 条件多、含文本输入、组合筛选 | 用户改完多个条件一次性提交 |

**混合方案（推荐）**：内联条件即时生效，高级筛选面板用「应用」按钮提交。
这样常用的快，复杂的准。

**反模式**：即时生效 + 无防抖 + 每次改动都请求。用户连点 5 个下拉，发出 5 个请求，
返回顺序还不一定对，列表会闪 5 次。

### 第 3 步：已选条件的展示

```tsx
{filters.length > 0 && (
  <div className="active-filters">
    <span className="label">已选条件：</span>
    {filters.map(f => (
      <Tag key={f.key} closable onClose={() => removeFilter(f.key)}>
        {f.label}：{f.displayValue}
      </Tag>
    ))}
    <Button text onClick={clearAll}>全部清空</Button>
  </div>
)}
```

- 标签文案要含**字段名和值**：「状态：已付款」，不要只写「已付款」——
  用户会忘记这是哪个字段的值。
- 时间范围标签要显示人类可读值：「近 7 天」，而不是 `from=2026-10-05&to=2026-10-12`。
- 标签行高度 36px，超出换行（不要横向滚动，条件多时滚动会藏住条件）。
- 条件 ≥ 4 个时，默认折叠为「已选 5 个条件」+ 展开，避免占掉 3 行高度。

### 第 4 步：筛选状态写 URL

```ts
// 序列化：只写「非默认」的条件，保持 URL 短
function toQuery(filters: Filters, defaults: Filters) {
  const q = new URLSearchParams();
  for (const [k, v] of Object.entries(filters)) {
    if (v !== defaults[k] && v !== '' && v != null) q.set(k, String(v));
  }
  if (page > 1) q.set('page', String(page));
  return q.toString();
}
```

- **只写非默认值**：默认状态下 URL 应该是干净的 `/orders`，不是 `/orders?status=&from=&page=1`。
- 数组类型用重复 key：`?tag=a&tag=b`，或逗号分隔 `?tag=a,b`（后者更短，但要确保值里不含逗号）。
- 时间用 ISO 短格式 `2026-10-12`，不要时间戳（用户看不懂，也不可读）。
- 进入页面时**从 URL 恢复**筛选状态，包括页码。
- 用户手动改 URL 要容错：非法值（`status=xxx`）忽略该条件并保留其余，不要整页报错。
- 用 `replace` 而不是 `push` 来更新**筛选条件**的变化（避免后退键要按 20 次才退出），
  但页码变化用 `push`（用户会想退回上一页）。

**为什么不用 sessionStorage 存筛选**：可以，但 URL 能分享、能在多标签页独立。
筛选状态属于「页面位置」，天然适合 URL。

### 第 5 步：搜索框的行为

```ts
const [keyword, setKeyword] = useState('');
const debounced = useDebounce(keyword, 300);
useEffect(() => {
  if (debounced === lastSubmitted.current) return;
  lastSubmitted.current = debounced;
  applyFilters({ ...filters, keyword: debounced, page: 1 });
}, [debounced]);
```

- **防抖时长**：输入类 300ms（经验值：低于 200ms 请求太多，高于 500ms 感觉迟钝）。
  下拉联想 200ms（用户已经明确要选，快一点更好）。
- **清空按钮**：搜索框有内容时右侧出现 `×`，点击清空并**立即**重新查询（不走防抖）。
- **回车立即搜索**：用户按回车说明等不及防抖了，要立刻发请求。
- **搜索范围**：在搜索框内或旁边明确写清搜哪些字段。
  多字段搜索用 `placeholder`：「搜索订单号 / 客户名 / 手机号」。
- **不要**在每次输入时把 URL 都改一遍 —— 用防抖后的值更新 URL，否则浏览器历史会被塞满。

### 第 6 步：模糊匹配 vs 精确匹配

| 场景 | 匹配方式 | 说明 |
| --- | --- | --- |
| 名称、标题、备注 | 包含（`LIKE %x%`） | 用户记不全，要能搜中间 |
| 手机号、订单号、身份证 | 前缀 + 精确 | 数字串搜中间没意义，且索引失效 |
| 状态、类型、标签 | 精确（`=`） | 枚举值必须精确 |
| 多关键词 | 空格分词，AND 关系 | 「张 北京」= 名字含张 且 含北京 |

- **不要**对数字类字段做 `%x%`：`LIKE '%138%'` 无法走索引，且会命中无关记录。
  手机号用前缀匹配 `LIKE '138%'` 或精确匹配。
- **大小写与全半角**：搜索前统一 `toLowerCase()`，并做全角转半角（用户常输入全角数字）。
- **前后空格**：搜索前 `trim()`，但保留词中间的空格（用于分词）。
- 高亮匹配片段（`<mark>`）能显著提升可用性，但要注意 XSS：先转义再插标签。

### 第 7 步：无结果的提示

区分三种「空」：

1. **首次进入、无任何筛选、数据确实为空** → 「还没有订单」+ 「新建订单」按钮。
2. **有筛选条件、结果为 0** → 「没有符合条件的订单」+ 展示已选条件 + 「清空筛选条件」按钮。
   文案不要写「暂无数据」，那会让用户以为系统坏了。
3. **搜索关键词无结果** → 「没有找到包含「张伟」的记录」+ 「清空搜索」+ 建议
   「试试搜索订单号或客户名」。

关键细节：
- 第 2 种情况**必须**把当前条件回显出来，让用户知道是哪些条件导致没结果。
- 提供「放宽条件」的快捷动作：如果只筛了一个条件，就一键清掉它。
- **不要**自动帮用户清空条件 —— 那会让用户以为数据丢了。

## 检查清单

- [ ] 筛选分两级：内联 ≤ 3 个高频 + 高级筛选面板含全部
- [ ] 有「已选条件」标签行，含字段名，可单独移除，有「全部清空」
- [ ] 筛选状态写入 URL query，且只写非默认值
- [ ] 从 URL 可恢复筛选与页码；非法值容错而非报错
- [ ] 筛选条件变化时页码重置为 1
- [ ] 搜索输入防抖 300ms，回车立即触发，清空按钮即时生效
- [ ] 搜索框 `placeholder` 写明搜索字段范围
- [ ] 数字类字段（手机号、订单号）用前缀/精确匹配，不做全模糊
- [ ] 多关键词按空格分词、AND 组合，输入前 `trim` + 全半角归一
- [ ] 筛选区即时生效与显式提交方案全站统一，不混用
- [ ] 无结果区分「无数据」「筛选无结果」「搜索无结果」三种文案
- [ ] 筛选无结果时回显当前条件，并提供清空入口
- [ ] 标签行超过 3 个条件时折叠，避免占满首屏
- [ ] 筛选操作 `replace` 历史，翻页 `push` 历史
- [ ] 高亮搜索结果时先转义再插入 `<mark>`，无 XSS

## 常见错误

| 错误做法 | 为什么错 | 正确做法 |
| --- | --- | --- |
| 12 个筛选条件全铺顶部 | 表格下移 120px，每屏少 3 行 | 高频 1–3 个内联，其余进抽屉 |
| 筛选后不显示已选条件 | 用户不知数据为何变少，反复重置 | 显示可移除的条件标签行 |
| 筛选状态只存在组件 state | 刷新即丢、无法分享、后退失效 | 写入 URL query |
| URL 里写满默认值 | 链接又长又难读 | 只写非默认条件 |
| 筛选后不重置页码 | 停在第 5 页但结果只有 2 页，看到空白 | 条件变化时 `page = 1` |
| 搜索不防抖 | 每敲一个字发一次请求，列表闪烁 | 输入类防抖 300ms |
| 下拉筛选也加防抖 | 没有连续输入，防抖只让人觉得卡 | 下拉立即生效 |
| 搜索框不写搜索范围 | 用户不知道能搜什么，试错成本高 | `placeholder` 写清字段 |
| 对手机号做 `%138%` | 索引失效 + 命中无关记录 | 前缀或精确匹配 |
| 无结果只写「暂无数据」 | 用户以为系统坏了 | 区分三种空并给出下一步 |
| 无结果时自动清空条件 | 用户以为数据丢失 | 回显条件，让用户自己清 |
| 每次输入都改 URL | 浏览器历史被塞满，后退要按几十次 | 用防抖后的值更新，且用 `replace` |
| 高级筛选面板没「应用」按钮 | 用户改到一半就被查询，结果不是想要的 | 抽屉底部固定「重置 / 应用」 |

## 参考

- 需要筛选状态与 URL 双向同步的完整实现（序列化格式、数组参数、多标签页隔离、防抖与历史的配合）时，读 `references/url-state-sync.md`
- 需要搜索的后端配合（可搜字段白名单、索引与 LIKE 的取舍、分词、搜索建议与历史记录）时，读 `references/search-backend.md`
$md$,
  '[{"path":"ATTRIBUTION.md","size":484,"kind":"text"},{"path":"LICENSE","size":1074,"kind":"text"},{"path":"SKILL.md","size":13262,"kind":"text"},{"path":"references/search-backend.md","size":5379,"kind":"text"},{"path":"references/url-state-sync.md","size":6643,"kind":"text"}]'::jsonb, 5, 26842, '2ee0c5dc4839ae7b723e8df729a642444d0ff7af3a71c07e03284d0cb0adae11',
  $b64$UEsDBBQAAAAIAAAAIQBT7NwTjwEAAOQBAAAOAAAAQVRUUklCVVRJT04ubWRFUU1LAlEU3c+vuOCmBCMM2odBH9TKoHXFUENSYrUIWmjqqOWYgUZWU7kIo2ykD/NrRn+M7773WvkXuqNSm8e75957znnneYCbT7ydZ82ccD4wbygKv6vys6iMO/y65vVSJV5LmHvA9K3XO7DTwV0tFILFo00Q9hXqpYGdGdhZ1jRoXDpV6Tj96KminMBPuQUngHoSLboQ4PP5CBieVI10CfgnHKkMu9Jq4kVN1mI0sLq0Bivalrp3oA57IpPmZpwagf3wcUTb3jmEia1J8E/7Z2FZjUSOYeKPc5I2FI8HZO2LX+cUZWSHdU1uWJisoh0VNwlpdaVVlpWEzMYpCGw8iedztO5lo86LXyKv07MDwSDwxxSm9H40th6YWwD/lJ+uqxuHakTbCMG8eqBt78EMYcpcOBxSYXFpAUYa3Czzale8UVLjsDCbxPwr63SYU8TcKRZ18iEqMX6XGbupJ1i7MozSDSL1IgrvzOmJwjMJsJ7FCy3Xqm5gWseLS5e1Z4piyf29qxTrfKPxSYsuwS9QSwMEFAAAAAgAAAAhAEXy6+uDAgAAMgQAAAcAAABMSUNFTlNFXVLNjtowEL77KUacdqVoW+2hh95MYjZuQxI5ZinH/DjEbYiR7RTx9h0H2KqVkNCMZ76/yZZLyHSrJqcIic35avVx8PDUPsPr59cv8E1Ze4Wn6pceR0jn5pmQUtmTdk6bCbSDQVnVXOFo68mrLoLeKgWmh3ao7VFF4A3U0xXOyjpcMI2v9aSnI9TQIhvBST8gjDO9v9RW4XAHtXOm1TXiQWfa+aQmX/vA1+tROXjyg4JVdd9YPS8knapHoidEU/B4gov2g5k9WOW81W3AiEBP7Th3QcPjedQnfWcI60sEjiDo7NBB0BnByXS6D/9qsXWem1G7IYJOB+hm9th0oblkGQUfn4wFp8aRIIJG3YvXv+qWmSAds0H+e0QudC6DOf3rRDvSz3ZCSgwl2DUY2cL4U7U+dMJ4b8bRXIK11kydDo7cV0IkPtWN+a0WL7cLT8aj1JuEcIBFxO2q9yc31HjzBrmXwJAX48XWhx10NzfO4+F1PcLZ2IXvf5svyJ8yqIqN3FPBgFdQiuKdJyyBFa2wXkWw5zItdhJwQtBcHqDYAM0P8J3nSQTsRylYVUEhCN+WGWfY43mc7RKev8Ea9/ICP2OOHzOCygIC4R2KM9zbwJaJOMWSrnnG5SEiGy7zgLkpBFAoqZA83mVUQLkTZVExpE8QNuf5RiAL27JcviAr9oC9YwFVSrMsUBG6Q/Ui6IO4KA+Cv6US0iJLGDbXDJXRdcZuVGgqzijfRpDQLX0L6gQUiCJIGLupg33KQivwUfzFkhd5sBEXuRRYRuhSyI/VPa9YBFTwKgSyEcU2IiFO3MARBMG9nN1QQtRLQB8XwZFQ79D0AxASRjPEwvPki8XH8Av5A1BLAwQUAAAACAAAACEAqBubJTcXAADOMwAACAAAAFNLSUxMLm1k1VtZU1tJln7Xr8ihomygDAZcW3iMO3q6e2IquqZ7ZtwzMREOR0gGYdPGQEnCZYfLEQIMWpCQsMW+ymYrMBIYikVieeh/4lJeSU/1F/o7efKmrjCu7n7qKAeBpXtzOXn2852koaHB1e156L0uajo6uwJeX4Onu73B7/X42u439HXWuNq9/jZfZ2+gs6cbY0qZ01ImLZOjMrFdnHle3JotByOFw1ErOVfce1XILRdyL6zJ/cLJWTG1/tPxjBweKvWnMKC8OVXMrfF4mpjHT+jHYL88eIsn1ny6kN+XO+PF5Rwe6mHRfQsDhqfF//7P13jKe5Sn3lrRCawoY0flobg1cSSPE/R2cqmYf2ktzFmJpFploMb1yOvzM93NjU2NTTWurs42b7efDvufX/2pxuXpC9zv8eHbrQedXV3iP/ru1rjaPAHvvR7fk+uir9MV8NzzXxe3a/SBM+licrjmiqhxEkjfnaTRdxAsZDJmba3QN+fZ1ej1dHE3yvTTdycPau64SCSuj8SFvHW5+LF8EePH1lRWE5dat8IH9fVWNiGXv8c3GVqS8X7rTbq+HgyX0cXS4MlPx7HC0SLm/BiMyYNM4TBYHDjCz4/BuDUXtKZGralTGjy3Db5CfC4rdYRBhcMNLaHtHSs/I2cXyun98uA62F46CxVyw4XDiAwPl18sFg7jxcWVcv9LGZ4spdcLh7lCPlg4CsvtMTUsKONRa3zbimcw14UjECHHS4XjRSIhOYf5MrxtHoIiPGeNkJmY9TbNMpaJjeLcCEbSCSKh4vQJ5O1yWXNvrGgQ5yzmp2Uod07bjKqw3FiaRq9K6RhRC3bbiiSXn2MAppdDCRmbsJZCMoTx2Oejj0ThZNzoucvVIJyGwWcvp38wFiJjuZ+Ow2wMzEnxiXCqRXn+lTV/9tNxBEuxJK3ojhUEh2N8dMNYw1Jmo0xMMW/BJ8wtzwVLq7CZXZmZ4blGT/Eci6i306WzWTYqmqMVKT1cyq6wCsvlmcLREEk3u4K38uVGITcrtyatzA/EL6W+pbMp6FHx7WkxnYFayVmo/6JMPi9l99TveToJHz5Z4SlGgi84LSRozUG7lfi+z0GCRMngrhWNWotJKJyZS/qoGAoNK+Q2SbTJWCE3QpvG92RirDi6XX55ao2u4DPUUY7mQVg5P1XKLPPJlcCspUN5Nlhaw2LTLldzo4BZ8BZY9nAZkjDuCoIpvxqDwJrfBV9eEyAGgrlYXmE5tA5DwPv6elINIQROIJpbaJa2GYx4mZNzUAiyGTLB4xkMwomspWN5CusasUbXMaep9zHeFrcihdwomfFOAqIV1wRUU6/NlIlWwQdTbm+/PLlXig3K2T0S2N5iae91IZcrnU3DKImIuaA8PIROgY9KeVsqRy+mFq3xMCnt2VA5DbadKs8J11BxSGSXS6Hi1imoqK8HfaCMllXPZCIr4+PFkTfFtXx5epneYrvELvsMWkmxxzocgoyVJTOL3qYhfEViEMvSoZXOkzOxPQlczc87E9Z/0oLEBkxeJuJyOV4OxYsn8C045zXHOe1IovVegBfimz6v74mSGll5akepI3GM9ADnUtpGEYo+H1gT8ErqcySOVcCzcjCoj+P+lT/gCfT5W3s9ne2XOnw9D1tbmlo+b2huamhqvhToMd+aWy71eu55W1vcemZ9fSH/upCH28amRBhUAxZdHodqweRT2pyVIyJzZs8QGZHRdXhmbcJkIJmjcmoai8ogNGpSnf9TOr/2bacv5ZC2bXGtqemhnzacJcUbiVwlnzS4S36OB7TQALy2AxANgqaX5xd4neJOXuk7xMMzSH6bIzK+y/pkLMEM52GwShJhbhjyI1PNHlg7A+qctAOG2WqxUMxv8VxyF+yREhtgTSnzPan2WgRnlPG0OuZnlWNqm0+R14SYisdBeFkZG5JJyDHujLq068kwogucF2RKPk55N0O6u7fL0+a939PV7vW5BTtNaDFFKKWCEBc20dzNvIIRyMSBuCpk5hUkJJPQdFvZYQK8OBPAc8BPs1Z58AT6WzjcAlfhJuTymlL2KB9Yu/kc2LFOLiOyaSUSpPXKZMvTSRne5/VtJwCmfF7Rfe2EECYQwib3EbsRNotv3ohmAU9MehB2k1K6BdsORCSaQYmmnoSsnkM/4NSNqYJQWuQzWkRGl4zDJhcwsW2iNOQpWmgMuz0O2vAF2qMf7RfyK9hRe+L5hApkOMAXSqomEquzIohqX70WtwaH5LCifoaobBAkDUT/+RVKUZQe2WkGhB0ur04gESK7HVohpzlnqI28G34h5PG4zB4jcMjwrMxT7mgWrYQwO/fAijTHTjMpKcFuxTerMhlmZhOrMtvyZBxDP1GUKf/nlAfpYyxSfpEhDVVprzx5CZ2133KSYQVHyd31z9A3ZIRKakgqcWqTV8jDQbkTdLncbrfrXSr2LhX85fwkQfGAkAcrcujAWoJWz4jbJhsRLV8iIN6BIBz/bjuD8B2MntiGwGgQrSQ+/bL3Mdac+2cf7B/6WWYuOJJDYgTHLPFu4pQCpiPK60cm0uvvt63FlVL21Z3bbK53fvkMUUmI0gnmRSueFPJT1ptT8ZdJkr1iSmvpbOwLVDzqmfnnzDts5bj2OeVXYTJWtkSYm8p4KO3+ZfKIc8h3wdVqK/k7/2EFrJL6Zx/lH/qZUo4OtYLTXuBwrdE1fIB3kLnVYh51aFBca1H5NBnOwTzSa/XNGt9DxikPVmX2qHySJE/LwUNZDyK4nUFq/4wYhlBXX8+ZGPQFJSRcP6pxik/7VGWOIjMcKI2sMC3Iy5CdIRnCW86HKFirZJYWSJ2azcweCDakl6lTyo3ie5T22hOt8EQpOMRfKefVNIUpGhHAEkPywHmCDsuz29YgShcK34VcTOVvQSJgaL24Oc2M4TNfVM0g99wtnK5Z0RO5Q5FcZk7Ep01clujTxSKl7FbhiJJ0VNVUAC3miulg4Sxt9WfBPjZKxcex8qt5eqIqBZCERXBSmRuHZcrZHFeozG7KnHIplbnFEeCpvlAnBak6f1mewcpMGCRPtg0cIkoc4JHE3oPF4nwQz3X45IDZogOmXschF/HIL5wCdbm+E8AIrHRYfCfKKAtS6/hg7a5bzxPiO7wEMIMHjt94VrUgRmuYhKrHd5FlcU2JAoW3TnEZqOLklmIcZmQTSE1YaygTtLNiKJxOm8MTyCyQKqn9nARX9lvGmfuR5loTIWRBvDwBHfnnmMoyxmBdPmCrTIxKfLtChU4QCcE1e1mXC8p9gDQ2zPwg7RxdL8WTKu83dfL7LCW639MrnZDb8mV58VYkKZSB1tKBqVHl2SZp3jJSoQH6qiGX+noUeMigcXimwMn3T6B2S7p6weeLOEplnq4xFwB4IXHF8e3aBiXkGCyZHxoJgLKUgrpyMpcA3AEVIwArMwPXQXO4KD2eKU9uYCa2rNK7a1rvnLU0nUcleypdC/gfu54y6Opv7PJ23wvcFzdFk7h0SdTCUG60dz4SbV0ev/8PwGdbazxtgc5H3gY9oeYmpajihr/X0+0c1eW56+2quencFUTcuErjeIrZ8qGnt7ZDtN5Uu6nF/uS5Jx54n7Q+7WjEf8+wbo/fc7fLK3q6f4OP3tantXU0wed92PPI++9qnVo1tu4ZL84bNCoqnmFjfG7v9KOYevJ/nq4+7zN7p6vYimfU1fHDG//WFwj0dIuA93FA7dfZ9qD1aVsXkOhfd3U9u+mM6Deu8mBa4cZV8OmmC6vowMD+hiwhHabCLbkJ3VEFEsoy4KYokZUGUXKv8goWEmcWqlwgsI1mwvUPo6gmOMS8fRdM4Qf7sjZRvX6GqnObtBhQLJCyww3ejYQdPGZn68zfNJqigglUARkc/AKK0FI2j/FMGHIa8YVAVsP0lIJEEtYX7mp04bNqdEHBCjYHEOY4HOrEJ1baH4KSW3GCOmHROiCtb8jkWMWZOr2tekjRZTJROEnYyqQqQ2zCMOa7yIr4VIFdk3gX4xLcik7JBGrCCpbEpmVqH1X0yGOKTOX+MzkUl/ElazTCWBdTXWVMn1ZVPVWNAW1KrqsUQhIwStS5KpJp4QG2YKIYKbFPESuczVuxfkaDFrdcHX3dsC/Sv57/JmCoVlvJdcFq7r8i2r0dnr6uQOVRnXgKRWjr6fYHxDcA5bq939J6t1Tz5L88Ps9Df23dv2JIR49P1PK42w+uiEd3RE+H+OPdP3vbAo3e7oCv0+u396vjRYXo7BC1j8S/tLaafW8/uEO+gR9evmx/Ft19XV114ptGvzdQi9VvYb3ue7WP6tTWZFy0FJX48C7N9sDL9OCyGU3feILPG+jzdWNUoEe/w2NjXOSGibGGq7Y1OfFWuFXFV7h8ApBhFkdvZShIoJv7ao8PkIrfzVamVFo/skE0BtAYKGu2NXockMJzspOFERgekgYECHJV2Nn9K3RpWj2X6PddWhcBsxycBB5DQOJMCvCcGnCFXhLYiYTKmt2D0BkFghEABYI64CjlEFEFl8ELVJRd2S8lBF/d+iPpCyG3xwnhdtie8Rs82ArvYjv2EoA96LAhhXYdUZOE7d2sz8gEI+OYTrDgqGKh1f8KJ63GMSn2xIaskTfUYVgCCEwrXAANKthKAYMkn/kFa3dcOZiwW3P68ePHoDoiz06K40hIdQJLoMzZfHF8Wg6hv4G59rHG97ChFV1hpJH3FG6fV0FlAMkqTqq3z3/fDQ+xAj6jQq+GorgdpfAoQmbY/BWcWk5laJ8YIKMmiqco0PAUPsskjxAXH5rnKwLUZobVhK0P7tK02QXC0A6DCnxSfEYSYTBklWSvC7/XTx3CW4EeHxmI3JpiUjnHSGQBT7GWMEMBM9uwMH0msG6GvS2RBRh8c4Q2qnJTOwuA88kRKekWTnR5oZKc74vP95FpItFiLNfh8pBRcN5q4yGEKqkele3xbIfiffItLOgKzhL4PX++A2fU5/fegpi9tZcvw4B5bLv3bg/8nLed3/9Wf601SwAbxmC8+l1HB5xTLYd7ckjkQxzT4YGQcwRu9d192BkIeNsb2/p8PriyOu0/yJNcOAA7m2VokKe3t+uJ9qe1T0VjY6N2hFfIvImq65UJVwR5hesAwZ6RU7oibptXd/DA+CidOMMOx8+UJA0Szeg3aUs+Ud6gXABvCyejEBHj3oLTP7m8AdFyOkvvPlPvrOeLAJ9LZ4vlF0BCNUTKSSSD6DZ2rpURsQ/7MMwMzWZ4FAku911hHHIFLVntA5Byq+SG82NFtpE9MAuk3DBmKjlVjcaFp3D/ZZIcD1aToTzPh/3CxBQeD06E0CHf5npTx/wftm3U3mwMWymdrPIc3lNtr31KLMLv0dmjo6A9Rf4rqhvxuWFKLeBDMTuMPEbj+uZMDJGrzIeNam7dHAtngrO2JvtLp0cajLdh9uqeI/EZ8tA4uprOtu9A6f8mJE+1aGTEmsvhuYbniUL2bmACCFOVg67OqNyMKrNHEcF98HJ/XHACSL5Pdya4Qxk8Zl9HE0jIyVX0Ga0fEqW1sJxel6PDMvGWUqlXmzK9YOWra4XPbVt3tCioOuXuKn+n6lTO5azpLCo5590HfGXJfLhGTcaLa9S+gqsqv5qiUnE5hLpWLUTdEYoJX3/1+9+Jjx9/TBHB1IpIbEnYQ5QagknweapHv0UlvqpGK/zsNzynz7nNQh6VVz9tYXdi+DRUtI5vQ5KFw7dmMcLQnycAK3DbCxIkSH55RxXV2Me0OzkF4KPA6xKhugMddrdq0q0FlLan1AlTbQN7W2IEVGhol8JMNk5TYWyI42E0vskd//oPvwVuuFvczeMdX0EAfyYLuTfQllbiIqgGt+g5iMSDTX5NBXOVJmWP+IhELVce/TPCzcydYU5f/rj52pcfX0aUnFxCYIZV8qGZAVRWjFFLCG9Bkt1NIDMwLKcrHoq1Wl/0uvay4Qmn9hhLX16T2wlYGV2gQWMqHi2tvXD4GlqR0TN3oOfrnm+9vt94/N7aOnIycCw4B7Wh1l6UTt7w3IqvOzxkw+EBzACnj4lQlGeWV2+IrXydD3kPRFpOPiASVg26Q6Em8U5wxrbA9NLKQ+tj4jIBuE3KcOOhx/fgJmkEKe3UaWlsEpCDjIcQ1IngINr9OvvTCM//37pF7mkojLMRwDUctxIvWM2qjPUL21jt7hRVFaoZ5HLZLaoIWlRUX6qmN/Wo+MLB+TbU5FIhn8dNEs4X6InqWZHUMshecphfXy+o26RqwindIFWGZnpLqgNinhncjPv8FbBbl17AhIhm6vI1Vdb+QA/L7KNbVA5QAfb8840tu9Wv6nBz8YTmzAyQzle6c7HywGsnhqlbgrt5aGKlJaja+VpnbBs2Ijh/Eityij6j3fqt3DD6QGeOl+WTEi8JkVUsz47j51xIITzuXJfXxRQV88OlKHL8GcqNFfTo6FSyM8IRolFnqw+hlSA91OXzlGkaJvDFBw0p5Gb14OxxKUTO0u5EqtoESNrpLJ0ldQrA1oiBsTQrfkBF/Alu3szI1QF9d2prlm9jmZrcxqgpB6cAPBqRmcHzEbIU2iBo+zCjEwPmncYBOCxeKEqWdeEQd9jM/SnrdRBZCZYAU8l73hZ37OtC793HAcgAJJUABH3/5aK7OOSNFUSkF4MW/MxNFhWiNw0spCDA96+yqBWqb7BUkWqACNizyhTUnRJ24e/XyXqqXdrRvQNV3ZmLflza4OaFKda4fENlRU9U5VW1/7nePs93tPFtVnzgEoi6tlXJ/Eprq0jf6OCOPNSJs1YtR+h19S0Jyt1wg5BN1HEjwZ5WHRIJU74oe4DHNpHtqjOEcSHKEYgTJb2wM6qDaGdUx8IU1RkHJ/PiCGXHHDd13+0oKE9eQP+rVRHu3HF+uhzogN8ZG3d2VjSocUCx2T61ucOgQgOZqcP5mQsGZhg/1Cx2POSYwt60WgfMvVd1uYMIdLgXDtvsInR5gPMnXtvU2fYAbBCXr9jIdKeH8l+C8aowunwaMQwX06pJeBmHg3FAAZzuUl1ylodS2oAAP9ZTOWzrXN4coDr6kllVIjlxjqK08h+Ubqz1k3Fks5Qa8ydoBwwH6Zup8/GcUsKt16RH+u0H0mS+tFdlWerqHt/bozRbdVtR78FFmOt65y7qUeuInZS5PMhOTDXhCFBB+Oc+Fme29v0ShZ0QIFwVZe1EnK/C2Y40h5yBL34qx1W5+EZH5UWQ5Sg/ZiBPI2rHttp/wVNtTdGFnvxz2pPQIS8l7urWGwwAnpuzFXJK5lqcgmzsHJ2Mv8oJql1U8RSKkWOA4th+kFik72uGUaDT75lToGG0SrXTtJlwjk98VvZ2NKl/znkbCUndhdePzN0j3DWtdM5s3wkdJQCoVTS7ubLhS9f2FTfdqBt/y0GTCoHEGPfNTL9IX/ud3CgOElnnbr+xy1Vr624gu/2jRVyfqmzys1fgzt1/U3qulnLcvnNQDxdNHhPcdxTh51QKSYau6vS9Nkp6YDRWOIlOIlQZ49938wjbyolzVYVyx/bkXOhQDQI2iqo6Dq72vZLGlIfnyhU+hHGdNpZ/LnWsHOW9jFGVtpVcnGERvhUOlpHgtlaqN4EOcH5TldZU72ASGRyJdlDu1jhak/XQOgc7WId3cIAKjCQou8CLanTAQAMqNyHjYjDU3ONnYi5EHXTZXIXH0t7vp0lQsPebsVW9YXWpHiER+SBIsqGjmF03EMILpIsQH+D5OAX35P9WV59qZHLbiYFScJASPr5Q4fRDCK86McL5x/jPJ9TdVrq0gYIIeBcB+HaThyF4LpoowCcG8EFhGxVIFvB/cZWa7pW/GlG8psuuhDpD3xFAlfDgf8C7Di9Ayjav/2qfr6tBOcIG/5PutsaH7W5Ds45ZoAxC2MzaC4WdF0nhYwgvoPKpn62ATqcqdIV+T5TClJyYLEVnTar4MFSyjXyQRP1HOnc9bQ+83e2KxL8CUEsDBBQAAAAIAAAAIQAFd6rfRAwAAAMVAAAcAAAAcmVmZXJlbmNlcy9zZWFyY2gtYmFja2VuZC5tZGVY61JbRxL+r6eYLceLhI3Adryb8i1FHLJ2xUl2jauyVcZbUvAx1kZIlCRvnLKpksBCEpYQNjcBwiDCzRckDASELvAu9pk5R794hf165kgojsvAOX1munt6ur+vZ04xMZ41dpeNuWd8fMx4W6hFU3w8rhfHePIAz8bmtDG1arPxRAofxeioGi5yIzwyxwsHemnkuJJUU43JDea6dfPbLtZymkd3apN5s5A63eJiejFMM5c3MdSIroulfZ7Kic3yx/CQyL4T0zGzsCuKUZ4uQDvfnBH53z+GIzbY4ZUpnp424ym88/gI9MEz5YJ5GOWjr/noojlchSKb7dQpMkQDm/Two2gtVzZmq3w8xVNTNpteTJlrETj/MZzk0Q01SmzkjB1raR/DMDakFxN68Q0fW+TzS8eVOZvtnJO1torwOqy1tkLi+vFG1+0u5mbWgh+fbmE/3GY/ffLudDpdTMwsiZ0p8/cttSIKWHTDzG2IxFuRTpPz50m7UZ4Qr7Lm7kYtlpY24BC8PNfRAZ/0yhx/UdWLm7XYi9ryApPSyM2vGR9/a73wlZjYweSkyCZIxLCpypbIFPjsm9riDtm6QLZ4PgG5tHISBbl+RA9rxH5RpAqrYm63lt2m9JBjjitxPhKtDW8oY7Aq4uPYRL28f1xJ6AeLFPlYSSysyj2Bocgc1q6WU0hTTPOv9OqEyBzySpr/tiUyY3/cd8xyuVyhoK3X7wuGWHdX5+3rNzq/utXFrrInNsb8gfta4BJjd1vk0/f+lrOspfdRMOTvx5u7X2t+/+dDv09ruXcW8x4F5TTMoyefNTCgub31SVq/2+NVg0Oe3p+10CUMDnlCXqXS7wtpvhB9H7xMLtaLgrkGvO5e7aHfC3dczJjfFWOrxuR782iWlhufwU4bk4uIEzZDP1owCxHsqkiPGyslxJWCTfuc4i+TlJOylBpCZLQZ223kdwlDIqoyxfQBIohyUElFOyQrxWZ7ylQsjfdl/uo5w6ucgIfuf91isKofklTNY08xvq2tDYI//cYXozLN0/vQhI0388soIbzSrieei2wJz9h1soBIVMJ4sOr/3IUvqPDxIS1h4au2UEDTpEYUorG+pTTy/LKI70NCGpditeWMpS4ZpbRuqDvNK0t6ZVGpRF4qrQhnLRum9J6ONS1GvJrTi4fQbozuiTBiHVGBUKqN7UMjlyfVV1nLgNtzv9lNml6bOoI+pDT5V09y5DzPH1jOSYOk4bvOO9dvUImzzn903vy++w6p+tSldtbVDcVUChITeXxFTG/KgrC1Mb42hJpvxMRC10wBWLNU5EfDCt9odPz67e8IrFXMyKf9VWwHJI3IUbFLvNOLo80+iPg0nMBXZDZV9XC1trBkxRZAhZzNvROJecqyhkfpN9KLZpSVXvDIHt+ahFVkpl6koFJWFyeR5OwKUAcGYmYuCWGTfoRXL6+iLHh6xnKjOkIwPLpk7kXFzB5yX6GfWMiJqS34X5sdV/40MlBsFc2jLLZJJZs0S1hOEpUvH8KT+M8gQITwEZipl8cIM2d2zfyWXk03pXCdMRISOYGCFmHxlWfG+IjNprSYhxM8CixLIgORljN66R2qUmQXRXYeJYcYyZpNoeLgAQ1CLBjPbvGFMAnqM5pw7cEjX2/I4/exAXcgqH2r/foLgCxoD7h/ucSCoYDH1+eQQBfQQo8CPga5E9J+u8MZHPB6Qvb2nuCZdofzgccb0gL2r/x+r+b24aPX06vZO86yi47LjLW3M4FEXJljF+HRG6zLNqhAq42JZMJ4XSJOlIxKlfK6JJYqFAjw0vrLxusd90+sNlylnZJRwW6rTSEiPniOsCIAYJPO779ubUVh7Bg7VNZG5TXfSpvJYT6/W0+QFI384baajs3l8b1PHKRyzmyLzWUVeWM7Y+7uIsv4yjqRk6xJXqgADsXiqllYNuIjxlBRKVTUQrsXH+FxhJ0AD8oJgJvYhXjbTtCvWJpg5TSx9ADRRJPMwbAi9oeRciPlYNS7w1XPHz6PsomoLOHVl+RuchrMkN3g6RdmYV+8H6J0LS/KhagYJgndM4fmixmQAE/FFK8bYzHZaABg5DhCGtl+fIrQeHOphCC4aQ4WLxZ5ca22Ns23DtUeKsSVm2pW3/HUKB4khG5S1yW9BjujjlF0CBFlAAKFMBaL1DPIidhQ13HlxXFl4riSwRMwUDq5jj3mI7NqbQR8Q3kj/56i8fw9tFNR1MdQLUoiU1PHyubRKxgy3q0RoqQLtTCShLC1QSvMBQppO3f+wudtF//29y9c7H9BKSKJEgBSm/uEkP+G2/vgR8/90EM0CvbgSS1dvYZiCjoDmqRpe/vdnkfffNNxro3+XOy61953lvViEOuW450PAv7+6w/dgev++5q919lrPXaG7B0O1sY6Hn/T1dXhcEAnO9HZ8+hCR0cHqWphLQ6rPZCEPUnU9qeGlT6eYugprZ5rbISnt6k2+WYGucNcXn+v29sd8gfcfRpinqSalTvNzjDVQfFkCcnOftZ+tUpAVhPmEwgDRokMxsq1GNU3fvOVlEUuo6M8P0yZF9+iOQkMsKoaQv1wnkhlIcfjS7XZFdWToDdHOiknLSxDDc+NG+sRMZUWzxZ5tiRmCzB0AwUeMbGgUdhHB034DOTl1an6bFk2pxgaXmvp5ZKZz1N3EZkUwzuYRWEw19dQP7VMnIcrqAqVqexDYpWdJ7RQuSMSKV4J8/XnaqrlFiBkdJqd7+joD1LcCpN60aJVfvTWojhps5Y7gMYV9oUVLTAROleeTplA9INtkdhqHo2OVpTQwc2phahFwW29kuHRONw+w4xhEM2GskXbpA4gkqwUIFlRniyIZARkY8yDtOdcH0ZetH8YmXAxVIF4/hoBdHWh1aRWMpc38ytSEOwFi4KiZjYbIUQfX3ub0Ut5pdwqh8cn/HLD0/fQi5+Q/QkLaY9DZylZJNmwwUtMyeplcrnxrS65e48NKiLyPGD2v9Q/O72ary/00FGnpyvXnpCewSvt1y5jrCpGLYiKkvqbys7ZeubL/3z2ZNDueHq3515Pj6y8lp6ez/6KikE1gbKAUfpBoqEmoEGLT/uF3db6uh4P2F32z540/Oh3D9hhxz2g3dYczv/6PT57y9MWx6DDBa19HqrCBofaqVrhqvzDmPTYYtMAJpMqO9gYEfJYeKH+BTRnSAuG5DcH+5Jd6XcHfqZIXX3iGbz2hMRYOAmvsUvE5yFrqmNQWWwnXfDE4l70gLI/Q1MpnqkzXqPvQIKZsTfNXQedluVhQjyvmEfzYvM3Hp9FT2Muv4UCOSDucrZSe5WphedkgkVcdpw3R1drk7OKeW3NKtiNO9/dYlDB/t3djUSinjSugq608+hwHZeTfCQlitticUJRrzk6ZAyhBcbdgNV1Mdd9t69PC/gfBb2/dmuhmz6fFiALRBKtrQ2KjCJnI1Z7N/aSl9I2m3XpIGXURkmx8pRX3/MJrIRYUjWroA4jWxGJQyAW4OfkOK56eZX+qg6bjs3qyEDN2syevKKgHo1WuQrylV1bfYDlQBaNviXEoZQOZIlUbQH3AdbxvLmSxbsc+h91EaCmYBuUEuZqbUhONMhDt15NGdU8em/Im/y1upVYyRjbosZB4QZMreyya8TV6LNIx+dSR3EO4CoWhoHpavbaEAXraB5dN8aq9Vhng8aq9rfr4NG0qotyVdEsL1nn82QCsYIxHqbtkPtH54A/iqG0efeouUNK5oFbTSHfPxDbOQrGRVxDALA/iSzuKE4a8GFiSHmxonyB0dSOXj3CzQFul+gosLAsEmFcauglnDeSepnyD69quEyHtsb1iTo61POA+E7yonk0yedfSXea0V6dwuGddfdyFMNY+lrYN3OrPBptlGeD93AmkkeWJhOqz2MXmIE2S35UBvBglGeJQNWwxqfCfnOLDNWgHNUiU67P71Kvlo3X7eFcL/as1J7eqt/SvDB/36eTk/yIVcvz2BuRxQVLEncNdLMg3SKQ6PzJHwhdxwVGwO/1glkajI+oVSbQM0jlxnyRj+O6yFoxKExJEDC9vEe7eQF3Susv6TCsWlY5l/r2yBHHXaHELuAYIi0mD3g6Tr/xDOpEAqkeRLbuDePoKurm1Ppkp9G4YwT8G+tl9CGWRDoCe1QGFC2cklUqQo+ELb1ILQbuUMxwFA7TPRUOBPJKhS7Q0hlE5tO7t/8DUEsDBBQAAAAIAAAAIQCr8MGuow0AAPMZAAAcAAAAcmVmZXJlbmNlcy91cmwtc3RhdGUtc3luYy5tZIVZbVMb1xX+rl+xnXRiYAwGp+20pDiTuslM2tjpmPhLU7eSYXE0ERKRliau4xkBRgjQm414lwDZvMUYCQMGvSD0X+K9d1ef/Bf6nHt3VxK2W09G2b1777nnnHvOc55z+UAx9lfr4Wlj5oSHx/RiQrl960vFWHnEkjGWesxSMb6/5XLxmZnmeTx9btZWxVS+VGCpBEseYA3fmGJTETa2wo/m35zF9GrkdTjWLOh1OM4z00YlYs6Ms+zjN2crLJplO7MstsAXT8xCwdzZZsnHZuGUvxx/HR5z8fkDowJdxvHAN87YWRKjbHMFOxn75/Xcq/pK2tiuYBCq81dJcyfKlndZIsKSh1CoPhlnqejr8DjPvOALU0ZlmU2VWbJgrB7zxJaR3iWld3NC7LjL9cEHil4MC2FlvRLWS1FYJ6w0wzG9GCdbJ3fZy7D0gsv1k8L2l+AMvRo3qnkFr9FTvnCg17LG/DK9JgssGtHLe/ScStTDYdo8vUuvthHG7Atjb1b5CcI6Ozvx5T2/+A5X6JUTJaR5NFVI3L7wS+rSRKklJgaC6puzKItMQs83Z9PvXCR+sSikhkLegL8fizz3SL6Q9k75HR3klO9H1eD9jg6Md3Tgy/9/crnsiEkX4GiKicUTXsmZJ0dsdVUvPufZHAzEoeA49MozvXJqHwBLLtXnaziaeiZsbiMEHhmpCJ+eZTO7PF1ygjZfqqeXxVl2dOjns2xzoaODomx7nK9lZATLPepTMUQin0/yR+t6LcfHCvATTobjAKdneQZRcordzPKeXqmahTG8wn8U1MU47R9Zpj2xRj9bMZ/u8cUtVlvEglvqkBpUg4qZP2BVJME0KWPWlo2dOJ+YZJFXdPqtnoZQVjpBPLLkIqQ7MQN7pA+c2CzHKPrLSRZdpIwR+eByud1uLeTS7o+oyuden6YGQ0qf8sClKN+p938IBAc/6UUgBL3+ex9jjGJnNNQYUux/V64ofG1FL56TOvF5Fj7D7MAPfjXYsn4oGBh+x2qx/ov+rxRjfR++4Jl15T7+dd640Tk4iGVaoEWK5rnX0OGbOy1aIDHk5p7hwKhfu+H1Y6Z/dPiuGqSl1qjnx6bRhx+TEygdjZcVtoZkkjETWQYQ4cUsHPOlxLtTTOTwovFiWy8eYsz9ieW1Pna2oZ+tuzGGkFPcqn8gMKjevvXF9cDwSMCv+jV8wmIAE9aLlY7CfT3d3bTQrL5wZMOt/GiXP0oah+esLDOOFSfYQVqsDfxbDQ6Oqn09tI5ixN3jvuLudtOyQlpxa8FRFQNDHl9IdZOXpQBxUPLchBh5vH0jHu+gJcj6SMo70YthvbgPQFR8nruqT4oSbhdCcDp9ng/p965b4dEFe+gyXgWOmeFJaCARHouQSyR3ooqMqocXkSrSMzIOSCJFTd/V7qu/6+zp7uwWNtrBIoLY0Qx4UF885tEjS4LzRjqEHBE9V7/u+UNv9296P/ro7yRMr0yyzK6EBixC/hg7T/AgoJawgCWfIxrq2bV6ZcnMb0Lpjg6klXyza9+sjJpy2ixssdIhmwqz6AHSUa9ssepcfXuB6s3cOTK1US2Q32N0CqnHVKHief5qDKBQH6uxyTjfr7Dz50YC0DKNEpoJs2LR3BlDXit3R+8RDqI8WuCGfFZ+iTxROCrTwoEF8TQgn96eQevotauri6qqvRVpxvefGbm8LMMCec38z7JWR1OobBJ89fIsy6/x7BYvpwRGWkDyo2to1D+gAZ6U0ZBqAcrnOL/bQV/boDrkGfVpoV4badoF0AwE/CFN+SakeoID3/7NE/QMhy4D5LT+poE7ACUIbB5qa//YhdXIedsYWeCoYgkd+UIJjiXv2XsMOQAHWTfU4UBbW7vSd00Z8QQdZdta9bB1br/cquEdZ3errJICEtPftztMaiAsFLju8fnuega+a2sb8WgD3/YqkKx5Pb4/WrOuXVYCIxoh3QNlZDT0LR7uBgI+1eNXHgq1yXm2cL/6o0bATSdqmXmZnoVoBRDXmPo97R9Sg9jK+x/HbBLQZK5ccOEU2r6H0AdKUB3xeQbUXuVXQr8uUg4q0ZKHcJOzvS3s7dOUzguq2mjQ37Sg4aE7iick1QU+S3jutDyN0owyF4l3dBiVYz6zSdFYqSpuSwrgDaws84JlrDwAOkjCZhYqdEIU452KeT7HJrd4LiKrq8UL4keU/3NxZDFJSeyIeEKtJ3GN7YrPkXpmfNrYrQELkECYU1865DMLRGYj0G4ZwhubWfWeEElxO94ToEzpLmBE8gMgDcFg7pWxAdJAWSvQnDxsLbDBA5SHwKOJAEsMvECDXaAPq1CGwCf7lBQQkHF6aFSSRKYFqZEMmRwlPOwIBTshQ3ee8bUUqK+cLCK9lWmT/URTKOz3twRoSIfijAQbMzLrgBUMSGgj3y4B14AaPV0geA6swlF2ZyDagqjch+S+yMndBPJKlYj+zcw0Fuf29OKMVVccmoM5iSf15U1nGumK0AbLBjGzIJQf5uBtYRm8WJ+KAyMd48jjV0lN/TxrvlqQTQUxQDD3coQXktCNFw/5+lwdRWzhgFXKRCYLJfNlTmjbFJp0mBb24G33iOVX2Nk8hi2t5KaE8TTts6EhdQBMQW6suP/S/9XNLkl7vEP32yyx7aLM8tg02ALPv+KzEXaGNmTc9REp3Y/pA9oNFHCYNot2yjyYwH5CsVuqZ0BTen6vYAHcLHsZHLozS1GFBlBOKkbxNVFlpXFjf5r2zCB0FvhJlBhv9ESEpuSTjvIWwjZwfkAL+oA/fvUH5dO7gaB2PeDXggGfTw0SoIMiqgCsL70hzTaPECfkvef3+HrF4i75AsDpGiBwa1ODwQYaeocUGujye4ZVpa+vT7kkdvksGAwEL7VbkEOMkRjr/jPUVGmB5BB8ZgsdgA19YhFJk9Amfi3MklYJdTwkn3Rvwr6/qveBcXKXxhDMfs8JSoQTJD2NrG7uW10uvbgJhJJ0lKWAbeR0M4qkQ/50XmBcGJR9NBlUqehVLEkYewUgHV87QYDi/KzsiabkPjg20QDNb4keiQCrQdkgT5I1MBkAKD4jDwRvAyiiv2GpPUnaCIBkMzMbgQ9FfBF34oldM566oCVRhhglZXaNEheiEVW2JL2Y1qsb/FENdBc0BDRYL4lGyGX8XJYqYzNAy04FIohtCUcJmY3+Sm7YgMvJ/Xf2/lZTuVDiuSjb/Nl4dMLTBR5rmWn12L+E0/gPWYQa8Fx+pLxJYVMqCcAbM0d5jDMypwjGqU6lYkhmCZyU4nr5CY2WDvn0AeFYbdluUY3VIiCjufUWhWyjyGoT+tkSmxFH44LviaWKXgBnI4qhBFqCFl9gwOOzGkPgy9kcGvfmmxd0imC6rbcmFUQTia6PP8MBGhvHLJuUvqHWN7MrLVU+paselo9ROZyeg+FAOuvTnxTCjOK2kQ3TtCZ7ZUtsJhAmcTZ5wrZFd2310yCZ+TVZJ6jK5A/0ahIADjSV62VdEXa1trxUNKn7l0cQmZQXJgRSp5a2tv4ybATVnqC8enfHj8ASesKKlhkUT6V1jOqVBIvu0a3B4ZJ5fAxTZcjRHZHN6J2SxGqT9VxFSm4Q4wYvbiWbI720UzM5avCmBk92npqANDDqED57AfE8SUrtZnwFGUawgSSrVZHhDTIqWj0igiNd91St7ZIcuCRAjkDUmvDhh0r/159+fbv/X9e/+vNn/V1e/4BvdFCF5uJ7ezvpAUSzpYkHRwvR3UKLm56bygUFhr1+zL8penC4QSrh9MCX2h1F5JQub+hzr9+rqW1Y2E5qkYBrfUq31MBZCaH44mggukgBitQpUu4hyVo1ofayyRH02nCD+IjdrvzzH4MPfvOwE79Xrd9fX+nSVKpTmGL5wRJF/7M1kFyu5SRW15QeZ/cRui17yxE0avmA5LZMgiu+8GvqPUynceEMMeGa0q18Ih97lZ5mig0ZDo9miXUWpcgE77JVqmeXwY+kXwCo8pKLwl9kFjJXrwLRBUHMUpmcP4ZZsliKhBZdLu5HJRLSjOk5IBwBWDJlbJaR3/UJ4E6k+RINJJRtvuTzuGEVHEvC9N7/vo2laxo+F9erGbpMEN/MHBC4TPcVqYiRfvneixpkdfP2dCtgcXF5MbENt1Dm/xZoYd0lEtTGpjECUJI3sLYkeawkg7i5fVsiMWTiiOzFbe3qGvAMPsFk2GgvBWMk72VzSI+LSrxc08sJcyfCVs/ZWJJtVS1eslSwL4ktGYknoLhvmYC5M3JKcRLFEtUEbrdoe5OqsuxIVo2rLb50TqAtKoR5eoSCS1UMgXqOckz389JuF4tu8oV9lnxmFsIifgTlf271KXlcYMZ4/Ck4MQ1mDlBUYbVZW5JXFRR3mQPwSkQPximc1l2YL2c6bQ7dWTVPFR9sIx04L2Wpmtt3nTy8AwPM85IxHyM1aUwCM93ZwyvlWQCzKM30TGGZnagvpyTxkGXaYlNyGdi94ODiBrNvGN7VS7O4HbSKtGgiyFTEerksy6FZ2AdNgS9gP3U8+OtAJWtPtu6GFe+gVZPQE1pqbUAVM1+rL+b5Ou5XnlvlunKMaz6qc9vj5vFTNpOT5B7LLUtac5WugEWmURW0/9rQSNAmuyyGVMStojj+8A6uV79T/SLtjunWCzU1FQfBJzpXmwJ8ir/nUL0jUf8FUEsBAhQAFAAAAAgAAAAhAFPs3BOPAQAA5AEAAA4AAAAAAAAAAAAAAAAAAAAAAEFUVFJJQlVUSU9OLm1kUEsBAhQAFAAAAAgAAAAhAEXy6+uDAgAAMgQAAAcAAAAAAAAAAAAAAAAAuwEAAExJQ0VOU0VQSwECFAAUAAAACAAAACEAqBubJTcXAADOMwAACAAAAAAAAAAAAAAAAABjBAAAU0tJTEwubWRQSwECFAAUAAAACAAAACEABXeq30QMAAADFQAAHAAAAAAAAAAAAAAAAADAGwAAcmVmZXJlbmNlcy9zZWFyY2gtYmFja2VuZC5tZFBLAQIUABQAAAAIAAAAIQCr8MGuow0AAPMZAAAcAAAAAAAAAAAAAAAAAD4oAAByZWZlcmVuY2VzL3VybC1zdGF0ZS1zeW5jLm1kUEsFBgAAAAAFAAUAOwEAABs2AAAAAA==$b64$,
  'published'
)
on conflict do nothing;
