---
name: "glassmorphism-ui"
description: "要用玻璃拟态做卡片、导航栏或浮层时使用：backdrop-filter 的性能代价、模糊与透明度取值、边框高光做法与禁用场景。"
version: "1.0.0"
license: "MIT"
author: "Skill Hub"
category: ui
tags: ["UI 风格", "backdrop-filter", "毛玻璃", "边框高光", "性能优化", "降级方案", "可读性"]
---

# 玻璃拟态（Glassmorphism）

玻璃拟态的本质不是「模糊」，而是**让用户感知到图层之间的深度关系**：
前景是磨砂玻璃，背景还在那里，只是被模糊和去饱和了。
所以它成立的前提是**背景必须有内容**。纯色背景上的玻璃 = 一块半透明色块。

## 何时使用

- 做悬浮导航栏、浮动操作面板、侧边抽屉、通知卡片
- 需要「内容从下面滚过去」的层次感（顶部 header 压住列表）
- 登录页、落地页上想要一点现代感
- 已经用了但感觉「脏」「糊」「卡」，需要调参

## 核心规则

1. **模糊半径 12–20px 是甜区**，全屏遮罩可以到 24–40px。
   - `< 4px`：看起来像没生效或者屏幕有脏点
   - `12–20px`：文字还能辨认出「那里有东西」，玻璃感最明确
   - `> 24px`：背后变成一片糊，失去深度线索，且 GPU 开销线性上升
   - 圆角处模糊半径会被裁剪，圆角越大越容易看出模糊边缘的锯齿

2. **填充色的透明度取 0.12–0.35（浅色主题）/ 0.30–0.55（深色主题）。**
   低于 0.10 玻璃层几乎消失，文字直接压在背景图上无法阅读；
   高于 0.55 就变成普通的半透明面板，玻璃感没了。
   深色主题要更高是因为深色下背景和填充的亮度差更小，需要更多不透明度才能拉出层次。

3. **必须给玻璃层加 1px 高光边框**，这是「玻璃」和「半透明色块」的唯一视觉区别。
   做法是三件事叠加：

   ```css
   border: 1px solid rgba(255, 255, 255, 0.18);
   box-shadow:
     inset 1px 1px 0 rgba(255, 255, 255, 0.35),   /* 左上内高光，模拟边缘折射 */
     0 8px 32px rgba(31, 38, 135, 0.15);          /* 外阴影，撑开层次 */
   ```

   只加外阴影不加内高光，玻璃会显得「贴」在背景上而不是浮在上面。

4. **文字对比度必须按「最坏情况背景」验证。**
   玻璃层背后的内容是不确定的（用户头像、封面图、任意滚动内容），
   不能按当前这张图去测对比度。做法：
   - 玻璃层上要放正文时，填充不透明度提到 **≥ 0.6**，或
   - 在文字后面再加一层独立的实心/近实心 scrim（不透明度 ≥ 0.7）
   - 目标是**最坏情况下**正文仍 ≥ 4.5:1、大字 ≥ 3:1

5. **同屏可见的玻璃层不超过 3 层。**
   每多一层 backdrop-filter，GPU 就要多一次离屏渲染 + 采样。
   嵌套 3 层以上时，中端 Android 机型上滚动帧率会掉到 30fps 以下。
   而且视觉上多层叠加会让模糊「越糊越糊」，最终失去层次。

6. **`backdrop-filter` 生效区域不要超过视口的 30%，且不要覆盖正在播放的视频/动画。**
   原因：模糊的内容每帧都在变，浏览器必须每帧重新采样 backdrop。
   一个覆盖全屏、背后是视频的玻璃层，是移动端最典型的掉帧来源。
   悬浮导航栏（占视口 8–12%）是安全区。

7. **必须尊重系统的「减少透明度」设置。**

   ```css
   @media (prefers-reduced-transparency: reduce) {
     .glass { backdrop-filter: none; background: var(--surface-solid); }
   }
   ```

   iOS 的「辅助功能 → 显示与文字大小 → 降低透明度」、Windows 的「透明效果」
   打开后，用户明确表达了「我要不透明」，无视这个设置是最常见的无障碍投诉之一。

