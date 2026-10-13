---
name: "mobile-app-navigation"
description: "设计移动应用的导航结构时使用：底部 Tab 取舍、抽屉与栈式导航、模态与全屏页、深层链接、返回手势与 Tab 内状态保持。"
version: "1.0.0"
license: "MIT"
author: "Skill Hub"
category: ui
tags: ["APP 移动端", "底部 Tab", "栈式导航", "深层链接", "返回手势", "状态保持", "模态与全屏"]
---

# 移动应用导航模式

移动端导航的核心矛盾是：**屏幕只有一屏大，但用户要能到达任意深度**。
每一次「多一层」都要付出返回成本，每一次「藏起来」都要付出发现成本。
下面的规则都是在两个成本之间取平衡。

## 何时使用

- 从零规划一个 App 的信息架构和导航骨架
- 用户反馈「找不到 XX 功能」「返回之后回到最上面了」「不知道自己在哪」
- 要在 Tab 和抽屉之间做取舍，或纠结某个页面该不该做成模态
- 接深层链接（分享链接、推送跳转、扫码）需要设计路由结构

## 核心规则

1. **底部 Tab 数量 3–5 个，5 是硬上限。**
   原因是每个 Tab 的宽度：375pt 宽的屏去掉左右各 16pt 边距，5 个 Tab 每个只有 68pt，
   刚好放得下 24pt 图标 + 11pt 文字。到 6 个就只剩 57pt，文字必须截断或缩写，
   识别速度断崖式下降。**3 个以下不要用 Tab**，直接用分段控件或页面内导航更省空间。

2. **Tab 必须有文字标签，不能只有图标。**
   纯图标的 Tab 在用户第一次见时的猜中率大约一半（尤其「钱包 / 卡包 / 收藏」这类抽象图标）。
   空间不够就缩字号到 10–11pt，不要去掉文字。

3. **Tab 尺寸与安全区：**
   iOS Tab bar 内容区高 49pt + 底部安全区 34pt = 83pt；
   Android M3 NavigationBar 高 80dp（M2 是 56dp）；
   图标 24–28pt，标签 10–12pt；
   每个 Tab 的点击热区最小 44×44pt（iOS）/ 48×48dp（Android），
   所以 Tab 宽度**不能小于 64pt**，否则热区会互相挤。

4. **一个 Tab 一个独立导航栈。** 在「首页 Tab」里点进详情，切到「我的 Tab」再切回来，
   必须还停在详情页，滚动位置也要保留。
   全局单一栈的实现（所有 Tab 共用一个 stack）会导致切 Tab 时栈被重置，
   这是最常见的「返回之后回到最上面」的根因。

5. **栈深度控制在 4 层以内**（Tab 根算第 1 层）。
   超过 4 层说明层级该被扁平化，或者某段该改成模态。
   实际数据显示 5 层以上的栈，用户主动返回的比例显著下降 —— 他们会直接杀掉 App。

6. **模态（modal）用于「有明确终点的独立任务」**，全屏页（push）用于「内容浏览」。
   判断标准：这个页面做完之后是不是要「回到出发的地方」？是 → 模态；
   这个页面本身是内容的一部分、用户可能继续往下走 → push。
   登录、新建、编辑、支付、图片查看 = 模态；商品详情、文章、设置 = push。

7. **返回手势必须能预测。** Android 14 起有预测性返回（predictive back），
   需要在 manifest 里开 `android:enableOnBackInvokedCallback="true"`；
   iOS 的左侧边缘滑动返回默认存在，**左边缘 20pt 内不能放横向滚动的轮播**，
   否则两个手势会打架，表现为「想滑动轮播结果退出了页面」。

8. **抽屉（Drawer）只在 Tab 装不下、且存在 ≥ 7 个一级入口时使用。**
   抽屉的可发现性差（用户平均只有约 30% 会主动点开汉堡菜单），
   而且和 iOS 的边缘返回手势冲突（都是从左边缘滑出）。
   用抽屉就必然要接受「很多用户永远看不到里面的功能」。

## 怎么做

### 1. 先定信息架构，再选导航容器

按一级入口数量选：

