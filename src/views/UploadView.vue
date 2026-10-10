<script setup>
import { computed, ref } from 'vue'
import { useRouter } from 'vue-router'
import AppIcon from '@/components/AppIcon.vue'
import FileTree from '@/components/FileTree.vue'
import LocalModeBanner from '@/components/LocalModeBanner.vue'
import { categories, limits, CATEGORY_KEYS, categoryLabel } from '@/data/site'
import { CATEGORY_RULE_HINT, resolveCategory } from '@/lib/category'
import { buildTree, formatBytes, parseSkill } from '@/lib/parseSkill'
import { errorText, publishSkill } from '@/lib/skills-api'
import { toast } from '@/composables/useToast'

const router = useRouter()

const mode = ref('file') // file | text
const dragOver = ref(false)
const parsing = ref(false)
const publishing = ref(false)

const parsed = ref(null) // parseSkill 的产物
const errors = ref([])
const warnings = ref([])
const fileName = ref('')

/* 表单（解析后自动填，允许改） */
const form = ref({
  name: '',
  description: '',
  category: 'other',
  tags: '',
  author: '',
  version: '',
  license: '',
})

const text = ref('')
const fileInput = ref(null)

/**
 * 分类是怎么定下来的 —— 解析后由 resolveCategory() 写入，模板里显示给用户看。
 * 分类识别一直是这个站最让人困惑的地方（「为什么我的技能跑到其他里去了」），
 * 所以不只要猜，还要**把猜的依据摆出来**，并且允许改。
 */
const catResolved = ref(null)
/** 用户是否手动改过分类。改过之后就不再显示推断理由了 */
const catTouched = ref(false)

const tree = computed(() => (parsed.value ? buildTree(parsed.value.files) : null))
const categoryOptions = computed(() => categories.filter((c) => CATEGORY_KEYS.includes(c.key)))
const canSubmit = computed(() => Boolean(parsed.value) && errors.value.length === 0 && !publishing.value)

function reset() {
  parsed.value = null
  errors.value = []
  warnings.value = []
  fileName.value = ''
  catResolved.value = null
  catTouched.value = false
}

function fillForm(skill) {
  // 分类：SKILL.md 声明 → 内容推断 → other（规则见 @/lib/category）
  const cat = resolveCategory(skill)
  catResolved.value = cat
  catTouched.value = false

  form.value = {
    name: skill.name || '',
    description: skill.description || '',
    category: cat.key,
    tags: (skill.tags || []).join(', '),
    author: skill.author || '',
    version: skill.version || '1.0.0',
    license: skill.license || '',
  }
}

async function runParse(name, bytes) {
  parsing.value = true
  reset()
  try {
    const r = await parseSkill({ name, bytes }, limits)
    warnings.value = r.warnings || []
    errors.value = r.errors || []
    if (r.skill) {
      parsed.value = r.skill
      fillForm(r.skill)
      fileName.value = name
    }
  } catch (e) {
    errors.value = [`解析失败：${e?.message || '未知错误'}`]
  } finally {
    parsing.value = false
  }
}

async function onFiles(fileList) {
  const file = fileList?.[0]
  if (!file) return

  // 提前拦一次：压缩包原始大小就超过「解压后」的上限，必然是超的
  if (file.size > limits.maxTotalBytes) {
    reset()
    errors.value = [
      `文件 ${formatBytes(file.size)} 超过上限 ${formatBytes(limits.maxTotalBytes)}（这是解压后的上限，原始文件更大就一定超了）。`,
    ]
    return
  }

  const buf = await file.arrayBuffer()
  await runParse(file.name, new Uint8Array(buf))
}

async function onDrop(e) {
  dragOver.value = false
  await onFiles(e.dataTransfer?.files)
}

async function onPick(e) {
  await onFiles(e.target.files)
  // 清空 input，否则同一个文件连选两次不触发 change
  e.target.value = ''
}

async function onParseText() {
  const t = text.value.trim()
  if (!t) {
    reset()
    errors.value = ['请先粘贴 SKILL.md 的内容。']
    return
  }
  await runParse('SKILL.md', new TextEncoder().encode(t))
}

function onSwitchMode(m) {
  if (mode.value === m) return
  mode.value = m
  reset()
}

/** 校验表单（提交前）。服务端还有一道，两边判据要一致 */
function validateForm() {
  const e = []
  const name = form.value.name.trim()
  if (!name) e.push('技能名不能为空。')
  if (name.length > limits.maxNameLength) e.push(`技能名最多 ${limits.maxNameLength} 个字符。`)
  const desc = form.value.description.trim()
  if (!desc) e.push('描述不能为空 —— 它是别人在列表里唯一能看到的说明。')
  if (desc.length > limits.maxDescLength) e.push(`描述最多 ${limits.maxDescLength} 个字符。`)
  return e
}