## 怎么做

### 1. 一个可直接用的玻璃卡片

```css
.glass-card {
  position: relative;
  padding: 20px 24px;
  border-radius: 16px;

  /* 半透明白填充 */
  background: rgba(255, 255, 255, 0.16);

  /* 模糊 + 提饱和：saturate 让背后的颜色更艳，玻璃才有"活"的感觉 */
  -webkit-backdrop-filter: blur(16px) saturate(180%);
  backdrop-filter: blur(16px) saturate(180%);

  /* 高光边框 + 内高光 + 外阴影 */
  border: 1px solid rgba(255, 255, 255, 0.18);
  box-shadow:
    inset 1px 1px 0 rgba(255, 255, 255, 0.35),
    0 8px 32px rgba(31, 38, 135, 0.15);

  /* 让子元素不受 backdrop-filter 的混合影响 */
  isolation: isolate;
}

/* 兜底：不支持时退化为近实心面板 */
@supports not ((backdrop-filter: blur(1px)) or (-webkit-backdrop-filter: blur(1px))) {
  .glass-card { background: rgba(255, 255, 255, 0.92); }
}
```

`saturate(180%)` 不是必须的，但加上之后玻璃后面的颜色会更浓，
这正是 Apple 的 vibrancy 效果的关键 —— 单纯 blur 会显得灰扑扑。

### 2. 背景要「有东西可糊」

玻璃层的效果 70% 取决于背景。三种可用的背景：

| 背景类型 | 效果 | 注意 |
| --- | --- | --- |
| 彩色渐变 + 色块 | 最好，能明显看出模糊 | 渐变里至少放 2–3 个不同色相的色块 |
| 高质量照片 | 好，但对比度不可控 | 文字必须加 scrim |
| 纯色 | 玻璃完全不可见 | 不要用玻璃拟态 |

纯色背景上做玻璃，用户看到的就是「一块稍微浅一点的方块」。
如果产品只有纯色背景，用**柔和阴影 + 微妙描边**表达层次，比硬上玻璃效果好。

### 3. 深色主题的玻璃

深色下不要用「黑色 + 低透明度」，要用「白/主色调 + 低透明度」：

```css
/* 深色主题 */
.glass-card--dark {
  background: rgba(255, 255, 255, 0.08);
  border: 1px solid rgba(255, 255, 255, 0.12);
  box-shadow:
    inset 1px 1px 0 rgba(255, 255, 255, 0.16),
    0 8px 32px rgba(0, 0, 0, 0.4);
  -webkit-backdrop-filter: blur(20px) saturate(140%);
  backdrop-filter: blur(20px) saturate(140%);
}
```

深色下的 saturate 要降到 140% 左右 —— 180% 在深色底上会让颜色脏掉。
模糊半径反而要**加大**（20px 起），因为深色下模糊的视觉差异更难看出来。

### 4. 悬浮导航栏的标准做法

```css
.app-header {
  position: sticky;
  top: 0;
  z-index: 100;
  height: 56px;
  padding: 0 16px;
  display: flex;
  align-items: center;

  background: rgba(255, 255, 255, 0.72);
  -webkit-backdrop-filter: blur(20px) saturate(180%);
  backdrop-filter: blur(20px) saturate(180%);
  border-bottom: 1px solid rgba(255, 255, 255, 0.18);
}

/* 滚动前不加阴影，滚动后才加 —— 避免静态页面就有一条阴影线 */
.app-header[data-scrolled='true'] {
  box-shadow: 0 1px 0 rgba(0, 0, 0, 0.06), 0 4px 16px rgba(0, 0, 0, 0.06);
}
```

导航栏的填充不透明度要高（0.6–0.8），因为它上面要放标题和按钮，
对比度优先级高于玻璃感。

### 5. 什么时候不该用

