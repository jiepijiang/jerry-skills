# Bento 网格的响应式塌陷与动态排布

## 一、塌陷的三个层次

「响应式」不是把 12 列换成 4 列就完事。要同时处理：

1. **列数变化** —— 12 / 8 / 6 / 4 / 2
2. **单卡跨度变化** —— 主角卡在桌面跨 7 列，在平板跨 6 列，在手机跨 2 列（满宽）
3. **卡片可见性变化** —— 移动端可能要隐藏 2 张次要卡（用 `display: none`，
   但要注意：`display: none` 会让读屏器也读不到，如果内容重要应该改成折叠/查看更多）

只做第 1 层的结果是：列数对了，但每张卡都变成 1 列宽，
Bento 的优先级表达完全丢失。

## 二、`grid-template-areas` 的完整重写方案

这是最可控的做法。定义一套 areas 字符串，每个断点换一套。

```css
/* 桌面 ≥ 1280：12 列 */
.bento {
  display: grid;
  gap: 24px;
  grid-template-columns: repeat(12, 1fr);
  grid-auto-rows: 120px;
  grid-template-areas:
    "hero hero hero hero hero hero hero s1 s1 s1 s1 s1"
    "hero hero hero hero hero hero hero s1 s1 s1 s1 s1"
    "q1   q1   q1   q1   s2   s2   s2   s2   s3   s3   s3   s3"
    "list list list list list list list list list list list list";
}

/* 平板 1024–1279：8 列，主角变 6 列宽 */
@media (max-width: 1279px) {
  .bento {
    grid-template-columns: repeat(8, 1fr);
    gap: 20px;
    grid-template-areas:
      "hero hero hero hero hero hero s1 s1"
      "hero hero hero hero hero hero s1 s1"
      "q1   q1   q1   q1   s2   s2   s2   s2"
      "s3   s3   s3   s3   s3   s3   s3   s3"
      "list list list list list list list list";
  }
}

/* 小屏平板 768–1023：6 列 */
@media (max-width: 1023px) {
  .bento {
    grid-template-columns: repeat(6, 1fr);
    gap: 16px;
    grid-auto-rows: 104px;
    grid-template-areas:
      "hero hero hero hero hero hero"
      "hero hero hero hero hero hero"
      "s1   s1   s1   s2   s2   s2"
      "q1   q1   q1   q1   q1   q1"
      "list list list list list list"
      "list list list list list list";
  }
}

/* 手机 < 640：2 列，主角满宽 */
@media (max-width: 639px) {
  .bento {
    grid-template-columns: repeat(2, 1fr);
    gap: 12px;
    grid-auto-rows: 96px;
    grid-template-areas:
      "hero hero"
      "hero hero"
      "s1   s2"
      "q1   q1"
      "list list"
      "list list";
  }
}
```

注意每一行字符串的「词」数量必须严格等于该断点的列数。
少一个单词或多一个空格都会让整个 areas 声明失效（浏览器静默忽略），
表现为所有卡片堆到左上角 —— 这是最常见的调试困惑。

**用空格对齐单词**，让每行的列边界在代码里能看出来。
上例里 `"hero hero hero hero hero hero hero s1 s1 s1 s1 s1"` 是 12 个词，
`"q1   q1   q1   q1   s2   s2   s2   s2   s3   s3   s3   s3"` 也是 12 个，
只是用多个空格做视觉对齐。

## 三、不用 areas 时：span 的组合表

卡片数多、需要动态生成时，用 span 更方便。关键是**预先算好合法的行组合**。

12 列的合法行组合（按常用度排序）：

| 组合 | 用法 |
| --- | --- |
| `12` | 满宽横条（列表、公告、图表） |
| `6 + 6` | 两张中等卡 |
| `8 + 4` | 主次搭配，最常用的对比行 |
| `7 + 5` | 主次搭配，比 8+4 更强调主卡 |
| `4 + 4 + 4` | 三张等重卡 |
| `3 + 3 + 3 + 3` | 四个小指标 |
| `3 + 3 + 6` | 两个小卡 + 一个中等卡 |
| `6 + 3 + 3` | 中等卡 + 两个小卡 |

**不要出现**：`5 + 5`（剩 2 列空洞）、`7 + 4`（剩 1 列）、`9 + 2`（剩 1 列）。

写生成逻辑时用「贪心填行」：