async function onSubmit() {
  if (!parsed.value) return
  const formErrors = validateForm()
  if (formErrors.length) {
    errors.value = formErrors
    toast('还有几处需要补一下', 'error')
    return
  }
  errors.value = []

  publishing.value = true
  try {
    const payload = {
      ...parsed.value,
      name: form.value.name.trim(),
      description: form.value.description.trim(),
      category: form.value.category,
      tags: form.value.tags
        .split(/[,，]/)
        .map((s) => s.trim())
        .filter(Boolean)
        .slice(0, 12),
      author: form.value.author.trim(),
      version: form.value.version.trim() || '1.0.0',
      license: form.value.license.trim(),
    }

    const r = await publishSkill(payload)
    toast(r.code === 'exists' ? '这个技能已经有人传过了，帮你打开了已有的那条' : '上传成功！')
    router.push(`/skills/${r.slug}`)
  } catch (e) {
    errors.value = [errorText(e)]
    toast(errorText(e), 'error')
  } finally {
    publishing.value = false
  }
}
</script>

<template>
  <div class="hub-shell narrow">
    <LocalModeBanner />

    <header class="page-head">
      <router-link to="/" class="back no-select">
        <AppIcon name="back" :size="16" />
        返回列表
      </router-link>
      <h1 class="page-title">上传技能</h1>
      <p class="page-desc">
        支持 <b>.zip</b>（技能文件夹压缩包）或 <b>SKILL.md</b>（单个 Markdown）。
        上传后会在<b>浏览器里就地解析</b>，先给你看一遍元信息和文件结构，确认无误再提交。
      </p>
      <p class="page-note">
        <AppIcon name="info" :size="13" />{{ CATEGORY_RULE_HINT }}
      </p>
    </header>

    <!-- 输入方式 -->
    <div class="tabs">
      <button class="tab" :class="{ active: mode === 'file' }" @click="onSwitchMode('file')">
        <AppIcon name="upload" :size="15" :fill="mode === 'file' ? '#fff' : ''" />上传文件
      </button>
      <button class="tab" :class="{ active: mode === 'text' }" @click="onSwitchMode('text')">
        <AppIcon name="doc" :size="15" :fill="mode === 'text' ? '#fff' : ''" />粘贴文本
      </button>
    </div>

    <!-- 文件拖拽 -->
    <section v-if="mode === 'file'" class="card block">
      <div
        class="dropzone"
        :class="{ over: dragOver }"
        @dragover.prevent="dragOver = true"
        @dragleave.prevent="dragOver = false"
        @drop.prevent="onDrop"
        @click="fileInput?.click()"
      >
        <AppIcon name="upload" :size="34" />
        <p class="dz-main">
          <template v-if="parsing">正在解析…</template>
          <template v-else-if="fileName">{{ fileName }}</template>
          <template v-else>把 .zip 或 SKILL.md 拖到这里，或点击选择</template>
        </p>
        <p class="dz-sub">
          上限：{{ limits.maxFiles }} 个文件 / 解压后 {{ formatBytes(limits.maxTotalBytes) }}
        </p>
        <input
          ref="fileInput"
          class="sr-only"
          type="file"
          accept=".zip,.md,.markdown,.txt"
          @change="onPick"
        />
      </div>
    </section>

    <!-- 粘贴文本 -->
    <section v-else class="card block">
      <div class="field">
        <label for="md">SKILL.md 内容</label>
        <textarea
          id="md"
          v-model="text"
          class="textarea"
          rows="12"
          placeholder="---&#10;name: my-skill&#10;description: 这个技能用来做什么，什么时候该用它。&#10;---&#10;&#10;# My Skill&#10;…"
        />
        <span class="hint">整段粘贴即可，开头的 <code>---</code> frontmatter 会被自动解析出来。</span>
      </div>
      <button class="btn primary" :class="{ loading: parsing }" :disabled="parsing" @click="onParseText">
        <AppIcon name="search" :size="15" fill="#fff" />
        解析
      </button>
    </section>

    <!-- 错误 -->
    <section v-if="errors.length" class="card block alert error">
      <h2 class="block-title"><AppIcon name="warn" :size="17" />有 {{ errors.length }} 处需要处理</h2>
      <ul>
        <li v-for="(e, i) in errors" :key="i">{{ e }}</li>
      </ul>
    </section>

    <!-- 警告（不阻断） -->
    <section v-if="warnings.length && parsed" class="card block alert warn">
      <h2 class="block-title"><AppIcon name="info" :size="17" />解析时做了这些调整</h2>
      <ul>
        <li v-for="(w, i) in warnings" :key="i">{{ w }}</li>
      </ul>
    </section>

    <!-- 预览 + 表单 -->
    <template v-if="parsed && !errors.length">
      <section class="card block">
        <h2 class="block-title"><AppIcon name="info" :size="18" />元信息<span class="block-sub">可以直接改</span></h2>

        <div class="form-grid">
          <div class="field span2">
            <label for="f-name">技能名 *</label>
            <input id="f-name" v-model="form.name" class="input" :maxlength="limits.maxNameLength" />
            <span class="hint">地址会是 <code>/skills/{{ parsed.slug }}</code>（若重名，服务端会自动加后缀）</span>
          </div>

          <div class="field span2">
            <label for="f-desc">描述 *</label>
            <textarea
              id="f-desc"
              v-model="form.description"
              class="textarea short"
              :maxlength="limits.maxDescLength"
              placeholder="说清楚「什么时候该用这个技能」——这句话模型也会读到。"
            />
            <span class="hint">{{ form.description.length }} / {{ limits.maxDescLength }}</span>
          </div>

          <div class="field">
            <label for="f-cat">分类</label>
            <select
              id="f-cat"
              v-model="form.category"
              class="input select"
              @change="catTouched = true"
            >
              <option v-for="c in categoryOptions" :key="c.key" :value="c.key">{{ c.label }}</option>
            </select>
            <!-- 把「这个分类是怎么来的」说清楚 —— 之前这里只有一个下拉框，用户完全猜不到规则 -->
            <span class="hint cat-hint">
              <template v-if="catTouched">
                已手动选为「{{ categoryLabel(form.category) }}」。
              </template>
              <template v-else-if="catResolved?.source === 'declared'">
                SKILL.md 里写了 <code>category: {{ catResolved.declared }}</code>，直接采用。
              </template>
              <template v-else-if="catResolved?.source === 'inferred'">
                这个包的 SKILL.md 没写分类，按内容推断为「{{ categoryLabel(catResolved.key) }}」
                （命中：{{ catResolved.hits.slice(0, 6).join('、') }}）。推断可能不准，可以直接改。
              </template>
              <template v-else-if="catResolved?.source === 'invalid'">
                SKILL.md 里的 <code>category: {{ catResolved.declared }}</code> 不是本站的分类，
                按内容也认不出，先放在「其他」——请手动选一个。
              </template>
              <template v-else>
                没写分类，按内容也认不出属于哪一类，先放在「其他」——请手动选一个。
              </template>
            </span>
          </div>

          <div class="field">
            <label for="f-tags">标签</label>
            <input id="f-tags" v-model="form.tags" class="input" placeholder="用逗号分隔，最多 12 个" />
          </div>

          <div class="field">
            <label for="f-author">作者</label>
            <input id="f-author" v-model="form.author" class="input" placeholder="留空会记为 anonymous" />
          </div>

          <div class="field">
            <label for="f-ver">版本</label>
            <input id="f-ver" v-model="form.version" class="input" placeholder="1.0.0" />
          </div>

          <div class="field">
            <label for="f-license">许可证</label>
            <input id="f-license" v-model="form.license" class="input" placeholder="MIT / Apache-2.0 …" />
          </div>
        </div>
      </section>

      <section class="card block">
        <h2 class="block-title">
          <AppIcon name="folder" :size="18" />文件结构
          <span class="block-sub">
            {{ parsed.fileCount }} 个文件 · {{ formatBytes(parsed.totalBytes) }} ·
            压缩后 {{ formatBytes(parsed.bundle.length) }}
          </span>
        </h2>
        <div class="tree-wrap">
          <FileTree v-if="tree" :node="tree" />
        </div>
      </section>

      <div class="submit-bar">
        <span class="submit-note">
          提交即表示你确认这个技能包可以公开分发。
        </span>
        <button class="btn primary" :class="{ loading: publishing }" :disabled="!canSubmit" @click="onSubmit">
          <AppIcon name="upload" :size="16" fill="#fff" />
          确认上传
        </button>
      </div>
    </template>
  </div>