| 一级入口数 | 推荐容器 | 理由 |
| --- | --- | --- |
| 2–3 | 分段控件 / 顶部 Tab / 页面内切换 | Tab bar 浪费 83pt 高度 |
| 3–5 | 底部 Tab bar | 最佳区间，可发现性最高 |
| 6–7 | 底部 Tab（挑最常用的 5 个）+ 其余进「更多」 | 折中 |
| ≥ 8 | 抽屉 或 首页宫格 | Tab 无法承载 |

选择时优先砍功能，而不是加容器。把 8 个入口硬塞进 5 个 Tab 的「更多」里，
等于这 3 个功能被隐藏了两次。

### 2. 路由结构（以 React Navigation / Expo Router 为例）

```ts
// 每个 Tab 是独立的 Stack，这是状态保持的关键
const Tab = createBottomTabNavigator()
const HomeStack = createNativeStackNavigator()
const MeStack = createNativeStackNavigator()

function HomeNavigator() {
  return (
    <HomeStack.Navigator screenOptions={{ headerShown: false }}>
      <HomeStack.Screen name="HomeFeed" component={FeedScreen} />
      <HomeStack.Screen name="Detail" component={DetailScreen} />
    </HomeStack.Navigator>
  )
}

export default function RootTabs() {
  return (
    <Tab.Navigator
      screenOptions={{
        tabBarLabelStyle: { fontSize: 11 },
        tabBarStyle: { height: 49 + insets.bottom },
        tabBarHideOnKeyboard: true,   // 键盘弹出时收起 Tab bar，避免和输入法叠在一起
      }}
    >
      <Tab.Screen name="HomeTab" component={HomeNavigator} options={{ title: '首页' }} />
      <Tab.Screen name="MeTab"   component={MeNavigator}   options={{ title: '我的' }} />
    </Tab.Navigator>
  )
}
```

Android Compose 用 `NavigationBar` + 每个 Tab 一个 `NavHost`，
Flutter 用 `go_router` 的 `StatefulShellRoute`，思路完全一致：**栈是 Tab 的子节点，不是兄弟**。

### 3. Tab bar 什么时候该隐藏

- **push 到二级页时保留 Tab bar**（iOS 惯例）。隐藏会让用户失去「我在哪个 Tab 里」的锚点，
  并且返回后 Tab bar 重新出现的动画会闪。
- **模态全屏页隐藏**，因为模态是脱离当前上下文的独立任务。
- **键盘弹出时隐藏**（`tabBarHideOnKeyboard`），否则输入框和 Tab bar 会叠。
- **沉浸式内容页隐藏**（视频播放、图片全屏、地图），并配合状态栏隐藏。

例外：短视频类 App 的 Tab bar 常驻，因为「刷」本身不需要返回。

### 4. 模态的尺寸与关闭方式

- **Bottom sheet 两档：半屏 50%、全屏 90%。** 半屏档用于「看一眼就走」，
  比如评论列表、选择器。iOS 用 `presentationDetents={[0.5, 0.9]}`。
- **模态必须提供三种关闭方式中的至少两种**：显式关闭按钮（左上角 × 或右上角「取消」）、
  下滑手势、物理返回键（Android）。
  只有下滑手势是不够的 —— 手上有水、戴手套、或屏幕上有横向滚动区域时下滑会失败。
- **模态内如果有未保存内容，关闭时二次确认**，文案要说明后果（「放弃编辑？」而不是「确定吗？」）。
- **模态的高度不要超过 90%**，顶部留一点露出下面的页面，用户才知道「这是个可以关掉的东西」。

### 5. 返回键与手势

Android：
```xml
<application android:enableOnBackInvokedCallback="true">
```
开启后，返回手势会在手指滑动过程中实时把当前页面缩小并露出上一页（预测性返回）。
如果某个页面不该被返回（比如支付进行中），用 `OnBackPressedCallback` 拦截并给提示，
**不要**用「按两次退出」这种隐式行为。

iOS：
- 左侧边缘右滑 = 返回上一页，热区约屏幕左侧 20pt 内
- 右滑手势在栈底无效（栈里只有一层时不应该有手势）
- 自定义返回按钮时，必须保留 `interactivePopGestureRecognizer`，
  否则手势会失效 —— 这是 React Navigation / SwiftUI 里最常被搞坏的一处

