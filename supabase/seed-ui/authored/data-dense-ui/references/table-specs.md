# 数据表格规格细则

## 一、行高与字号对照

| 档位 | 行高 | 字号 | 行内上下 padding | 适用 |
| --- | --- | --- | --- | --- |
| 紧凑 | 32px | 12px | 8px | 日志、监控、纯数值列表 |
| 默认 | 40px | 13px | 12px | 通用管理列表（推荐） |
| 宽松 | 48px | 14px | 16px | 行内含按钮/多行文本 |
| 触屏 | 48–56px | 14px | — | iPad、触屏笔记本 |

表头：`行高 + 8px`。40px 行配 48px 表头。
分页栏：56px。批量操作条：48px。

## 二、单元格内边距与分隔线

```css
td, th { padding-inline: 16px; }
td:first-child, th:first-child { padding-inline-start: 24px; }
td:last-child,  th:last-child  { padding-inline-end: 24px; }
```

首尾列多给 8px，视觉上表格才不会贴着卡片边缘。

分隔线只用**横线**，`border-bottom: 1px solid #f0f0f0`（默认行高时）；
紧凑档把颜色提到 `#e8e8e8`，否则 32px 行距下细线几乎看不见。
不要用斑马纹 + 横线同时存在 —— 两种分隔方式叠加会让表格看起来像一张网格纸。
斑马纹（`#fafafa`）只在行高 ≥ 40 且列数 ≥ 8 时使用，二选一。

悬停行背景 `#f5f7fa`，选中行 `#eef4ff` + 左侧 3px 主色条。
悬停与选中必须能同时看出区别：选中行悬停时仍然是选中色。

## 三、对齐规则

| 内容类型 | 对齐 | 附加 |
| --- | --- | --- |
| 文本（名称、标题） | 左 | 长文本 `ellipsis` + `title` |
| 数字、金额、数量 | 右 | `font-variant-numeric: tabular-nums` |
| 日期时间 | 左 | 等宽数字，格式统一 `YYYY-MM-DD HH:mm` |
| 状态标签 | 左或居中 | 标签宽度固定，避免列宽跳动 |
| 操作按钮 | 右 | 与右侧留白对齐 |

状态标签统一宽度是高频被忽略的点：如果「成功」和「处理中」宽度不同，
一列状态标签会左右参差，纵向扫视时找不到节奏。

## 四、列宽策略

```css
table { table-layout: fixed; width: 100%; border-collapse: separate; border-spacing: 0; }
```

- **主列**：`width: 28%; min-width: 200px;`，配合 `ellipsis`。
- **固定列**：状态 96px、时间 168px、金额 120px、操作 88–120px、ID 120px。
- **可选列**：标签类 120–160px，超出用「+N」折叠。

`table-layout: fixed` 的必要性：默认的 `auto` 会让浏览器按内容分配宽度，
一条超长文本就能把整张表的列宽全部重排，翻页时列宽跳动。

列宽跳动的根治方法：给主列 `min-width` 并固定其余列，或者对超长文本先截断再渲染。

## 五、排序、筛选、固定列

**排序**：点击表头切换 无 → 升 → 降 → 无，三态循环。
排序图标常驻显示（弱色 `#bfbfbf`），激活时变主色。只在悬停时显示图标的话，
用户不知道这一列能不能排序。默认排序状态必须在表头上有视觉标记。

**列筛选**：表头右侧漏斗图标，激活后变主色并显示已选数量徽标。
筛选面板宽度 200–240px，含搜索框（选项 > 8 个时）、全选、选项列表、底部「重置/确定」。

**固定列**：首列（通常是名称）固定左侧，操作列固定右侧。
用 `position: sticky` + `left: 0` / `right: 0` 实现，并给固定列加阴影：

```css
th.col-name, td.col-name {
  position: sticky; left: 0; z-index: 2; background: #fff;
}
th.col-name::after {
  content: ''; position: absolute; inset-block: 0; inset-inline-end: 0;
  width: 8px; box-shadow: inset 8px 0 8px -8px rgba(0,0,0,.15);
}
```

固定列的 `background` 必须显式设置，否则横向滚动时下层内容会透出来。

## 六、虚拟滚动的实现要点

```js
// 关键参数
const ROW_H = 40        // 固定行高
const OVERSCAN = 10     // 上下各多渲染 10 行，减少快速滚动白屏
const totalH = rows.length * ROW_H
const start = Math.max(0, Math.floor(scrollTop / ROW_H) - OVERSCAN)
const end   = Math.min(rows.length, Math.ceil((scrollTop + viewH) / ROW_H) + OVERSCAN)
```

1. 用 `<div role="table">` 而非原生 `<table>`，因为虚拟滚动需要独立的滚动容器 + 绝对定位的行。
2. 滚动容器 `overflow: auto`，内部放一个 `height: totalH` 的占位 div，行绝对定位 `top: i * ROW_H`。
3. 表头放在滚动容器**外部**，否则会跟着滚走。
4. 键盘移动选中行时用 `scrollIntoView({ block: 'nearest' })`，让浏览器做最小滚动。
5. 每行 `will-change: transform` 是反模式（几十个层会爆显存），不要加。
6. 滚动事件用 `passive: true`，且不要在里面做同步布局读取（会触发 layout thrash）。
7. 无障碍：容器加 `role="grid"`、`aria-rowcount`、`aria-rowindex`，
   否则屏幕阅读器读不出总行数和当前位置。

## 七、空状态与加载态

| 状态 | 表现 |
| --- | --- |
| 首次加载 | 骨架屏，延迟 200ms 出现（避免闪一下） |
| 翻页/筛选 | 表格区域局部遮罩 + 骨架行，不要全屏转圈 |
| 无数据（无筛选） | 插画 + 「暂无数据」+ 主操作按钮 |
| 无数据（有筛选） | 「没有符合条件的结果」+ 「清空筛选」按钮 |
| 请求失败 | 「加载失败」+ 「重试」按钮，保留上一次数据 |

「无数据」和「筛选后无结果」必须是两套文案。混用会让用户以为系统坏了。

## 八、检查清单

- [ ] 行高用 `height` 而非 padding 撑
- [ ] 表头吸顶且背景不透明
- [ ] 数字列右对齐 + `tabular-nums`
- [ ] 状态标签列宽度固定
- [ ] `table-layout: fixed`，主列 `ellipsis` + `title`
- [ ] 排序图标常驻可见，当前排序列有激活标记
- [ ] 固定列背景显式设置，滚动时无内容透出
- [ ] 虚拟滚动行高固定，`overscan` ≥ 10
- [ ] 空状态区分「无数据」与「无结果」
- [ ] 表格容器有 `role` 与 `aria-rowcount` 等无障碍属性
