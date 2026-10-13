# 筛选状态与 URL 的双向同步

把筛选状态放进 URL 是后台的标准做法，但「双向同步」有细节坑：初始化时误触发请求、
数组参数格式、多标签页隔离、与浏览器历史的配合。本文给出可直接用的模式。

## 一、为什么是 URL 而不是全局状态

| 存放位置 | 刷新保留 | 可分享 | 后退可用 | 多标签独立 |
| --- | --- | --- | --- | --- |
| 组件 state | 否 | 否 | 否 | 是 |
| 全局 store（内存） | 否 | 否 | 否 | 否 |
| sessionStorage | 是 | 否 | 否 | 是 |
| **URL query** | **是** | **是** | **是** | **是** |

URL 是唯一同时满足四个条件的。代价是 URL 变长、需要处理手动改 URL 的容错。

**例外**：如果筛选条件里有敏感信息（用户手机号、身份证号），不要写 URL（会被日志、Referer 记录）。
这种情况用 sessionStorage，并接受不可分享的代价。

## 二、序列化格式

```ts
type Filters = {
  keyword?: string;
  status?: string;         // 枚举，单值
  owner?: string;
  from?: string;           // ISO 短日期 yyyy-MM-dd
  to?: string;
  tags?: string[];         // 多值
  amountMin?: number;
  amountMax?: number;
};
```

| 类型 | URL 写法 | 说明 |
| --- | --- | --- |
| 字符串 | `?keyword=张伟` | 需 `encodeURIComponent` |
| 数字 | `?amountMin=100` | 转字符串，注意精度 |
| 布尔 | `?overdue=1` | 用 `1`/`0`，比 `true`/`false` 短 |
| 单值枚举 | `?status=paid` | 用枚举 code，不要用中文 label |
| 多值 | `?tag=a&tag=b` 或 `?tag=a,b` | 后者短，但值里不能有逗号 |
| 日期 | `?from=2026-10-01` | ISO 短格式，不要时间戳 |
| 时间戳 | `?ts=2026-10-12T19:04:33Z` | 仅在需要时分秒时用 |

**只写非默认值**。默认状态下 URL 应该干净到可以当首页链接。

## 三、单向数据流（避免死循环）

最常见的 bug 是「URL 变化 → 更新 state → state 变化 → 更新 URL → ...」死循环。
正确做法是**让 URL 成为唯一事实来源**：

```tsx
function useFiltersFromUrl(defaults: Filters) {
  const [searchParams, setSearchParams] = useSearchParams();

  // URL → 组件（唯一方向）
  const filters = useMemo(() => parseFilters(searchParams, defaults), [searchParams]);

  // 组件 → URL（唯一方向）
  const setFilters = useCallback((patch: Partial<Filters>, opts?: { push?: boolean }) => {
    const next = { ...filters, ...patch };
    const qs = serializeFilters(next, defaults);
    setSearchParams(qs, { replace: !opts?.push });
  }, [filters, defaults, setSearchParams]);

  return [filters, setFilters] as const;
}
```

- 组件**不再**维护一份 `filters` 的本地 state，直接读 URL。
- 输入框这种需要即时响应的控件，本地维护一个「草稿值」，防抖后再写入 URL。
- 写 URL 时 `replace: true`（默认），只有页码变化用 `push: true`。

## 四、初始化时不要误触发请求

进入页面时 URL 已经有筛选参数，组件初始化会「解析出筛选 → 触发请求」，
这一步是**需要**的。真正要避免的是：

1. **默认值写进 URL 后又触发一次请求**。解析时把默认值填上，但序列化时排除默认值，
   保证「URL 没变 → 不重新请求」。
2. **依赖数组里放了每次渲染都新建的对象**。`filters` 用 `useMemo` 稳定引用，
   请求的 `useEffect` 依赖 `JSON.stringify(filters)` 或按字段拆开。
3. **StrictMode 下双调用**。React 18 开发模式会双调用 effect，请求要能幂等或有取消机制。

```ts
useEffect(() => {
  const ctrl = new AbortController();
  fetchList(filters, { signal: ctrl.signal }).catch(err => {
    if (err.name === 'AbortError') return;   // 正常取消，不报错
    setError(err);
  });
  return () => ctrl.abort();
}, [filtersKey]);   // filtersKey = JSON.stringify(filters)
```

## 五、数组参数

两种写法各有取舍：

- `?tag=a&tag=b`：标准，任何后端框架都能解析成数组。URL 略长。
- `?tag=a,b`：短，可读。**但值本身含逗号时会被拆错**。

**推荐 `?tag=a&tag=b`**，除非值可能含逗号且你愿意做转义。

空数组时**移除该参数**，不要写 `?tag=`。

## 六、多标签页隔离

URL 方案天然支持多标签页独立 —— 两个标签开同一个列表，各自有不同的筛选，
互不干扰。这是 URL 相对全局 store 的核心优势。

但要注意：**不要**用 `localStorage` 缓存筛选状态并在初始化时读取。
那会破坏隔离：在标签 A 筛完，打开新标签 B 会带着 A 的筛选，用户莫名其妙。
如果确实需要「记住上次筛选」，用 `sessionStorage`（同标签内保留，跨标签隔离）。

## 七、手动改 URL 的容错

用户会手动改 URL，也会从别处粘贴带参数的链接。解析时必须容错：

```ts
function parseFilters(sp: URLSearchParams, defaults: Filters): Filters {
  const out = { ...defaults };

  // 枚举：非法值忽略
  const status = sp.get('status');
  if (status && STATUS_CODES.includes(status)) out.status = status;

  // 数字：NaN 忽略
  const min = Number(sp.get('amountMin'));
  if (Number.isFinite(min) && min >= 0) out.amountMin = min;

  // 日期：格式不对忽略
  const from = sp.get('from');
  if (from && /^\d{4}-\d{2}-\d{2}$/.test(from)) out.from = from;

  // 页码：非法值回 1
  const page = Number(sp.get('page'));
  out.page = Number.isInteger(page) && page > 0 ? page : 1;

  return out;
}
```

原则：**非法值静默忽略该条件，保留其余**，绝不整页报错。
可以给一个不打扰的提示「部分筛选条件已失效」。

## 八、与浏览器历史的配合

| 操作 | 历史行为 | 理由 |
| --- | --- | --- |
| 改筛选条件 | `replace` | 否则改 5 个条件要按 5 次后退 |
| 改页码 | `push` | 用户会想「退回上一页」 |
| 改每页条数 | `replace` | 属于视图偏好，不是位置 |
| 改排序 | `replace` | 同上 |
| 清空全部筛选 | `push` | 这是一次明显的状态跳转，值得可后退 |

判断口诀：**这个变化算「换了个地方」还是「原地调整」**？
换地方用 `push`，原地调整用 `replace`。

## 九、可分享性的边界

分享链接给同事时，同事的权限可能不同：

- 链接里的 `owner=me` 之类相对值，换个人打开语义变了。用绝对值（用户 id）。
- 同事无权访问某个筛选维度（如财务字段）时，忽略该条件并提示，而不是报错。
- 链接里不要带一次性 token、临时签名等会过期的参数。
