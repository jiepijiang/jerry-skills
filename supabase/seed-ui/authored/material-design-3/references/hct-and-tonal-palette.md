# HCT 色彩空间与色调调板生成

## 为什么是 HCT 而不是 HSL / HSV

HSL 的问题在于「明度」不感知：`hsl(60, 100%, 50%)` 的黄和 `hsl(240, 100%, 50%)` 的蓝
L 值都是 50%，但人眼看黄的亮度远高于蓝。用 HSL 生成色板，黄色系的对比度会系统性偏低。

HCT = **H**ue（CAM16 色相）+ **C**hroma（CAM16 色度）+ **T**one（CIELAB 的 L\*）。
- Hue 0–360，和 CAM16 一致，对蓝紫色的感知均匀性好于 HSL
- Chroma 无上界（实际 0–~120），0 是灰，越大越艳；同一个 chroma 在不同色相下「艳的程度」感知接近
- Tone 0–100，等于 CIELAB 的 L\*，**tone 50 就是感知中灰**

关键性质：**任意 hue / chroma 下，tone 相同时相对亮度（relative luminance）几乎相同**。
所以「tone 40 配 tone 100 的文字」这套对比度关系在所有色相上都成立 —— 这正是 M3 敢把
角色固定映射到 tone 的前提。

## tone 到对比度的换算表

WCAG 的对比度用相对亮度算，而 L\* 和相对亮度 Y 的关系是：
`Y = 100 * ((L* + 16) / 116)^3`（L\* > 8 时；更小时走线性段）。

| 前景 tone | 背景 tone | 近似对比度 | 可用范围 |
| --- | --- | --- | --- |
| 10 | 90 | 12.6:1 | 正文、AAA |
| 10 | 98 | 15.8:1 | 正文、AAA |
| 30 | 90 | 5.4:1 | 正文、AA |
| 40 | 98 | 8.6:1 | 正文、AAA |
| 40 | 90 | 6.4:1 | 正文、AA |
| 50 | 90 | 3.5:1 | 仅大字 / 图标 |
| 60 | 30 | 2.6:1 | 仅装饰、边框 |
| 80 | 30 | 5.1:1 | 深色模式正文 |
| 90 | 10 | 12.6:1 | 深色模式正文 |

结论：**正文配对要求 tone 差 ≥ 40**；tone 差 20–30 只能用于大字、图标、分隔线。

## 生成一套完整调板

```ts
import {
  Hct, TonalPalette, argbFromHex, hexFromArgb,
  MaterialDynamicColors, SchemeTonalSpot,
} from '@material/material-color-utilities'

const seed = Hct.fromInt(argbFromHex('#4C662B'))
const isDark = false

// 六组调板（hue / chroma 的取法来自官方默认算法）
const primary       = TonalPalette.fromHueAndChroma(seed.hue, 36)
const secondary     = TonalPalette.fromHueAndChroma(seed.hue, 16)
const tertiary      = TonalPalette.fromHueAndChroma(seed.hue + 60, 24)  // 旋转 60° 做点缀色
const neutral       = TonalPalette.fromHueAndChroma(seed.hue, 4)
const neutralVariant= TonalPalette.fromHueAndChroma(seed.hue, 8)
const error         = TonalPalette.fromHueAndChroma(25, 84)

// 角色映射（浅色）
const lightScheme = {
  primary:                    primary.tone(40),
  onPrimary:                  primary.tone(100),
  primaryContainer:           primary.tone(90),
  onPrimaryContainer:         primary.tone(10),
  surface:                    neutral.tone(98),
  onSurface:                  neutral.tone(10),
  surfaceContainerLowest:     neutral.tone(100),
  surfaceContainerLow:        neutral.tone(96),
  surfaceContainer:           neutral.tone(94),
  surfaceContainerHigh:       neutral.tone(92),
  surfaceContainerHighest:    neutral.tone(90),
  outline:                    neutralVariant.tone(50),
  outlineVariant:             neutralVariant.tone(80),
}
```

深色模式把每个角色的 tone 换成「100 减」的对称值（40↔80、90↔30、98↔6、10↔90），
**不是**把浅色值做反相或调透明度。深色下的 surface 是 tone 6，不是 `#000`，
原因见 `dark-mode-oled` 技能。

## 动态方案（Dynamic Scheme）变体

`material-color-utilities` 0.3.0 起提供多种 scheme 变体，都接收 `(sourceColorHct, isDark, contrastLevel)`：

| 变体 | 特征 | 适合 |
| --- | --- | --- |
| `SchemeTonalSpot` | 默认，chroma 保守，中性色偏灰 | 通用 |
| `SchemeContent` | 从源色提取更多色相变化，保留源色个性 | 跟随图片取色 |
| `SchemeFidelity` | 源色几乎原样保留，容器色偏暗 | 品牌色必须精准 |
| `SchemeVibrant` | 提高 chroma，色彩更跳 | 消费级 App 的活泼调性 |
| `SchemeExpressive` | hue 旋转幅度大，出现意外色相 | 需要强记忆点 |
| `SchemeNeutral` | 几乎全灰，只留一点色味 | 工具型 / 生产力 |
| `SchemeMonochrome` | chroma 归零，纯灰度 | 电子墨水、极简 |
| `SchemeRainbow` / `SchemeFruitSalad` | hue 大幅旋转，容器色相互错开 | 实验性 |

`contrastLevel` 取值 `-1 / 0 / 0.5 / 1`，对应「标准 / 中等 / 高 / 极高」对比度。
无障碍设置里打开「高对比度文字」时应把 contrastLevel 提到 0.5 或 1，
它会自动把 on-color 的 tone 推向极端（10 或 100），而不改变色相。

## 从图片取色

```ts
import { sourceColorFromImage } from '@material/material-color-utilities'

const sourceColor = await sourceColorFromImage(imgEl)  // 需要图片已加载且同源/带 CORS
const theme = themeFromSourceColor(sourceColor)
```

`sourceColorFromImage` 内部会做量化 + 打分（偏好彩度高、非极端的色），
比 `canvas.getImageData` 取平均色靠谱得多 —— 平均色在自然照片上几乎总是脏灰。

注意：图片取色必须在图片 `load` 之后再调，且跨域图片需要 `crossOrigin="anonymous"`，
否则 canvas 被污染会抛 SecurityError。

## 手动校色时的取舍

- **品牌色必须保留**：用 `SchemeFidelity`，或把品牌色直接当 tone 40 用，
  再用 `Hct.from(h, c, 40)` 反推出该 tone 下的实际色值。
- **品牌色太艳**：降 chroma 到 36 附近。chroma 60 以上的容器色（tone 90）会显得塑料。
- **品牌色是纯黑 / 纯白**：chroma 为 0，无法派生有色调板。此时把 hue 手动指定为
  品牌辅助色的 hue，只取 chroma 16 给 secondary。
- **品牌色是荧光色（chroma > 90）**：tone 40 下会超出 sRGB 色域被裁剪，
  表现为「设计稿和实现不一致」。降 chroma 或改用 P3 色彩空间。

## 常见坑

- `argbFromHex('#FFF')` 三位缩写**不支持**，必须先展开成六位
- `Hct.fromInt` 需要的是 ARGB int（含 alpha 通道），不是 RGB
- `TonalPalette.tone(n)` 返回的是 ARGB int，Web 上要 `hexFromArgb()` 再转成 CSS 值
- 自己算 tone 到 hex 时忘了 sRGB 色域裁剪，会出现负值或 >255 的通道
