/**
 * 界面一致性守卫（源码级）
 * ---------------------------------------------------------------------------
 * 起因：三处「上传技能」按钮看起来不一样。查下来根因不在按钮本身，而在
 * `src/styles/hub.css` 里那条 `.empty svg { … }`：
 *
 *   - 它是**后代选择器**，会连 EmptyState 插槽里的按钮图标一起命中；
 *   - 它和 `.btn svg` 的**特异度完全相同**（都是 0,1,1），谁赢只看**源码顺序**，
 *     而 `.empty svg` 写在后面 —— 于是插槽里的图标被撑成 40px、染成灰色、加 0.6 透明度。
 *
 * 实测（改之前）：
 *   where   h   w    iconW  iconFill            iconOpacity
 *   顶栏     32  99   16     rgb(255,255,255)   1
 *   Hero    38  111  16     rgb(255,255,255)   1
 *   空状态   32  123  40 ←   rgb(138,138,150)   0.6 ←
 *
 * 修法是：装饰图标改用组件自己的 scoped 样式 + 专属 class（`.empty-icon`），
 * 这样插槽内容**结构上**就不可能被它影响，而不是靠调顺序去赌。
 *
 * ⚠️ 按项目纪律：**没红过的绿灯没有意义**。
 *    把 `.empty svg` 那条规则加回 hub.css，本文件必须红 —— **已实测：第 1 条变红**
 *    （`not ok 1`，其余 5 条仍绿：它们查的是别的文件，不受影响）。
 *
 * 为什么在这里做源码断言而不是渲染断言：
 *   这个坑的本质是「CSS 选择器的匹配范围」，不是「渲染出来的 DOM 长什么样」——
 *   从渲染结果看一切正常，是**计算后的样式**错了。真要渲染断言得跑真实浏览器
 *   量 computedStyle，那是另一个脚本（.workbuddy-ai 下的 verify-button-consistency.mjs）
 *   干的活。单测这一层负责「别把那条规则写回来」。
 */
import { test } from 'node:test'
import assert from 'node:assert/strict'
import { readFileSync } from 'node:fs'
import { fileURLToPath } from 'node:url'

const ROOT = fileURLToPath(new URL('../..', import.meta.url))
const read = (p) => readFileSync(`${ROOT}${p}`, 'utf8')

/**
 * 剥掉注释再断言。
 *
 * ⚠️ 这不是洁癖，是被咬过：hub.css 里那段解释「为什么不能写 .empty svg」的注释
 *    本身就含有 `.empty svg` 这串字。不剥的话，下面第一条断言会**永远为真**
 *    —— 哪怕真把规则加回去了。
 *    （同类坑在本项目踩过两次：模板注释会被 SSR 渲染进 HTML；
 *      SkillDetailView 的注释里写着「复制次数」。）
 *
 * 这一步本身也造过红（两条方向都验了）：
 *   ① 注释里写一条**完整规则**（`.empty` + `svg` + 花括号 + 声明）→ 6/6 绿，说明正确剥掉
 *   ② 把本函数改成 `return src`（停用剥注释）→ 上面那条**立刻变红**（`not ok 1`）
 * 少了 ②，就只是「碰巧没踩到」，不是「守卫真的在防」。
 */
function stripComments(src) {
  return src.replace(/\/\*[\s\S]*?\*\//g, '').replace(/^\s*\/\/.*$/gm, '')
}

test('hub.css 里不能再有 `.empty svg` 这类会漏进插槽的后代选择器', () => {
  const css = stripComments(read('src/styles/hub.css'))

  // 抓 `.empty` 后面跟任意后代（空格 / >）再跟 svg 的写法
  const hits = [...css.matchAll(/\.empty\s+svg\b[^{]*\{[^}]*\}/g)].map((m) => m[0].trim())
  assert.deepEqual(
    hits,
    [],
    `.empty svg 是后代选择器，会连插槽里按钮的图标一起命中。\n` +
      `装饰图标的样式请写在 EmptyState.vue 的 scoped 样式里（.empty-icon）。\n` +
      `抓到：${JSON.stringify(hits)}`,
  )
})

test('EmptyState 的装饰图标走专属 class，不走裸标签选择器', () => {
  const vue = stripComments(read('src/components/EmptyState.vue'))

  assert.ok(
    /class="empty-icon"/.test(vue),
    'EmptyState.vue 的装饰图标应该带 class="empty-icon"（专属 class 才不会漏进插槽）',
  )
  assert.ok(
    /\.empty-icon\s*\{/.test(vue),
    'EmptyState.vue 的 scoped 样式里应该有 .empty-icon 规则',
  )
  // 反向：模板里不该再出现裸的 <svg>（那意味着又回到「靠标签选」的老路）
  assert.ok(
    !/<svg\b/.test(vue),
    'EmptyState.vue 不该直接写 <svg>，应该用 AppIcon 组件并挂 .empty-icon',
  )
})

test('EmptyState 用了 scoped 样式（没有 scoped 的话专属 class 也会外泄）', () => {
  const vue = stripComments(read('src/components/EmptyState.vue'))
  assert.ok(
    /<style\s+scoped>/.test(vue),
    'EmptyState.vue 的 <style> 必须是 scoped —— 否则 .empty-icon 一样会影响别处',
  )
})

test('三处「上传技能」按钮都用默认尺寸，没有谁偷偷加 .sm', () => {
  // 同一个按钮在三个地方出现两个尺寸，看起来就是「没做完」。
  // 顶栏那个尤其要盯：它旁边是 38px 的搜索框，按钮要是 32px，整排就参差不齐。
  const files = {
    'TopBar.vue': read('src/components/TopBar.vue'),
    'HomeView.vue': read('src/views/HomeView.vue'),
  }
  for (const [name, src] of Object.entries(files)) {
    const code = stripComments(src)
    const hits = [...code.matchAll(/class="btn[^"]*\bsm\b[^"]*"[^>]*>\s*(?:<[^>]+>\s*)*上传技能/g)]
    assert.deepEqual(
      hits.map((m) => m[0].slice(0, 60)),
      [],
      `${name} 里的「上传技能」不该用 .sm —— 三处尺寸要一致`,
    )
  }
})

test('顶栏整排控件同高：图标按钮不写死小尺寸', () => {
  const css = stripComments(read('src/components/TopBar.vue'))
  // .nav-icon-btn 曾经是 padding: 0 10px 的 .btn.sm（32px），比搜索框矮 6px
  assert.ok(
    /\.nav-icon-btn\s*\{[^}]*width:\s*38px/.test(css),
    '.nav-icon-btn 应该是 38px 的正方形，和搜索框对齐',
  )
})

test('空状态插槽里的按钮不带 .sm（详情页两处）', () => {
  const src = stripComments(read('src/views/SkillDetailView.vue'))
  // EmptyState 插槽里的按钮：<button class="btn" ...>重试</button> / <router-link to="/" class="btn">
  const slotButtons = [...src.matchAll(/<EmptyState[\s\S]*?<\/EmptyState>/g)]
    .map((m) => m[0])
    .join('\n')
  assert.ok(slotButtons.length > 0, '应该能抓到 EmptyState 区块')
  assert.ok(
    !/class="btn[^"]*\bsm\b/.test(slotButtons),
    'EmptyState 插槽里的按钮不该用 .sm —— 会和 Hero 的主操作尺寸不一致',
  )
})
