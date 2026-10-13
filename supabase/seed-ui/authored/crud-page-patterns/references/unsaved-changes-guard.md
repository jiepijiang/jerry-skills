# 未保存改动的拦截实现

「填了半天被误关」是后台最常见的差评来源。拦截本身不难，难在**不漏拦、也不误拦**。
本文给出可直接落地的分层方案。

## 一、先定义「脏」（dirty）

脏 = 当前值 ≠ 初始值。三个必须处理的坑：

1. **对象比较不能只用引用**。表单库通常每次渲染都产生新对象，引用永远不等。
   用深比较（`JSON.stringify` 对纯数据够用；含 Date/File/undefined 时需自定义序列化）。
2. **初始值要归一化**。接口返回 `amount: 100`，输入框里是 `"100"`，字符串化后就不相等了。
   初始化时把值统一成表单里的类型（该 number 就 number，该 string 就 string）。
3. **忽略「服务端补全字段」**。新建时后端可能给 id、createdAt 填了默认值，这些不该算用户的改动。
   只比较**用户可编辑的字段**（schema 里 `inForm: true` 的那批）。

```ts
function pickEditable(values: Record<string, unknown>, schema: Schema) {
  return Object.fromEntries(
    Object.entries(values).filter(([k]) => schema[k]?.inForm)
  );
}
const isDirty = deepEqual(pickEditable(values, schema), pickEditable(initial, schema));
```

## 二、三层拦截，缺一不可

| 层 | 触发场景 | 手段 |
| --- | --- | --- |
| 浏览器 | 刷新、关标签、关浏览器 | `beforeunload` |
| 路由 | 点侧栏、点面包屑、前进后退 | 路由 blocker / `history` 拦截 |
| 组件 | 点抽屉关闭、点「取消」、点遮罩 | 组件内部判断 |

### 层 1：beforeunload

```ts
useEffect(() => {
  if (!isDirty) return;
  const handler = (e: BeforeUnloadEvent) => { e.preventDefault(); e.returnValue = ''; };
  window.addEventListener('beforeunload', handler);
  return () => window.removeEventListener('beforeunload', handler);
}, [isDirty]);
```

注意：浏览器只允许弹**系统默认文案**，你无法自定义。所以不要在代码里费劲写中文提示，没用。
部分浏览器（含 Chrome 119+ 的某些场景）要求用户有过交互才显示，不要指望 100% 触发。

### 层 2：路由拦截

React Router v6.4+ 有 `useBlocker`；Vue Router 用 `onBeforeRouteLeave`；Next.js App Router 需要在链接上包一层自定义组件。

```ts
useBlocker(({ currentLocation, nextLocation }) =>
  isDirty && currentLocation.pathname !== nextLocation.pathname
);
```

- 只比较 `pathname`，忽略 query 变化 —— 改筛选条件不该触发拦截。
- 拦截到之后，用一个统一的确认弹窗组件，按钮写「继续编辑 / 放弃修改」。
- 如果是「保存并跳转」的流程（保存成功 → 主动跳列表），要在跳转前把 `isDirty` 置 false，
  否则会被自己拦下来。

### 层 3：组件内关闭

抽屉/弹窗的关闭路径有三条：右上角 ×、取消按钮、点击遮罩（若允许）。
三条必须走**同一个** `handleClose()`：

```ts
const handleClose = async () => {
  if (isDirty && !(await confirmDiscard())) return; // 用户选「继续编辑」
  onClose();
};
```

**常见漏网之鱼**：
- 点击遮罩关闭时直接 `onClose()`，绕过了检查。
- `Esc` 键监听直接关闭。
- 多标签页关闭按钮只关 Tab 不检查表单。

## 三、多标签页与抽屉嵌套

后台常有「抽屉里再开一个抽屉」的编辑（列表 → 订单抽屉 → 客户选择抽屉）。
脏值需要**向上冒泡**：内层抽屉有未保存内容时，外层抽屉的关闭也必须被拦。

```ts
// 用 context 汇总所有子表单的脏状态
const DirtyCtx = createContext<{ register: (id: string, dirty: boolean) => void }>(...);
const isAnyDirty = Object.values(dirtyMap).some(Boolean);
```

关外层时检查 `isAnyDirty`，弹「内层表单有未保存内容」的提示，并**把内层抽屉高亮/滚动到可视**。

## 四、不要误拦

过度拦截比不拦更伤用户。以下情况**不**应该拦：

| 场景 | 是否拦截 | 原因 |
| --- | --- | --- |
| 打开表单，一个字段没动就关 | 否 | 没有损失，拦截是骚扰 |
| 只切换了 Tab、没改字段 | 否 | 非字段状态不算脏 |
| 保存成功后自动关闭 | 否 | 已保存，置 `isDirty = false` |
| 校验失败后用户点取消 | 是 | 改动还在，仍需确认 |
| 用户点了「重置」按钮后再关 | 否 | 重置后应同步更新 `initialValues` |

**关键**：点「重置」时要把 `initialValues` 更新为重置后的值，否则脏比较仍然为真，关了还拦。

## 五、确认弹窗的文案

| 场景 | 标题 | 正文 | 按钮 |
| --- | --- | --- | --- |
| 有未保存改动 | 放弃未保存的修改？ | 你对「订单 1024」的修改尚未保存。 | 继续编辑 / 放弃修改 |
| 关闭内层表单 | 还有未保存的表单 | 「新增客户」中有未保存内容。 | 返回填写 / 全部放弃 |
| 删除实体 | 删除订单 1024？ | 删除后不可恢复，关联的 3 条记录也会一并删除。 | 取消 / 删除 |

按钮永远是「安全的动作在左，破坏性的动作在右」，且破坏性按钮用红色或次要样式，
**不要**把「放弃修改」做成默认高亮的 primary —— 用户按回车会误丢数据。