```ts
const COLUMNS = 12
const SPANS = [7, 5, 6, 6, 4, 4, 4, 3, 3, 3, 3]  // 按优先级排序的可用跨度

function packRows(cards: Card[]): Card[][] {
  const rows: Card[][] = []
  let current: Card[] = []
  let used = 0
  for (const card of cards) {
    const span = SPANS[Math.min(cards.indexOf(card), SPANS.length - 1)] ?? 3
    if (used + span > COLUMNS) { rows.push(current); current = []; used = 0 }
    current.push({ ...card, span })
    used += span
    if (used === COLUMNS) { rows.push(current); current = []; used = 0 }
  }
  if (current.length) rows.push(current)
  return rows
}
```

最后一行没填满时，把最后一张卡片的 span 拉长到填满剩余列，
或者让最后一行用 `grid-column: 1 / -1` 拉满。**不要留空洞。**

## 四、行高对齐的算术

用基准行 + span 时，实际高度是：

```
实际高度 = 基准行 × span + gap × (span − 1)
```

基准行 120、gap 16 时的常见组合：

| span | 实际高度 |
| --- | --- |
| 1 | 120 |
| 2 | 256 |
| 3 | 392 |
| 4 | 528 |
| 5 | 664 |

这些数字在设计稿里要对上。设计稿如果标的是 240px 高，
那实际是 `span 2` 得到 256px —— 有 16px 的差，
**要么改设计稿，要么把基准行调成 112px**（112×2+16 = 240）。

反过来说：**设计阶段就该用「基准行 + 间距」来标高度**，
而不是给每张卡片标一个绝对高度。否则实现时必然对不上。

## 五、内容溢出与高度自适应

`grid-auto-rows: 120px` 是固定值，内容超出会被裁掉或撑破。
两种处理：

### 方案 A：固定高度 + 内容裁剪（推荐）

```css
.bento-card { overflow: hidden; }
.bento-card__text {
  display: -webkit-box;
  -webkit-line-clamp: 3;      /* 最多 3 行 */
  -webkit-box-orient: vertical;
  overflow: hidden;
}
```

优点：布局稳定，网格永远对齐。
代价：长文本被截断。所以**卡片内的文案必须事先控制长度**
（标题 ≤ 20 字，描述 ≤ 40 字）。

### 方案 B：`minmax` 允许行高增长

```css
.bento {
  grid-auto-rows: minmax(120px, auto);
}
```

优点：内容不截断。
代价：**同一行的所有卡片高度会一起被最高的那张撑开**，
下一行的卡片位置全部下移，网格的「对齐感」被破坏。
只在内容长度不可控时用。

**推荐 A**。Bento 的价值在于对齐和节奏，一旦高度不固定，这个价值就没了。

## 六、动态卡片数量

卡片数量由数据决定时（比如「推荐模块」数量可变），要处理：

1. **数量 < 3**：不要用 Bento，退化成横向卡片列表或普通列表。
   只有 2 张卡片的 Bento 看起来很空。
2. **数量 = 5–9**：理想区间，按上文的权重分配。
3. **数量 > 9**：取权重最高的 8 张，其余放进「查看更多」。
   硬塞进去会让每张卡片都变小，重点丢失。
4. **数量为 0**：显示空状态（见 `mobile-onboarding` 技能的空状态部分），
   不要渲染一个空网格，那会留下一个大片空白。

排序规则要稳定：**相同权重时按固定顺序（如 ID）排**，
不要按时间倒序 —— 否则每次刷新卡片位置都变，用户永远建立不起空间记忆。

## 七、打印与导出

Bento 布局在导出 PDF / 截图时容易出问题：

- `grid` 在部分 PDF 渲染器里不被支持，会退化成块级堆叠。
  导出场景用 `flex-wrap` 加固定宽度百分比更保险。
- `overflow: hidden` 裁掉的内容在打印时**不会**显示。
  打印样式里要把 `-webkit-line-clamp` 去掉，并允许行高增长：

```css
@media print {
  .bento { display: block; }
  .bento-card { break-inside: avoid; margin-bottom: 16px; }
  .bento-card__text { -webkit-line-clamp: unset; overflow: visible; }
}
```

## 八、调试清单

- [ ] 每个断点的 areas 字符串词数是否等于列数（少一个词整条声明失效）
- [ ] 每行 span 之和是否等于列数（用 DevTools 的 Grid 高亮检查空洞）
- [ ] 基准行 × span + gap × (span−1) 是否和设计稿标的高度一致
- [ ] 最长的一条文案在最小断点下是否被 `line-clamp` 截断（截断了就要改文案）
- [ ] Tab 键遍历顺序是否和视觉顺序一致
- [ ] 卡片数为 0 / 1 / 2 / 10 时布局是否仍然正常
- [ ] 200% 系统缩放（浏览器 200% zoom）下是否溢出
- [ ] 打印预览里是否退化成单列且内容完整
