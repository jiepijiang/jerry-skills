---
name: "bento-grid-ui"
description: "用 Bento 网格排布首页、仪表盘或功能入口时使用：栅格与跨行列规则、视觉权重分配、避免每张卡片都当主角、响应式塌陷。"
version: "1.0.0"
license: "MIT"
author: "Skill Hub"
category: ui
tags: ["UI 风格", "Bento 网格", "栅格系统", "视觉权重", "响应式塌陷", "卡片布局", "焦点顺序"]
---

# Bento 网格（便当盒布局）

Bento 的本质是**用尺寸表达重要性**：大格子 = 重要，小格子 = 次要。
所以它失败的方式永远是同一种 —— **每个格子都想当主角**，
最后用户看到的是一堆等重的方块，优先级信息全部丢失。

## 何时使用

- 做产品首页、仪表盘、功能入口页、营销落地页的模块排布
- 已有栅格但「看起来乱」「找不到重点」「滚动时格子高度对不齐」
- 需要在一屏内同时展示指标、快捷入口和内容推荐

## 核心规则

1. **列数按断点固定，不要用 `auto-fit` 随波逐流。**

   | 视口宽度 | 列数 | 间距 |
   | --- | --- | --- |
   | ≥ 1280 | 12 | 24px |
   | 1024–1279 | 8 | 20px |
   | 768–1023 | 6 | 16px |
   | 640–767 | 4 | 16px |
   | < 640 | 2 | 12px |

   `repeat(auto-fill, minmax(240px, 1fr))` 的问题是列数会随容器宽度连续变化，
   于是「跨 2 列」的卡片在不同宽度下占的比例完全不同，视觉权重失控。
   Bento 要的是**离散的列数**。

2. **行高用「基准行 + 跨行」，不要给每张卡片写死高度。**
   基准行 `grid-auto-rows: 120px`，卡片用 `grid-row: span 2`。
   这样 2 行高的卡片实际高度 = 120×2 + 16(间距) = 256px。
   写死高度的问题是：一行里有 3 张卡片，其中一张内容多了 8px，
   整行高度被撑开，其他卡片出现空洞。

   ```css
   .bento {
     display: grid;
     grid-template-columns: repeat(12, 1fr);
     grid-auto-rows: 120px;      /* 基准行 */
     gap: 16px;
   }
   ```

3. **视觉权重遵守「1 : 2 : 4」预算。**
   一个 Bento 区域里，卡片按尺寸分三档，数量比例大约是：
   - **主角卡 1 个**：跨 6–8 列 × 2 行（或跨 4 列 × 3 行）
   - **次要卡 2–3 个**：跨 4 列 × 2 行，或跨 6 列 × 1 行
   - **小卡 4–6 个**：跨 3 列 × 1 行，或跨 2 列 × 1 行

   总卡片数控制在 **5–9 张**。超过 9 张就不是 Bento 了，
   那是一个仪表盘，应该用等宽网格。

4. **每张卡片最多在一个维度上「拉满」。**
   可用的强调手段有五个：尺寸、色彩饱和度、图片面积、字号、动效。
   一张卡片同时用「大尺寸 + 高饱和背景 + 大图 + 超大数字」，
   其他卡片就完全被压死了。规则：**主角卡可以用 2 个，其他卡最多 1 个**。

5. **左上角是最高注意力位，放最重要的内容。**
   用户的扫描路径是 F 型（先横后竖），所以：
   - 主角卡放左上
   - 第二重要放主角卡右侧或正下方
   - 说明性、次要入口放右下
   用 `grid-template-areas` 显式表达这个顺序，别靠自动排布碰运气。

6. **不要用 `order` 做视觉重排。**
   `order` 只改视觉顺序，不改 DOM 顺序，而**焦点顺序（Tab 键）跟的是 DOM**。
   用 `order` 重排后，键盘用户的焦点会跳来跳去（WCAG 2.4.3 焦点顺序）。
   需要重排就改 DOM 顺序，或者用 `grid-template-areas` 把位置写清楚 ——
   但即使如此，DOM 顺序仍要和视觉顺序大致一致。

7. **`grid-auto-flow: dense` 慎用。**
   它能填补空洞，但代价是**视觉顺序和 DOM 顺序脱钩**，
   屏幕阅读器读出来的顺序会变得无法预测。只在纯装饰性的场景用。

