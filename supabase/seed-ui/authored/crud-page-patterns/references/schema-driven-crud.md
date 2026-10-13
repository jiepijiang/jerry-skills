# Schema 驱动的 CRUD：字段类型、校验映射与使用边界

「同一份数据在三个页面重复实现」是 CRUD 最大的失控点。Schema 驱动是主流解法，
但它有适用边界，用错地方反而增加复杂度。本文说清怎么用、什么时候别用。

## 一、什么时候该上 schema

| 条件 | 建议 |
| --- | --- |
| 字段 ≤ 4 且只有一个页面 | 不要用，直接写 |
| 字段 ≤ 4 但有列表 + 表单两个页面 | 可以用轻量常量表，不必上框架 |
| 字段 5–15，有列表/详情/表单 | **该用**，收益最大 |
| 字段 > 15 或含动态字段 | 该用，且需要分组与条件显示能力 |
| 字段来自后端元数据（用户自定义字段） | 必须用，运行时才能确定 |

判断口诀：**同一份字段描述出现 ≥ 3 次，就该抽成 schema**。

## 二、字段类型清单

只保留够用的类型，不要发明「手机号类型」这种 —— 那是 `text` + 正则。

| type | 表单控件 | 列表显示 | 详情显示 |
| --- | --- | --- | --- |
| `text` | `<input type="text">` | 文本，超长省略 | 文本 |
| `longtext` | `<textarea rows="3">` | 不在列表（`inList: false`） | 多行文本，保留换行 |
| `number` | `<input type="number">` | 右对齐 | 右对齐 |
| `money` | 数字输入 + 前缀 `¥` | 右对齐 + 千分位 | 右对齐 + 千分位 + 2 位小数 |
| `percent` | 数字输入 + 后缀 `%` | 右对齐 | 右对齐 |
| `enum` | `<select>` 或单选 | 彩色标签 | 彩色标签 |
| `multienum` | 多选 | 多个标签，超出显示 `+N` | 全部标签 |
| `bool` | `<Switch>` | 「是 / 否」或图标 | 「是 / 否」 |
| `date` | 日期选择器 | `yyyy-MM-dd` | `yyyy-MM-dd` |
| `datetime` | 日期时间选择器 | `yyyy-MM-dd HH:mm` | `yyyy-MM-dd HH:mm:ss` |
| `image` | 上传（缩略图预览） | 40×40 缩略图 | 大图 + 点击放大 |
| `file` | 上传 | 文件名 + 下载图标 | 文件名 + 大小 + 下载 |
| `ref` | 选择器（异步搜索） | 关联实体的显示名 | 关联实体卡片，可点跳转 |

## 三、校验规则映射

```ts
const RULES = {
  required: v => (v === '' || v == null) ? '不能为空' : null,
  min:      (v, n) => (typeof v === 'number' && v < n) ? `不能小于 ${n}` : null,
  max:      (v, n) => (typeof v === 'string' && v.length > n) ? `最多 ${n} 个字符` : null,
  precision:(v, n) => (typeof v === 'number' && String(v).split('.')[1]?.length > n)
                       ? `最多 ${n} 位小数` : null,
  pattern:  (v, re) => (v && !re.test(v)) ? '格式不正确' : null,
};
```

错误文案三原则：
1. **说清怎么改**：「不能小于 0.01」优于「输入有误」。
2. **带上限值**：「最多 40 个字符」优于「太长」。
3. **不用术语**：「格式不正确，请输入 11 位手机号」优于「正则校验失败」。

## 四、条件显示与联动

很多字段只在某个条件下才需要填。用 `dependsOn` 描述，避免三个页面各写一遍 `v-if`。

```ts
{
  key: 'refundReason',
  label: '退款原因',
  type: 'longtext',
  inForm: true, inList: false, inDetail: true,
  visibleWhen: { field: 'status', in: ['refunded', 'refunding'] },
  requiredWhen: { field: 'status', in: ['refunded'] },
}
```

- `visibleWhen` 为假时字段**不渲染且不参与校验**。
- `requiredWhen` 让必填变成条件必填 —— 这是产品需求里最常被漏掉的一类。
- 联动字段的隐藏要**同时清空值**，否则用户填了又隐藏，提交时带上了看不见的数据。

## 五、格式化只在展示层做，不在数据层

- 数据层永远存**原始值**（金额存分或存 number，时间存 ISO 字符串或时间戳）。
- 展示层才做千分位、单位、时区转换。
- **绝不要**把格式化后的字符串存回表单值，否则下一次编辑会 `"¥1,234.00"` 变成非法输入。

```ts
// 反例：输入框里放的是格式化值
value="¥1,234.00"   // 用户一改就崩

// 正例：输入框放原始值，单位用前缀装饰
prefix="¥"  value={1234.00}  // 显示时由 input 组件加千分位
```

## 六、不该用 schema 的边界

1. **纯展示页**（报表、看板）：字段是动态计算的，没有「同一份定义三处复用」的需求。
2. **强交互表单**（多步骤向导、复杂联动矩阵）：schema 描述不了这种状态机，硬套会变成一堆 `visibleWhen` 地狱。
3. **只有 3 个字段的小实体**：写三遍比维护一套 schema 类型系统更快。
4. **字段描述本身来自后端且格式不稳定**：需要先做一层适配与版本兼容，别把不稳定的东西当事实来源。

## 七、落地的目录建议

```
src/
  schema/
    order.ts          # 字段定义
    order.rules.ts    # 校验规则（若规则复杂，从 schema 拆出）
  pages/order/
    List.tsx          # 读 schema.inList
    Detail.tsx        # 读 schema.inDetail
    FormDrawer.tsx    # 读 schema.inForm
  components/
    FieldRenderer.tsx # 按 type 渲染表单控件
    CellRenderer.tsx  # 按 type 渲染列表单元格
```

三个页面里不应该出现任何硬编码的 `label="客户"` —— 所有 label 都来自 schema。
如果哪天发现页面里写死了字段名，那就是重复实现又回来了。