- **文字密集的界面**：表格、表单、代码编辑器、长文阅读。玻璃会让每个字都要和背景搏斗
- **中低端机型为主的产品**：如果目标用户的设备是 2019 年前后的中端 Android，
  全屏玻璃是明确的性能负收益
- **无障碍要求高的场景**：政务、医疗、金融的正式流程页面，
  用户可能有低视力或对透明度敏感，实心界面更可靠
- **背景是纯色或纯白**：玻璃不可见，纯属浪费 GPU
- **背后是视频 / 高频动画**：每帧重采样，必掉帧
- **打印和截图为主的页面**：模糊在导出时经常丢失，变成半透明色块

### 6. 性能自查方法

1. Chrome DevTools → Rendering → 勾选 **Paint flashing**，滚动时看玻璃区域是否每帧重绘
2. Performance 面板录制滚动，看 `Composite Layers` / `Paint` 是否吃掉 > 8ms
3. 真机测试，不要只在桌面浏览器测。桌面 GPU 比手机强一个数量级
4. 用 `document.querySelectorAll('*')` 数一下页面里有多少个 `backdrop-filter` 元素

## 检查清单

- [ ] 模糊半径在 12–20px（卡片）/ 24–40px（全屏遮罩）
- [ ] 浅色填充不透明度 0.12–0.35，深色 0.30–0.55
- [ ] 有 1px 高光边框 + inset 内高光 + 外阴影三件套
- [ ] 玻璃上的正文在最坏背景（深色照片）下对比度 ≥ 4.5:1
- [ ] 同屏玻璃层 ≤ 3 层
- [ ] 玻璃区域占视口 < 30%，且不覆盖视频
- [ ] `@supports not (backdrop-filter)` 有降级为实心面板
- [ ] `prefers-reduced-transparency: reduce` 时关闭模糊
- [ ] 真机（中端 Android）滚动 60fps 稳定
- [ ] 圆角处没有模糊边缘的锯齿
- [ ] 深色主题单独调过参数，不是简单反色
- [ ] `backdrop-filter` 前缀 `-webkit-` 已补（Safari 需要）

## 常见错误

| 错误做法 | 为什么错 | 正确做法 |
| --- | --- | --- |
| 纯色背景上用玻璃 | 玻璃完全不可见，只看到一块浅色方块 | 换背景，或改用阴影 + 描边表达层次 |
| 模糊半径写 60px | GPU 开销大，背景全糊，失去深度线索 | 卡片 12–20px，遮罩 24–40px |
| 填充透明度 0.05 | 文字直接压在背景图上，完全读不了 | 提到 0.12 以上，正文区 ≥ 0.6 |
| 只写 `backdrop-filter` 不写 `-webkit-` 前缀 | 老版本 Safari / iOS WebView 上完全没效果 | 两个都写 |
| 祖先元素有 `filter` 或 `opacity: 0.99` | 会创建 Backdrop Root，玻璃只能模糊该祖先内部的内容，表现为「模糊失效」 | 去掉祖先的 filter/opacity/mask，或把玻璃元素提到该祖先之外 |
| 玻璃层里再套玻璃层套 3 层 | 每层一次离屏渲染，中端机掉到 30fps | 最多 3 层，且不要嵌套 |
| 背后放自动播放的视频 | 每帧重采样 backdrop，帧率直接崩 | 视频上不要叠玻璃，用实心 scrim |
| 忽略 `prefers-reduced-transparency` | 无障碍设置失效，用户投诉 | 加媒体查询降级为实心 |
| 深色主题直接把浅色参数反相 | 深色下玻璃变脏、发灰 | 深色用白色 8% 填充 + 更大模糊半径 |
| 用 `opacity` 代替 `background: rgba()` | `opacity` 会连子元素一起变透明，文字也跟着淡 | 用 rgba 背景色，不用 opacity |

## 参考

- 需要完整的性能测量流程、Backdrop Root 的成因排查、跨浏览器兼容矩阵时，读 `references/performance-and-fallbacks.md`