</template>

<style scoped>
.narrow {
  max-width: 860px;
}

.page-head {
  padding: 18px 0 20px;
}

/* 与详情页的 .back 保持同一套写法，两个页面的返回入口看起来才是一家的 */
.back {
  align-items: center;
  color: var(--hub_muted);
  display: inline-flex;
  font-size: 13px;
  gap: 5px;
  margin-bottom: 16px;
  transition: color 0.2s ease;
}

.back:hover {
  color: var(--main_text_color);
}

.back svg {
  fill: currentColor;
}

.page-title {
  font-size: 34px;
  font-weight: 800;
  margin: 0;
}

.page-desc {
  color: var(--hub_muted);
  font-size: 14px;
  line-height: 1.7;
  margin-top: 10px;
}

.page-desc b {
  color: var(--main_text_color);
}

/* 分类规则说明。之前规则只存在于代码里，用户只能靠猜 —— 现在摆在页头上 */
.page-note {
  align-items: flex-start;
  background: var(--hub_code_bg);
  border: 1px solid var(--hub_line);
  border-radius: 9px;
  color: var(--hub_muted);
  display: flex;
  font-size: 12.5px;
  gap: 7px;
  line-height: 1.65;
  margin-top: 14px;
  padding: 10px 12px;
}

.page-note svg {
  fill: var(--hub_muted);
  flex-shrink: 0;
  margin-top: 2px;
}