8. **同一区域内圆角只用一档。** 20px 或 24px，选一个。
   大卡 24 / 小卡 20 这种「按尺寸分档」看起来有道理，
   实际并排时会出现 4px 的视觉错位，非常明显。

## 怎么做

### 1. 用 grid-template-areas 显式定义（推荐）

小规模（5–7 张）时，`grid-template-areas` 最清晰：

```css
.bento {
  display: grid;
  grid-template-columns: repeat(12, 1fr);
  grid-auto-rows: 120px;
  gap: 16px;

  grid-template-areas:
    "hero hero hero hero hero hero hero stat stat stat stat stat"
    "hero hero hero hero hero hero hero stat stat stat stat stat"
    "quick quick quick quick list list list list list list list list"
    "quick quick quick quick list list list list list list list list";
}

.bento__hero  { grid-area: hero; }   /* 7 列 × 2 行 = 主角 */
.bento__stat  { grid-area: stat; }   /* 5 列 × 2 行 */
.bento__quick { grid-area: quick; }  /* 4 列 × 2 行 */
.bento__list  { grid-area: list; }   /* 8 列 × 2 行 */
```

用 areas 的好处是**换行、换列时改字符串就行**，不用改每个子元素。

### 2. 用 span 自动排布（卡片数多时）

```css
.bento__hero  { grid-column: span 6; grid-row: span 2; }
.bento__card  { grid-column: span 4; grid-row: span 2; }
.bento__small { grid-column: span 3; grid-row: span 1; }
.bento__wide  { grid-column: span 8; grid-row: span 1; }
```

关键约束：**每行必须正好占满 12 列**，否则右侧会出现空洞。
排布前先在纸上算一遍：`6+6 / 4+4+4 / 3+3+3+3 / 8+4` 都是合法行。

用 `grid-column: span N` 时，如果某行的剩余列数不够，
卡片会被推到下一行，留下一个洞。**永远用明确的 span 组合，
不要指望浏览器帮你排满。**

### 3. 卡片内部的结构

```css
.bento-card {
  display: flex;
  flex-direction: column;
  justify-content: space-between;
  padding: 24px;                 /* 移动端降到 20px */
  border-radius: 24px;           /* 全区域统一一档 */
  background: var(--surface-container-low);
  overflow: hidden;              /* 防止内部图片溢出圆角 */
}

.bento-card__label {
  font-size: 13px;
  line-height: 1.4;
  color: var(--on-surface-variant);
}

.bento-card__value {
  font-size: 40px;               /* 小卡 28px，主角卡 56px */
  font-weight: 600;
  line-height: 1.1;
  letter-spacing: -0.02em;       /* 大字号需要负字距，否则显得散 */
  font-variant-numeric: tabular-nums;   /* 数字对齐，刷新时不跳动 */
}
```

字号与卡片尺寸的对应：主角（7×2）标签 14 / 数值 48–56 / 内边距 32；
中等（4×2）13 / 32–40 / 24；小（3×1）12 / 24–28 / 20。

`tabular-nums` 是必须的：指标卡的数字每秒刷新时，
如果字宽不等，整行会左右抖动。

### 4. 响应式塌陷

塌陷不是「列数变少」这么简单，要同时处理三件事：

```css
@media (max-width: 1023px) {
  .bento {
    grid-template-columns: repeat(6, 1fr);
    gap: 16px;
    grid-auto-rows: 104px;
    /* 重新定义 areas：主角从 7 列变 6 列（满宽） */
    grid-template-areas:
      "hero hero hero hero hero hero"
      "hero hero hero hero hero hero"
      "stat stat stat quick quick quick"
      "list list list list list list"
      "list list list list list list";
  }
}

@media (max-width: 639px) {
  .bento {
    grid-template-columns: repeat(2, 1fr);
    gap: 12px;
    grid-auto-rows: 96px;
    grid-template-areas:
      "hero hero"
      "hero hero"
      "stat quick"
      "list list"
      "list list";
  }
  .bento-card { padding: 20px; border-radius: 20px; }
  .bento-card__value { font-size: 28px; }
}
```

三条规则：
1. **主角卡永远保持最大**（在移动端就是占满整行）。塌陷时不要把所有卡片都变成单列，
   那样优先级信息就丢了。
