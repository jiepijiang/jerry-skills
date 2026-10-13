---
name: "material-design-3"
description: "在 Android 或 Web 上落地 Material Design 3 时使用：动态取色与色调调板、表面分层与形状刻度、组件尺寸规范，以及从 M2 迁移到 M3 的差异清单。"
version: "1.0.0"
license: "MIT"
author: "Skill Hub"
category: ui
tags: ["APP 移动端", "动态取色", "HCT 色彩空间", "色调调板", "Elevation 分层", "形状刻度", "M2 迁移"]
---

# Material Design 3 落地手册

M3 不是「M2 换了个圆角」。它的核心变化是**颜色由色调（tone）派生而不是手写十六进制**，
以及**层级由表面色差而不是阴影表达**。把这两条搞错，做出来就是个换了配色的 M2。

## 何时使用

- 从零搭一个遵循 M3 的 Android / Compose 应用，或 Flutter / Web 上复刻 M3
- 已有 M2 项目要迁移到 M3，需要知道哪些数值变了
- 要接「动态取色」（Material You），跟随用户壁纸生成主题
- 组件尺寸对不上：按钮高度、FAB 大小、底部导航高度和官方规范不一致

## 核心规则

1. **颜色只从 5 组色调调板（tonal palette）里取，禁止手写 `#6750A4` 之外的随机色值。**
   调板是 primary / secondary / tertiary / neutral / neutral-variant / error 六组，
   每组含 tone 0、10、20、30、40、50、60、70、80、90、95、99、100 共 13 档。
   手写色值等于放弃了暗色模式、对比度校验和动态取色三件事。

2. **角色（role）到 tone 的映射是固定的**，不要凭感觉选：

   | 角色 | 浅色 tone | 深色 tone |
   | --- | --- | --- |
   | primary / on-primary | 40 / 100 | 80 / 20 |
   | primary-container / on-primary-container | 90 / 10 | 30 / 90 |
   | surface / on-surface | 98 / 10 | 6 / 90 |
   | surface-variant / on-surface-variant | 90 / 30 | 30 / 80 |
   | outline / outline-variant | 50 / 80 | 60 / 30 |
   | error / on-error | 40 / 100 | 80 / 20 |

   相邻两档 tone 差 ≥ 40 时，正文对比度基本落在 4.5:1 以上；差 30 只能算合格的大字对比。

3. **动态取色必须带降级路径。** Android 12（API 31）才有壁纸取色，
   低版本或用户关闭「主题颜色」时要回落到种子色方案。
   Compose 里判断 `Build.VERSION.SDK_INT >= 31`，不要直接调 `dynamicLightColorScheme`。

4. **层级用 surface 容器角色表达，不要靠叠加阴影。**
   M3 更新后的规范给了 5 档容器色：
   `surface-container-lowest` → `low` → `container` → `high` → `highest`，
   它们之间的 tone 差是 4 左右（浅色下 100 / 96 / 94 / 92 / 90）。
   一个卡片浮起来，靠的是容器色 + 一层极浅阴影，不是 `box-shadow: 0 8px 24px`。

5. **形状走圆角刻度，不要随手写 10px。**
   刻度是 none 0 / xs 4 / s 8 / m 12 / l 16 / xl 28 / full 999。
   默认组件用哪一档：按钮 full、卡片 m(12)、对话框 xl(28)、FAB l(16)、
   底部抽屉 top l(16)、文本字段 xs(4)、chip s(8)。

6. **触摸目标最小 48×48dp**，视觉尺寸可以更小。
   Icon button 视觉 40×40，但热区必须撑到 48。
   这条是 Android 无障碍扫描的硬门槛，不达标会被标记。

7. **组件尺寸按官方数值来**，常见的一组：
   按钮高 40dp（密集场景 32，大按钮 48 用在大屏/主 CTA）、
   FAB 56dp（small 40、large 96、extended 高 56）、
   Navigation bar 高 80dp、Top app bar small 64 / medium 112 / large 152、
   Chip 高 32、Switch 轨道 52×32、Text field 高 56。
   随手写 44 或 60 会让整套组件看起来「哪里不对但说不上来」。

## 怎么做

### 1. 从种子色生成色调调板

Web / 跨端用 `@material/material-color-utilities`（官方维护的 TS 实现）：

```ts
import {
  argbFromHex, hexFromArgb,
  themeFromSourceColor, Hct, TonalPalette,
} from '@material/material-color-utilities'

// 方式一：只要一套完整 scheme
const theme = themeFromSourceColor(argbFromHex('#4C662B'))
const light = theme.schemes.light   // 含 primary / onPrimary / surfaceContainerHigh ...
const dark  = theme.schemes.dark

// 方式二：自己控制 chroma，做品牌色微调
const hct = Hct.fromInt(argbFromHex('#4C662B'))
const primary = TonalPalette.fromHueAndChroma(hct.hue, 36)
primary.tone(40)   // 浅色模式 primary
primary.tone(80)   // 深色模式 primary
```

各调板的默认 chroma（决定了「这个色有多艳」）：
primary 36、secondary 16、tertiary 24（hue 旋转 +60）、neutral 4、neutral-variant 8、error 60。
neutral 的 chroma 只有 4 —— 这就是为什么 M3 的灰面**永远带一点点主色味**，
手写 `#EEEEEE` 是纯灰，混进去一眼就假。

