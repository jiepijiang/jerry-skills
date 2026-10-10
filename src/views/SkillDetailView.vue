<script setup>
import { computed, ref, watch } from 'vue'
import { useRoute } from 'vue-router'
import AppIcon from '@/components/AppIcon.vue'
import FileTree from '@/components/FileTree.vue'
import EmptyState from '@/components/EmptyState.vue'
import { agents, DEFAULT_AGENT, categoryLabel, categoryIcon, SITE_URL } from '@/data/site'
import { buildTree, formatBytes } from '@/lib/parseSkill'
import { absoluteTime, relativeTime } from '@/lib/time'
import { agentPrompt, cliCommand } from '@/lib/install'
import { downloadSkill, errorText, getSkill, registerInstall, saveBlob } from '@/lib/skills-api'
import { useCopy } from '@/composables/useCopy'
import { toast } from '@/composables/useToast'

const route = useRoute()

const skill = ref(null)
const loading = ref(true)
const error = ref('')
const notFound = ref(false)
const downloading = ref(false)

const tab = ref('cli') // cli | agent
const agent = ref(DEFAULT_AGENT)

const { done: cmdDone, copy: copyCmd } = useCopy({ silent: true })
const { done: promptDone, copy: copyPrompt } = useCopy({ silent: true })
const { done: mdDone, copy: copyMd } = useCopy({ silent: true })

const tree = computed(() => (skill.value ? buildTree(skill.value.files || []) : null))
const cliText = computed(() => (skill.value ? cliCommand(skill.value.slug, agent.value) : ''))
const promptText = computed(() => (skill.value ? agentPrompt(skill.value, agent.value) : ''))
const targetDir = computed(() => agents.find((a) => a.key === agent.value)?.dir || '')

/**
 * 上传时间。解析不了时 `uploaded` 是空串 —— 用它当 v-if 的条件，
 * 而不是 `v-if="skill.created_at"`：后者在时间戳格式不对时会渲染出
 * 「上传于 」这种半截文案（`created_at` 有值但 Date 解析失败）。
 */
const uploaded = computed(() => relativeTime(skill.value?.created_at))
const uploadedAbs = computed(() => absoluteTime(skill.value?.created_at))

async function load(slug) {
  loading.value = true
  error.value = ''
  notFound.value = false
  try {
    const s = await getSkill(slug)
    if (!s) {
      notFound.value = true
      skill.value = null
    } else {
      skill.value = s
    }
  } catch (e) {
    error.value = errorText(e)
  } finally {
    loading.value = false
  }
}

/** 复制安装命令 / agent 提示词都算一次「安装」—— 这是本站能拿到的最接近真实安装的信号 */
async function onCopy(kind) {
  const text = kind === 'cli' ? cliText.value : promptText.value
  const ok = kind === 'cli' ? await copyCmd(text, '') : await copyPrompt(text, '')
  if (!ok) return
  toast(kind === 'cli' ? '安装命令已复制，粘到终端执行' : '提示词已复制，粘给你的 AI 助手')
  if (!skill.value) return
  try {
    const r = await registerInstall(skill.value.slug)
    skill.value.installs = r.installs
  } catch {
    // 计数失败不该影响复制这件事本身，静默即可（复制已经成功了）
  }
}

async function onCopyMd() {
  if (!skill.value) return
  const ok = await copyMd(skill.value.readme, '')
  if (ok) toast('SKILL.md 已复制')
}

async function onDownload() {
  if (!skill.value || downloading.value) return
  downloading.value = true
  try {
    const r = await downloadSkill(skill.value.slug)
    saveBlob(r.filename, r.bytes)
    skill.value.downloads = r.downloads
    toast(`已开始下载 ${r.filename}`)
  } catch (e) {
    toast(errorText(e), 'error')
  } finally {
    downloading.value = false
  }
}

watch(() => route.params.slug, (s) => s && load(s), { immediate: true })
</script>

