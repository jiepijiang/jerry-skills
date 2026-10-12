<script setup>
import { computed, ref, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import AppIcon from '@/components/AppIcon.vue'
import AppDialog from '@/components/AppDialog.vue'
import FileTree from '@/components/FileTree.vue'
import EmptyState from '@/components/EmptyState.vue'
import StarRating from '@/components/StarRating.vue'
import {
  adminNotes,
  agents,
  DEFAULT_AGENT,
  categoryLabel,
  categoryIcon,
  metricNotes,
  oses,
  osByKey,
  ratings,
  SITE_URL,
} from '@/data/site'
import { buildTree, formatBytes } from '@/lib/parseSkill'
import { absoluteTime, relativeTime } from '@/lib/time'
import { agentPrompt, cliCommand, detectOS } from '@/lib/install'
import { downloadSkill, errorText, getSkill, rateSkill, registerInstall, saveBlob } from '@/lib/skills-api'
import { adminToken, isAdmin } from '@/lib/admin'
import { useSkillDelete } from '@/composables/useAdmin'
import { useCopy } from '@/composables/useCopy'
import { toast } from '@/composables/useToast'

const route = useRoute()
const router = useRouter()

const skill = ref(null)
const loading = ref(true)
const error = ref('')
const notFound = ref(false)
const downloading = ref(false)

const tab = ref('cli') // cli | agent
const agent = ref(DEFAULT_AGENT)
/**
 * 安装命令针对哪个系统。
 *
 * 默认值按 UA 猜（Windows 用户打开页面就是对的），但**必须能改** ——
 * 猜错的时候用户自己切一下就行，比让他去理解「为什么给我 Windows 命令」强。
 * 只有两档：macOS 与 Linux 共用同一条 curl|bash，见 @/data/site 的 oses。
 */
const os = ref(detectOS())

/* 站主专属：删除 */
const confirmOpen = ref(false)
const { busy: deleting, remove } = useSkillDelete()

/* 评分 */
const ratingBusy = ref(false)

const { done: cmdDone, copy: copyCmd } = useCopy({ silent: true })
const { done: promptDone, copy: copyPrompt } = useCopy({ silent: true })
const { done: mdDone, copy: copyMd } = useCopy({ silent: true })

const tree = computed(() => (skill.value ? buildTree(skill.value.files || []) : null))
const cliText = computed(() =>
  skill.value ? cliCommand(skill.value.slug, agent.value, os.value) : '',
)
const promptText = computed(() =>
  skill.value ? agentPrompt(skill.value, agent.value, os.value) : '',
)
const targetDir = computed(() => agents.find((a) => a.key === agent.value)?.dir || '')
const osInfo = computed(() => osByKey(os.value))

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

/**
 * 打分 / 改分。
 *
 * 服务端是「一人一票、再打一次是覆盖」，所以这里不需要「我评过了吗」的分支 ——
 * 直接打，返回值里带着覆盖之后的平均分和人数，一次往返就够。
 *
 * 乐观更新：先把星星点亮，失败了再回滚。不这么做的话，从点击到服务端回来
 * 之间有一段「点了没反应」的空白 —— 用户会以为没点上，然后去点第二遍。
 */
async function onRate(n) {
  if (!skill.value || ratingBusy.value) return

  const prev = {
    my: skill.value.my_score,
    avg: skill.value.rating_avg,
    cnt: skill.value.rating_count,
  }
  skill.value.my_score = n
  ratingBusy.value = true

  try {
    const r = await rateSkill(skill.value.slug, n)
    skill.value.my_score = r.my_score
    skill.value.rating_avg = r.rating_avg
    skill.value.rating_count = r.rating_count
    toast(ratings.thanks(n))
  } catch (e) {
    skill.value.my_score = prev.my
    skill.value.rating_avg = prev.avg
    skill.value.rating_count = prev.cnt
    toast(errorText(e), 'error')
  } finally {
    ratingBusy.value = false
  }
}

/**
 * 删除。成功之后回列表 —— 留在这个页面只会看到「没有找到这个技能」，
 * 那不是一个好的收尾。
 */
async function onDelete() {
  const ok = await remove(skill.value.slug, adminToken.value)
  confirmOpen.value = false
  if (ok) router.push('/')
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
      <button class="btn" @click="load(route.params.slug)">重试</button>
    </EmptyState>

    <EmptyState v-else-if="notFound" icon="box" text="没有找到这个技能，可能已经被删掉了。">
      <router-link to="/" class="btn">回到列表</router-link>
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
            <span class="meta" :title="metricNotes.downloads">
              <AppIcon name="download" :size="14" />{{ skill.downloads }} 次下载
            </span>
            <span class="meta" :title="metricNotes.installs">
              <AppIcon name="terminal" :size="14" />{{ skill.installs }} 次安装
            </span>
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
            <!-- 站主专属：解锁之后才出现（见页脚的「管理」入口） -->
            <button v-if="isAdmin" class="btn danger" type="button" @click="confirmOpen = true">
              <AppIcon name="trash" :size="15" />
              {{ adminNotes.deleteButton }}
            </button>
          </div>
        </div>
      </header>

      <!-- ------------------------------------------------ 评分 -->
      <!--
        位置刻意放在头部之后、安装之前：评分是「要不要用它」的判断依据，
        比「怎么装」更靠前一步。放在页面底部的话，绝大多数人看不到。
      -->
      <section class="card block rate">
        <h2 class="block-title">
          <AppIcon name="star" :size="18" />评分
          <span class="block-sub">
            {{ skill.rating_count ? `${skill.rating_count} 人评过` : '还没人评过' }}
          </span>
        </h2>

        <div class="rate-row">
          <!-- 左：当前的社区口碑 -->
          <div class="rate-view">
            <StarRating readonly :avg="skill.rating_avg" :count="skill.rating_count" :size="22" />
          </div>

          <!-- 右：打分入口。busy 期间整块变灰且不可点，避免连点打出两次请求 -->
          <div class="rate-act" :class="{ busy: ratingBusy }">
            <StarRating :model-value="skill.my_score" :size="26" @rate="onRate" />
          </div>
        </div>

        <!--
          ⚠️ 正文整段包在 <span> 里：.metric-note 是 display:flex，
             直接摊开的话文本节点和 <template> 里的内容会各成一个 flex item、各自换行。
             （同一个坑在下面的安装区已经踩过一次，注释在那儿。）
        -->
        <p class="block-hint metric-note" :title="metricNotes.rating">
          <AppIcon name="info" :size="13" />
          <span>
            {{ ratings.hint }}
            <template v-if="skill.my_score">
              你已经给了 <b>{{ skill.my_score }} 星</b>，点别的星星就是改分，不会变成第二票。
            </template>
          </span>
        </p>
      </section>

      <!-- ------------------------------------------------ 安装 -->
      <section class="card block install">
        <h2 class="block-title">
          <AppIcon name="terminal" :size="18" />安装
          <span class="block-sub">复制即计入「安装量」</span>
        </h2>

        <!--
          ⚠️ 正文必须整段包在一个 <span> 里，不能直接摊在 .metric-note 下面。
             这个 p 是 display:flex，直接放文本 + <b> 的话，文本节点和 <b> 会各自变成
             独立的 flex item、各自换行 —— 表现是「复制次数」被拆成「复制次」/「数」两行，
             中间还夹一个孤零零的「是」。
        -->
        <p class="block-hint metric-note" :title="metricNotes.installs">
          <AppIcon name="info" :size="13" />
          <span>
            本站的「安装量」数的是<b>复制次数</b>，不是真的装了多少台机器 ——
            纯静态站点拿不到「命令被粘贴执行了」的信号。这是刻意的取舍：宁可标一个诚实的近似值，
            也不编一个看着精确的假数字。
          </span>
        </p>

        <div class="tabs">
          <button class="tab" :class="{ active: tab === 'cli' }" @click="tab = 'cli'">
            <AppIcon name="terminal" :size="15" :fill="tab === 'cli' ? '#fff' : ''" />命令行
          </button>
          <button class="tab" :class="{ active: tab === 'agent' }" @click="tab = 'agent'">
            <AppIcon name="robot" :size="15" :fill="tab === 'agent' ? '#fff' : ''" />AI Agent
          </button>

          <!-- 两个选择器包在一起，才能整体靠右；分开写的话每个都 margin-left:auto，
               中间会被撑开一大段空白。 -->
          <div class="picks">
            <label class="pick">
              <span>装到</span>
              <select v-model="agent" class="input select">
                <option v-for="a in agents" :key="a.key" :value="a.key">{{ a.label }}</option>
              </select>
            </label>

            <label class="pick">
              <span>系统</span>
              <select v-model="os" class="input select">
                <option v-for="o in oses" :key="o.key" :value="o.key">{{ o.label }}</option>
              </select>
            </label>
          </div>
        </div>

        <template v-if="tab === 'cli'">
          <p class="block-hint">
            {{ osInfo.hint }}下面这条命令，技能会被装到
            <code>{{ targetDir }}/{{ skill.slug }}</code>。
          </p>
          <div class="code-block cmd-block">
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

      <!-- ------------------------------------------------ 删除（站主专属） -->
      <AppDialog
        :open="confirmOpen"
        danger
        icon="trash"
        :title="adminNotes.deleteTitle"
        @close="confirmOpen = false"
      >
        <p class="dlg-p">确定要删除 <b>{{ skill.name }}</b> 吗？</p>
        <p class="dlg-p">
          它被下载过 {{ skill.downloads }} 次、安装命令被复制过 {{ skill.installs }} 次，
          这些数字会一起消失。链接 <code>/skills/{{ skill.slug }}</code> 会立刻失效，
          别人再打开只会看到「没有找到」。
        </p>
        <p class="dlg-p dlg-note">
          服务端会先存一份快照到回收站（保留 90 天）。要恢复就在 Supabase 里按
          supabase/README.md 那节操作 —— 界面上没有恢复入口。
        </p>

        <template #actions>
          <button class="btn sm" type="button" @click="confirmOpen = false">{{ adminNotes.cancel }}</button>
          <button
            class="btn sm danger solid"
            :class="{ loading: deleting }"
            type="button"
            :disabled="deleting"
            @click="onDelete"
          >
            {{ adminNotes.confirmDelete }}
          </button>
        </template>
      </AppDialog>
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

/* 「下载 .zip」和站主的「删除技能」并排。删除是描边红（见 hub.css 的 .btn.danger），
   不抢下载的视觉权重。 */
.head-actions {
  align-items: center;
  display: flex;
  gap: 9px;
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

/* ---------------------------------------------------------------- 评分 */
/* 左边是「大家给的分」，右边是「我给它打分」。
   justify-content: space-between 把它们推到两端；窄屏时 wrap 成上下两行。 */
.rate-row {
  align-items: center;
  display: flex;
  flex-wrap: wrap;
  gap: 14px 24px;
  justify-content: space-between;
  margin-bottom: 14px;
}

.rate-view {
  align-items: center;
  display: flex;
  gap: 10px;
}

.rate-act {
  align-items: center;
  display: flex;
  gap: 9px;
  transition: opacity 0.15s ease;
}

/* 请求在飞的时候：变灰 + 不吃点击。只置灰不禁用的话，连点仍会打两次请求 */
.rate-act.busy {
  opacity: 0.55;
  pointer-events: none;
}

/* ---------------------------------------------------------------- 安装 */
/* 计量口径说明。比普通 block-hint 弱一档 —— 它是「解释」，不该跟操作说明抢注意力 */
.metric-note {
  align-items: flex-start;
  display: flex;
  font-size: 12.5px;
  gap: 6px;
  margin-bottom: 14px;
}

.metric-note svg {
  fill: var(--hub_muted);
  flex-shrink: 0;
  margin-top: 3px;
}

.metric-note b {
  color: var(--main_text_color);
  font-weight: 600;
}

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

/* 两个选择器（装到 / 系统）整体靠右。
   别给每个 .pick 各写 margin-left:auto —— 那样它们中间会被撑开一大段空白。 */
.picks {
  align-items: center;
  display: flex;
  flex-wrap: wrap;
  gap: 10px;
  margin-left: auto;
}

.pick {
  align-items: center;
  color: var(--hub_muted);
  display: flex;
  font-size: 13px;
  gap: 7px;
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

/* ------------------------------------------------------------ 弹窗内容 */
.dlg-p {
  margin: 0;
}

.dlg-p + .dlg-p {
  margin-top: 8px;
}

.dlg-p b {
  color: var(--main_text_color);
}

.dlg-p code {
  background: var(--hub_code_bg);
  border-radius: 5px;
  padding: 1px 5px;
}

.dlg-note {
  font-size: 12.5px;
  opacity: 0.8;
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

  .picks {
    margin-left: 0;
    width: 100%;
  }

  /* 窄屏两个选择器各占一半，别让「系统」被挤到下一行还只占一小截 */
  .pick {
    flex: 1 1 45%;
  }

  .pick .select {
    flex: 1;
    min-width: 0;
  }
}
</style>