### 6. Tab 内嵌栈的状态保持

要做到「切回来还在原地」，需要三件事同时成立：

1. **导航栈本身不销毁**：Tab 切换时用 `unmountOnBlur: false`（React Navigation）
   或 `AutomaticKeepAliveClientMixin`（Flutter），不要让 Tab 卸载重建。
2. **滚动位置要单独存**：栈保住了不代表滚动位置保住了。
   列表页在 `blur` 时把 `scrollY` 存进 store，`focus` 时恢复。
   iOS 的 `UITableView` 会自动保，`FlatList` / `RecyclerView` 不一定。
3. **表单草稿要存**：用户在「新建」页填了一半切走，回来必须还在。
   存内存就够（进程被杀就丢，可接受），但至少要撑住一次 Tab 切换。

代价：所有 Tab 都常驻内存，低端机上内存占用会明显上升。
Tab 数 ≥ 4 且每个 Tab 都有重列表时，考虑只保栈、不保列表数据（回来时重新请求 + 恢复滚动位置）。

### 7. 深层链接

路径设计规则：
- 路径即层级，`/orders/123` 而不是 `/order_detail?id=123`
- **每一级都要能独立打开**：`/orders/123` 能开，`/orders` 也必须能开
- 未登录时不能直接跳目标页，要先存下目标路径，登录成功后 replace 过去（**不要 push**，
  否则返回时会回到登录页）
- App 没装时回落网页版，网页版顶部给「打开 App」banner

细节（Universal Link / App Link 配置、延迟深链、扫码场景）见 `references/deep-linking.md`。

## 检查清单

- [ ] Tab 数量 3–5 个，每个宽度 ≥ 64pt
- [ ] 每个 Tab 都有文字标签，字号 ≥ 10pt
- [ ] 底部安全区处理正确（iPhone 全面屏不遮挡，Android 手势条不遮挡）
- [ ] 切换 Tab 再切回，二级页面和滚动位置都还在
- [ ] 任意页面的栈深度 ≤ 4 层
- [ ] 所有模态都能用「按钮」关闭，不只靠手势
- [ ] Android 开启预测性返回，且支付/上传等关键流程有返回拦截
- [ ] iOS 自定义返回按钮后，边缘滑动返回仍然可用
- [ ] 左边缘 20pt 内没有横向滚动手势冲突
- [ ] 键盘弹出时 Tab bar 收起，输入框不被遮挡
- [ ] 冷启动走深层链接能直达目标页，未登录时登录后 replace 而非 push
- [ ] 系统「大字体」设置下 Tab 标签不换行、不截断

## 常见错误

| 错误做法 | 为什么错 | 正确做法 |
| --- | --- | --- |
| 全局单一导航栈 | 切 Tab 时栈被重置，用户回到根页并丢失滚动位置 | 每个 Tab 一个独立 Stack |
| 6 个 Tab | 每格宽度 < 60pt，文字截断、误触率上升 | 砍到 5 个，其余进「更多」 |
| 抽屉里放核心功能 | 汉堡菜单打开率低，功能等于被隐藏 | 核心功能进 Tab，抽屉只放设置类 |
| 只有下滑手势能关模态 | 手湿、戴手套、页面内有横滑时关不掉 | 补一个显式关闭按钮 |
| 登录后 push 目标页 | 返回键回到登录页，用户会再次触发登录 | 用 replace |
| 栈深度 7 层 | 用户迷失，返回成本高于重新进入 | 扁平化，或中间层改模态 |
| 模态高度 100% | 和全屏页没区别，用户不知道能不能关 | 上限 90%，顶部露出下层 |
| Tab 切换用 unmount 省内存 | 回来时列表重建，滚动位置丢失 | 保栈，必要时只清数据不清栈 |
| 左边缘放轮播图 | 横滑被系统返回手势抢走，用户以为卡了 | 轮播左侧留 20pt 手势死区或右移 |
| Android 用「按两次退出」 | 隐式行为，用户不知道要按第二次 | 明确弹「再按一次退出」或直接退出 |

## 参考

- 要接 Universal Link / App Link、处理延迟深链、扫码和推送跳转时，读 `references/deep-linking.md`