<template>
  <div class="hub-shell">
    <router-link to="/" class="back no-select">
      <AppIcon name="back" :size="16" />
      返回列表
    </router-link>

    <!-- 加载中 -->
    <div v-if="loading" class="stack">
      <div class="skeleton card sk-head" />
      <div class="skeleton card sk-block" />
      <div class="skeleton card sk-block" />
    </div>

    <!-- 出错 / 不存在 -->
    <EmptyState v-else-if="error" icon="warn" :text="error">
      <button class="btn sm" @click="load(route.params.slug)">重试</button>
    </EmptyState>

    <EmptyState v-else-if="notFound" icon="box" text="没有找到这个技能，可能已经被删掉了。">
      <router-link to="/" class="btn sm">回到列表</router-link>
    </EmptyState>

    <template v-else-if="skill">
      <!-- ------------------------------------------------ 头部 -->
      <header class="card head">
        <div class="head-main">
          <span class="head-icon"><AppIcon :name="categoryIcon(skill.category)" :size="22" fill="#fff" /></span>
          <div class="head-text">
            <h1 class="head-name">
              {{ skill.name }}
              <span class="ver">v{{ skill.version }}</span>
            </h1>
            <p class="head-desc">{{ skill.description || '（这个技能还没写描述）' }}</p>
          </div>
        </div>

        <div class="head-tags">
          <span class="tag cat">{{ categoryLabel(skill.category) }}</span>
          <span v-for="t in skill.tags" :key="t" class="tag">{{ t }}</span>
        </div>

        <div class="head-foot">
          <div class="metas">
            <span class="meta"><AppIcon name="download" :size="14" />{{ skill.downloads }} 次下载</span>
            <span class="meta"><AppIcon name="terminal" :size="14" />{{ skill.installs }} 次安装</span>
            <span class="meta"><AppIcon name="file" :size="14" />{{ skill.file_count }} 个文件</span>
            <span class="meta"><AppIcon name="box" :size="14" />{{ formatBytes(skill.total_bytes) }}</span>
            <span class="meta muted">
              by {{ skill.author }}<template v-if="skill.license"> · {{ skill.license }}</template>
              <template v-if="uploaded">
                · <span :title="`上传于 ${uploadedAbs}`">上传于 {{ uploaded }}</span>
              </template>
            </span>
          </div>

          <div class="head-actions">
            <button class="btn primary" :class="{ loading: downloading }" :disabled="downloading" @click="onDownload">
              <AppIcon name="download" :size="15" fill="#fff" />
              下载 .zip
            </button>
          </div>
        </div>
      </header>

      <!-- ------------------------------------------------ 安装 -->
      <section class="card block install">
        <h2 class="block-title"><AppIcon name="terminal" :size="18" />安装</h2>

        <div class="tabs">
          <button class="tab" :class="{ active: tab === 'cli' }" @click="tab = 'cli'">
            <AppIcon name="terminal" :size="15" :fill="tab === 'cli' ? '#fff' : ''" />命令行
          </button>
          <button class="tab" :class="{ active: tab === 'agent' }" @click="tab = 'agent'">
            <AppIcon name="robot" :size="15" :fill="tab === 'agent' ? '#fff' : ''" />AI Agent
          </button>

          <label class="agent-pick">
            <span>装到</span>
            <select v-model="agent" class="input select">
              <option v-for="a in agents" :key="a.key" :value="a.key">{{ a.label }}</option>
            </select>
          </label>
        </div>

        <template v-if="tab === 'cli'">
          <p class="block-hint">
            在终端执行下面这条命令，技能会被装到 <code>{{ targetDir }}/{{ skill.slug }}</code>。
          </p>
          <div class="code-block">
            <pre>{{ cliText }}</pre>
            <button class="code-copy" :class="{ done: cmdDone }" @click="onCopy('cli')">
              <AppIcon :name="cmdDone ? 'check' : 'copy'" :size="13" />
              {{ cmdDone ? '已复制' : '复制' }}
            </button>
          </div>
        </template>

        <template v-else>
          <p class="block-hint">
            把下面这段话整段粘给你的 AI 助手（Claude Code / Cursor / WorkBuddy 都行），
            它会自己执行安装并回报结果。
          </p>
          <div class="code-block prompt-block">
            <pre>{{ promptText }}</pre>
            <button class="code-copy" :class="{ done: promptDone }" @click="onCopy('agent')">
              <AppIcon :name="promptDone ? 'check' : 'copy'" :size="13" />
              {{ promptDone ? '已复制' : '复制' }}
            </button>
          </div>
        </template>
      </section>

      <!-- ------------------------------------------------ 结构 + 安全 -->
      <div class="two-col">
        <section class="card block">
          <h2 class="block-title">
            <AppIcon name="folder" :size="18" />文件结构
            <span class="block-sub">{{ skill.file_count }} 个文件 · {{ formatBytes(skill.total_bytes) }}</span>
          </h2>
          <div class="tree-wrap">
            <FileTree v-if="tree" :node="tree" />
          </div>
        </section>

        <section class="card block">
          <h2 class="block-title"><AppIcon name="shield" :size="18" />安装前请看一眼</h2>
          <ul class="safety">
            <li>技能包里的脚本会在<b>你的机器上执行</b>，装之前建议先过一遍上面的文件结构。</li>
            <li>本站的下载量 / 安装量只是「有人点过」，<b>不代表技能被审核过</b>。</li>
            <li>技能来源是上传者，页面上不保证与任何官方仓库一致。</li>
            <li>发现可疑内容可以到
              <a href="https://github.com/jiepijiang/jerry-skills/issues" target="_blank" rel="noopener noreferrer">仓库提 issue</a>。
            </li>
          </ul>
          <p class="share-url">
            <AppIcon name="link" :size="13" />
            <code>{{ SITE_URL }}/skills/{{ skill.slug }}</code>
          </p>
        </section>
      </div>

      <!-- ------------------------------------------------ SKILL.md -->
      <section class="card block">
        <h2 class="block-title">
          <AppIcon name="doc" :size="18" />SKILL.md
          <span class="block-sub">技能的说明书，也是模型判断「什么时候用它」的依据</span>
        </h2>
        <div v-if="skill.readme" class="code-block md-block">
          <pre>{{ skill.readme }}</pre>
          <button class="code-copy" :class="{ done: mdDone }" @click="onCopyMd">
            <AppIcon :name="mdDone ? 'check' : 'copy'" :size="13" />
            {{ mdDone ? '已复制' : '复制' }}
          </button>
        </div>
        <p v-else class="block-hint">这个技能包里没有 SKILL.md 内容。</p>
      </section>
    </template>
  </div>