### 2. 接动态取色

Compose：

```kotlin
val colorScheme = when {
  Build.VERSION.SDK_INT >= Build.VERSION_CODES.S -> {
    if (dynamicColor) {
      if (darkTheme) dynamicDarkColorScheme(context)
      else dynamicLightColorScheme(context)
    } else fallbackScheme
  }
  else -> fallbackScheme
}
MaterialTheme(colorScheme = colorScheme, typography = AppTypography, shapes = AppShapes) { ... }
```

Web 上跟随壁纸取色做不到，退而求其次的做法是**从用户头像或上传的封面图取色**：

```ts
import { themeFromImage } from '@material/material-color-utilities'
const theme = await themeFromImage(imgElement)
```

再往下就是「用户手选一个品牌色」，用 `themeFromSourceColor` 生成整套。
三层降级顺序：壁纸 → 内容图 → 品牌种子色。

### 3. 用色调而非透明度做「禁用态」

M3 禁用态的规则是**固定透明度**，不是把颜色变灰：
内容 `on-surface` 38% alpha，容器 `on-surface` 12% alpha。
自己写 `color: #BDBDBD` 的问题是深色模式下这个灰会突然变得刺眼。
状态层（state layer）同理：hover 8%、focus 10%、pressed 10%、dragged 16%，
叠在内容色上，不是叠在容器色上。

### 4. 迁移 M2 → M3 的差异清单

| 维度 | M2 | M3 |
| --- | --- | --- |
| 字体命名 | h1–h6 / subtitle1-2 / body1-2 / button / caption / overline | display / headline / title / body / label，各 ×large/medium/small |
| 层级表达 | 纯阴影，6 档 elevation | 表面色调 + 浅阴影，0–5 档 |
| 默认圆角 | 4dp | 12dp（卡片），按钮全圆角 |
| 底部导航 | Bottom navigation 高 56dp | Navigation bar 高 80dp，带 active indicator 药丸 |
| 按钮高度 | 36dp | 40dp |
| FAB | 圆形 56dp | 圆角方形 r=16，56dp |
| 状态层 | 4% / 8% / 12% | 8% / 10% / 10% / 16% |
| 配色来源 | 1 个 primary + 1 个 secondary 手动配 | 种子色派生 6 组调板 ×13 tone |

迁移时**不要**逐个组件改，先换主题层（colorScheme / typography / shapes），
再跑一遍视觉回归，把「看起来变胖了」的组件单独修尺寸。

## 检查清单

- [ ] 全项目搜索 `#` 开头的十六进制颜色，除了种子色定义处，业务代码里应该为 0
- [ ] 深色模式下每个 surface 层级都能分辨（相邻容器色差 ≥ tone 4）
- [ ] 动态取色在 Android 11 及以下有降级，界面不崩不闪白
- [ ] 所有可点击元素热区 ≥ 48×48dp（用 Android 的「无障碍扫描」或 Flutter 的 `MaterialTapTargetSize` 校验）
- [ ] 正文对比度 ≥ 4.5:1，大字（≥18.66px bold 或 ≥24px）≥ 3:1
- [ ] 圆角只用刻度值：0 / 4 / 8 / 12 / 16 / 28 / full
- [ ] 按钮高度是 40 或 48，不是 44 / 50 / 56
- [ ] 禁用态用 38% / 12% 透明度，不是自定义灰色
- [ ] Top app bar 在滚动时切换的是容器色（`surface-container` ↔ `surface`），不是突然加深阴影

## 常见错误

| 错误做法 | 为什么错 | 正确做法 |
| --- | --- | --- |
| 手写 `#6750A4` 当 primary | 暗色模式下这个紫在白字上对比度不足，且完全无法跟随壁纸 | 从调板取 `primary.tone(40)` / `.tone(80)` |
| 用 `elevation` 阴影做层级 | M3 里阴影很弱，深色模式下几乎不可见，层级会塌掉 | 用 surface-container 五档容器色 |
| neutral 调板 chroma 设 0 | 灰面变纯灰，和彩色组件放一起显脏 | neutral chroma 4、neutral-variant 8 |
| 低版本 Android 直接调 `dynamicLightColorScheme` | API 31 以下无此能力，会回落或抛错 | 版本判断 + 种子色兜底 |
| 按钮写死 `height: 44px` | 不在规范刻度里，和系统组件并排时高度对不齐 | 40（默认）/ 32（密集）/ 48（大） |
| 禁用按钮把背景改成浅灰 | 深色模式下浅灰块比正常按钮还显眼 | 内容 38% alpha、容器 12% alpha |
| 迁移时把 h1–h6 直接映射到 displayLarge | 语义对不上，标题字号会突然暴涨 | h5/h6 → titleLarge/titleMedium，body1 → bodyLarge |
| 卡片圆角用 10px「看起来差不多」 | 与规范 12dp 的组件并排会出现 2px 错位，肉眼能看出来 | 严格用 12（m 档） |

## 参考

- 需要写完整的色调调板生成、对比度校验脚本，或要理解 HCT 为什么比 HSL 好用时，读 `references/hct-and-tonal-palette.md`
- 迁移老项目、需要逐组件对照表（含状态层、图标、对话框、Snackbar 差异）时，读 `references/m2-to-m3-migration.md`