.tabs {
  display: flex;
  gap: 8px;
  margin-bottom: 14px;
}

.tab {
  align-items: center;
  background: var(--item_bg_color);
  border: 1px solid var(--hub_line);
  border-radius: 8px;
  color: var(--main_text_color);
  cursor: pointer;
  display: inline-flex;
  font-family: inherit;
  font-size: 13px;
  gap: 6px;
  height: 34px;
  padding: 0 14px;
  transition:
    background-color 0.2s ease,
    border-color 0.2s ease;
}

.tab:hover {
  background: var(--item_hover_color);
}

.tab.active {
  background: var(--gradient);
  border-color: transparent;
  color: #fff;
  font-weight: 600;
}

.block {
  margin-bottom: 16px;
  padding: 20px 22px;
}

.block-title {
  align-items: center;
  display: flex;
  flex-wrap: wrap;
  font-size: 16px;
  font-weight: 700;
  gap: 8px;
  margin: 0 0 14px;
}

.block-title svg {
  fill: var(--hub_muted);
}

.block-sub {
  color: var(--hub_muted);
  font-size: 12px;
  font-weight: 400;
}

/* ------------------------------------------------------------ 拖拽区 */
.dropzone {
  align-items: center;
  border: 2px dashed var(--hub_line_strong);
  border-radius: 11px;
  cursor: pointer;
  display: flex;
  flex-direction: column;
  gap: 8px;
  padding: 40px 20px;
  text-align: center;
  transition:
    background-color 0.2s ease,
    border-color 0.2s ease;
}

.dropzone:hover,
.dropzone.over {
  background: var(--item_bg_color);
  border-color: var(--hub_accent);
}

.dropzone svg {
  fill: var(--hub_muted);
}

.dz-main {
  font-size: 15px;
  word-break: break-all;
}

.dz-sub {
  color: var(--hub_muted);
  font-size: 12px;
}

/* -------------------------------------------------------------- 表单 */
.form-grid {
  display: grid;
  gap: 14px;
  grid-template-columns: 1fr 1fr;
}

.span2 {
  grid-column: 1 / -1;
}

.textarea.short {
  min-height: 76px;
}

.select {
  cursor: pointer;
}

.select option {
  background: #1b1b23;
  color: #eee;
}

/* 分类来源说明。比普通 hint 多一行，因为要容纳「命中：xxx、yyy」 */
.cat-hint {
  line-height: 1.6;
}

.cat-hint code {
  background: var(--hub_code_bg);
  border: 1px solid var(--hub_line);
  border-radius: 4px;
  font-family: ui-monospace, SFMono-Regular, Menlo, monospace;
  font-size: 11.5px;
  padding: 1px 4px;
}

/* -------------------------------------------------------------- 提示 */
.alert ul {
  display: flex;
  flex-direction: column;
  gap: 7px;
  list-style: none;
  margin: 0;
  padding: 0;
}

.alert li {
  font-size: 13px;
  line-height: 1.6;
  padding-left: 14px;
  position: relative;
}

.alert li::before {
  content: '•';
  left: 0;
  position: absolute;
}

.alert.error {
  background: #ff6b6b1a;
  border-color: #ff6b6b66;
}

.alert.error .block-title,
.alert.error li::before {
  color: var(--hub_err);
}

.alert.error .block-title svg {
  fill: var(--hub_err);
}

.alert.warn {
  background: #ffb0201a;
  border-color: #ffb02066;
}

.alert.warn .block-title {
  color: #ffd489;
}

.alert.warn .block-title svg {
  fill: #ffb020;
}

.tree-wrap {
  max-height: 300px;
  overflow: auto;
}

/* ------------------------------------------------------------ 提交栏 */
.submit-bar {
  align-items: center;
  display: flex;
  flex-wrap: wrap;
  gap: 12px;
  justify-content: space-between;
  margin-top: 6px;
}

.submit-note {
  color: var(--hub_muted);
  font-size: 12px;
}

@media (max-width: 640px) {
  .form-grid {
    grid-template-columns: 1fr;
  }

  .page-title {
    font-size: 26px;
  }

  .submit-bar .btn {
    width: 100%;
  }
}
</style>