</template>

<style scoped>
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

.stack {
  display: flex;
  flex-direction: column;
  gap: 14px;
}

.sk-head {
  height: 180px;
}

.sk-block {
  height: 150px;
}

/* ---------------------------------------------------------------- 头部 */
.head {
  display: flex;
  flex-direction: column;
  gap: 14px;
  padding: 22px;
}

.head-main {
  align-items: flex-start;
  display: flex;
  gap: 14px;
}

.head-icon {
  align-items: center;
  background: var(--gradient);
  border-radius: 11px;
  display: flex;
  flex-shrink: 0;
  height: 44px;
  justify-content: center;
  width: 44px;
}

.head-text {
  min-width: 0;
}

.head-name {
  align-items: baseline;
  display: flex;
  flex-wrap: wrap;
  font-size: 26px;
  font-weight: 700;
  gap: 9px;
  line-height: 1.25;
  margin: 0;
  word-break: break-word;
}

.ver {
  color: var(--hub_muted);
  font-size: 13px;
  font-weight: 400;
}

.head-desc {
  color: var(--hub_muted);
  font-size: 14px;
  line-height: 1.65;
  margin-top: 8px;
}

.head-tags {
  display: flex;
  flex-wrap: wrap;
  gap: 6px;
}

.tag.cat {
  background: #bd34fe2e;
  color: #e0b0ff;
}

.head-foot {
  align-items: center;
  border-top: 1px solid var(--hub_line);
  display: flex;
  flex-wrap: wrap;
  gap: 12px;
  justify-content: space-between;
  padding-top: 14px;
}

.metas {
  display: flex;
  flex-wrap: wrap;
  gap: 14px;
}

.meta {
  align-items: center;
  color: var(--main_text_color);
  display: inline-flex;
  font-size: 13px;
  gap: 5px;
}

.meta svg {
  fill: var(--hub_muted);
}

.meta.muted {
  color: var(--hub_muted);
}

/* ---------------------------------------------------------------- 区块 */
.block {
  margin-top: 16px;
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

.block-hint {
  color: var(--hub_muted);
  font-size: 13px;
  line-height: 1.6;
  margin-bottom: 11px;
}

.block-hint code {
  background: var(--hub_code_bg);
  border-radius: 5px;
  padding: 1px 5px;
}

/* ---------------------------------------------------------------- 安装 */
.tabs {
  align-items: center;
  display: flex;
  flex-wrap: wrap;
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
  height: 32px;
  padding: 0 13px;
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

.agent-pick {
  align-items: center;
  color: var(--hub_muted);
  display: flex;
  font-size: 13px;
  gap: 7px;
  margin-left: auto;
}

.select {
  cursor: pointer;
  font-size: 13px;
  height: 32px;
  padding: 0 8px;
  width: auto;
}

.select option {
  background: #1b1b23;
  color: #eee;
}

.prompt-block pre {
  white-space: pre-wrap;
  word-break: break-word;
}

/* -------------------------------------------------------------- 双栏 */
.two-col {
  display: grid;
  gap: 16px;
  grid-template-columns: 1fr 1fr;
}

.tree-wrap {
  max-height: 320px;
  overflow: auto;
}

.safety {
  color: var(--hub_muted);
  display: flex;
  flex-direction: column;
  font-size: 13px;
  gap: 9px;
  line-height: 1.6;
  list-style: none;
  margin: 0;
  padding: 0;
}

.safety li {
  padding-left: 14px;
  position: relative;
}

.safety li::before {
  color: var(--hub_accent);
  content: '•';
  left: 0;
  position: absolute;
}

.safety b {
  color: var(--main_text_color);
}

.safety a {
  color: var(--purple_text_color);
}

.share-url {
  align-items: center;
  border-top: 1px solid var(--hub_line);
  color: var(--hub_muted);
  display: flex;
  font-size: 12px;
  gap: 6px;
  margin-top: 14px;
  padding-top: 12px;
}

.share-url svg {
  fill: var(--hub_muted);
  flex-shrink: 0;
}

.share-url code {
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.md-block pre {
  max-height: 460px;
  overflow: auto;
  white-space: pre-wrap;
  word-break: break-word;
}

@media (max-width: 860px) {
  .two-col {
    grid-template-columns: 1fr;
  }

  .head-name {
    font-size: 21px;
  }

  .head-foot {
    align-items: stretch;
    flex-direction: column;
  }

  .head-actions .btn {
    width: 100%;
  }

  .agent-pick {
    margin-left: 0;
    width: 100%;
  }
}
</style>