2. **间距和基准行高一起缩小**：24→16→12，120→104→96。
   只缩间距不缩行高，移动端每张卡片会显得过于空。
3. **移动端最多 2 列**。1 列会让 Bento 退化成普通列表，
   失去「用尺寸表达重要性」的能力 —— 这时候不如直接用列表。

### 5. 内容优先级怎么定

给每张候选卡片打一个权重分，按分数决定尺寸：

| 维度 | 权重 |
| --- | --- |
| 是否是当前页面的核心任务 | +40 |
| 是否需要用户立刻行动 | +25 |
| 是否包含实时/动态数据 | +15 |
| 是否是高频使用（日均 ≥ 1 次） | +10 |
| 是否只是「说明性」内容 | −20 |

- 分数最高的一张 → 主角卡（6–8 列 × 2 行）
- 60 分以上 → 中等卡（4 列 × 2 行）；其余 → 小卡（3 列 × 1 行）
- 分数为负 → 不放这一屏，或放到最底部的横条

**核心任务永远只有一件**。如果算出来有两张 40 分以上的核心任务卡，
说明信息架构有问题，先解决那个，别指望用布局解决。

## 检查清单

- [ ] 列数在各断点是 12 / 8 / 6 / 4 / 2，且用 `repeat(N, 1fr)` 而非 `auto-fill`
- [ ] 行高用 `grid-auto-rows` 基准行 + `span`，没有写死高度的卡片
- [ ] 每一行的 `span` 之和正好等于列数，右侧无空洞
- [ ] 全区域只有一个主角卡（跨 ≥ 6 列或 ≥ 2 行且用强调样式）
- [ ] 卡片总数在 5–9 张之间
- [ ] 每张卡片最多在 2 个维度上强调（主角卡）/ 1 个维度（其他卡）
- [ ] 主角卡在 DOM 顺序和视觉位置上都在最前
- [ ] 没有用 `order` 做重排；用 `grid-auto-flow: dense` 的地方有理由
- [ ] 圆角全区域统一一档
- [ ] 数值用 `tabular-nums`，刷新时不抖动
- [ ] 640px 以下仍保持 2 列（没有退化成单列）
- [ ] 每张卡片单独看都能理解（不依赖相邻卡片的上下文）
- [ ] Tab 键遍历顺序与视觉顺序一致
- [ ] 卡片内文字在 200% 系统缩放下不溢出（`overflow: hidden` 会截断，需要检查）

## 常见错误

| 错误做法 | 为什么错 | 正确做法 |
| --- | --- | --- |
| `repeat(auto-fit, minmax(240px, 1fr))` | 列数连续变化，「跨 2 列」的比例失控 | 按断点用固定列数 |
| 每张卡片写死 `height: 240px` | 内容多 8px 就撑破整行，出现空洞 | `grid-auto-rows` + `span` |
| 每张卡片都是高饱和背景 | 没有重点，视觉疲劳，扫描速度下降 | 1 张主角 + 其余中性色 |
| 9 张以上卡片塞进一个 Bento | 退化成仪表盘，尺寸失去意义 | 砍到 5–9 张，或改成等宽网格 |
| 用 `order` 把重要卡片提到前面 | 焦点顺序跟 DOM，键盘用户会跳乱 | 改 DOM 顺序或用 areas |
| 移动端塌陷成单列 | Bento 退化为普通列表，白做了 | 保持 2 列，主角占满整行 |
| 大卡 24px / 小卡 20px 圆角 | 并排时出现 4px 错位，很显眼 | 全区域统一一档 |
| 数字不加 `tabular-nums` | 实时数据刷新时整行左右抖动 | 加 `font-variant-numeric: tabular-nums` |
| 卡片内容依赖相邻卡片 | 响应式重排后语义断裂 | 每张卡片自包含 |
| 行内 span 之和是 11 列 | 右侧留一个 1 列宽的空洞 | 排布前先算清每行的 span 组合 |
| 用 `grid-auto-flow: dense` 填洞 | 视觉顺序与 DOM 脱钩，读屏顺序混乱 | 手工调整 span 组合 |

## 参考

- 需要复杂的响应式塌陷策略、`grid-template-areas` 的完整重写方案、
  或卡片数量会动态变化时的排布算法时，读 `references/responsive-collapse.md`
