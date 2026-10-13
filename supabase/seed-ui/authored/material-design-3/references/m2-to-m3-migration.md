# Material 2 → Material 3 迁移逐项对照

迁移顺序很重要：**先主题、再布局、最后组件细节**。反过来做会反复返工。

## 阶段一：主题层（改动最大，风险最低）

### 配色

M2 的 `colorPrimary` / `colorSecondary` 是手配的两个色，
`colorPrimaryVariant` / `colorSecondaryVariant` 手动加深。
M3 把这一套扩成 26 个以上的角色，全部由种子色派生。

| M2 属性 | M3 对应 | 备注 |
| --- | --- | --- |
| `colorPrimary` | `primary` | tone 40 / 80 |
| `colorPrimaryVariant` | 无直接对应 | 用 `primaryContainer` 或 tone 30 |
| `colorOnPrimary` | `onPrimary` | |
| `colorSecondary` | `secondary` | chroma 从 36 降到 16 |
| `colorSurface` | `surface` | 从 `#FFFFFF` 变成 tone 98（带色味） |
| `colorBackground` | 无 | 已废弃，统一用 `surface` |
| `colorOnBackground` | `onSurface` | |
| `colorError` | `error` | |
| `android:colorControlHighlight` | state layer | 改为按交互类型分别设 alpha |

M3 **删除了 `background` / `onBackground`**，浅色 surface tone 98、深色 tone 6。
迁移时把 `background` 的引用全部改成 `surface`。

### 字体

M2 的 13 个样式 → M3 的 15 个角色。常用映射：

| M2 | M3 | 字号 / 行高 |
| --- | --- | --- |
| `h4` | `headlineSmall` | 24 / 32 |
| `h5` | `titleLarge` | 22 / 28 |
| `h6` | `titleMedium` | 16 / 24（weight 500） |
| `subtitle1` | `titleMedium` | 16 / 24 |
| `subtitle2` | `titleSmall` | 14 / 20（weight 500） |
| `body1` | `bodyLarge` | 16 / 24 |
| `body2` | `bodyMedium` | 14 / 20 |
| `button` | `labelLarge` | 14 / 20（weight 500） |
| `caption` | `bodySmall` | 12 / 16 |
| `overline` | `labelSmall` | 11 / 16（weight 500，去掉了强制大写） |

M3 的完整刻度（字号 / 行高，单位 sp）：

| 角色 | Large | Medium | Small |
| --- | --- | --- | --- |
| Display | 57 / 64 | 45 / 52 | 36 / 44 |
| Headline | 32 / 40 | 28 / 36 | 24 / 32 |
| Title | 22 / 28 | 16 / 24 | 14 / 20 |
| Body | 16 / 24 | 14 / 20 | 12 / 16 |
| Label | 14 / 20 | 12 / 16 | 11 / 16 |

行高比基本落在 1.25–1.45。`bodyLarge` 16/24 = 1.5，
中文正文建议在此基础上再加 0.05–0.1（即 24–26px 行高）。

### 形状

M2 只有一个 `shapeAppearanceSmall/Medium/Large`（4 / 4 / 0）。
M3 给出七档：

| 档位 | 圆角 |
| --- | --- |
| none | 0 |
| extra-small | 4 |
| small | 8 |
| medium | 12 |
| large | 16 |
| extra-large | 28 |
| full | 999（胶囊） |

组件默认档：Text field xs(4)、Chip s(8)、Card m(12)、FAB l(16)、
Dialog xl(28)、Button / Navigation indicator full。
M2 项目里大量 `4dp` 的卡片要改成 `12dp` —— 这是视觉上最明显的「变 M3 了」的信号。

## 阶段二：布局与容器

| 组件 | M2 | M3 |
| --- | --- | --- |
| 底部导航 | `BottomNavigationView`，高 56dp，选中色块在文字上 | `NavigationBar`，高 80dp，选中态是 64×32 的药丸 indicator |
| 抽屉 | `DrawerLayout` + 白色圆角 0 | 圆角 0→16（右侧边缘），宽度 360dp 上限 |
| App bar | `Toolbar`，滚动加阴影 | `TopAppBar` 三档：small 64 / medium 112 / large 152，滚动切换容器色 |
| 弹窗 | `AlertDialog` 圆角 4 | `BasicAlertDialog` 圆角 28 |
| 提示 | Snackbar 圆角 4 | 圆角 4，但上移到距底部导航 8dp 之上 |

NavigationBar 的高度从 56 涨到 80 是**必然的**，
不要为了「省空间」把它压回 56 —— indicator 药丸高 32 加上下 24 内边距就是 80。
压缩会导致 indicator 贴边、图标和 label 挤在一起。

## 阶段三：组件细节

### 按钮

| | M2 | M3 |
| --- | --- | --- |
| 高度 | 36dp | 40dp |
| 水平内边距 | 16dp | 24dp |
| 圆角 | 4dp | full |
| 图标与文字间距 | 8dp | 8dp |
| 变体 | Contained / Outlined / Text | Filled / Filled tonal / Elevated / Outlined / Text（5 种） |

M3 新增 `FilledTonalButton`（次要按钮，用 `secondaryContainer` 填充），
这是 M2 没有的一档，能有效减少界面上「到处都是主色按钮」的问题。

### 状态层（state layer）

| 交互 | M2 alpha | M3 alpha |
| --- | --- | --- |
| Hover | 4% | 8% |
| Focus | 8% | 10% |
| Pressed | 12% | 10% |
| Dragged | — | 16% |

M3 的状态层**叠在内容色之上**（`onSurface` 而不是 `surface`），
且 ripple 之外还要有 hover / focus 的常驻状态层（桌面端、键盘导航必须有）。

### 图标与触摸目标

图标默认 24dp 不变。但 M3 明确了：视觉尺寸 24，**触摸目标 48**。
Icon button 视觉容器 40×40（M3 从 M2 的 48 缩小了），
所以必须显式补 `Modifier.minimumInteractiveComponentSize()` 或 `LocalMinimumInteractiveComponentSize`。

### 禁用态

M2 用 38% / 12%（其实 M2 也是这个值），M3 保持一致但明确了：
- 内容（文字/图标）：`onSurface` 38% alpha
- 容器：`onSurface` 12% alpha
- 描边：`onSurface` 12% alpha

迁移时如果老代码用了 `Color.Gray` 之类的硬编码，全部替换。

## 阶段四：迁移后回归检查

1. 打开系统「深色模式」，逐屏检查有没有硬编码白/黑残留
2. 打开系统「高对比度文字」，确认 `contrastLevel` 生效且没有文字被裁切
3. 在 Android 12+ 上切换壁纸，确认主题跟着变且没有中间闪白
4. 用「无障碍扫描器」跑一遍，触摸目标 48dp 是最常见的失败项
5. 截图对比 M2 版本，重点看：卡片圆角、按钮高度、底部导航高度、
   灰色是否带色味、阴影是否过重

## 最容易踩的三个坑

1. **把 M3 当成「换色 + 加圆角」**。不做 surface-container 分层的话，
   深色模式下所有面都是一个色，层级彻底塌掉。
2. **直接映射 h1–h6 到 displayLarge 系列**。M2 的 h1 是 96sp，
   M3 的 displayLarge 是 57sp，语义完全对不上，标题会突然缩水或暴涨。
   按上文的 h4→headlineSmall 这条线映射。
3. **NavigationBar 压回 56dp**。会让 indicator 药丸和图标重叠，
   并且和官方的 80dp 并排时出现明显高度差。
