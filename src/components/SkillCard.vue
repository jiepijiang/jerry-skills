<script setup>
import { computed, ref } from 'vue'
import AppIcon from './AppIcon.vue'
import AppDialog from './AppDialog.vue'
import { adminNotes, categoryIcon, categoryLabel, metricNotes } from '@/data/site'
import { absoluteTime, relativeTime } from '@/lib/time'
import { adminToken, isAdmin } from '@/lib/admin'
import { useSkillDelete } from '@/composables/useAdmin'

/**
 * 技能卡片。
 * 视觉沿用主站 ProjectCard 的玻璃卡语言（--item_bg_color + 圆角 + hover 上浮），
 * 但改成纵向布局 —— 技能的信息密度比项目卡片高（描述 / 标签 / 三个统计）。
 *
 * 结构上有一处刻意安排：**根节点是 <div>，不是 <router-link>**。
 * 因为站主解锁后卡片上要多一个删除按钮，而 `<button>` 嵌在 `<a>` 里是
 * 非法嵌套（<a> 不允许包含交互内容），点击归属在部分浏览器上也不可靠。
 * 现在链接只包内容、删除按钮是它的兄弟节点 —— HTML 合法，而且点按钮
 * 根本不会冒泡到链接，不需要靠 stopPropagation 去救。
 */
const props = defineProps({
  skill: { type: Object, required: true },
})

const emit = defineEmits(['deleted'])

const confirmOpen = ref(false)
const { busy: deleting, remove } = useSkillDelete()

/**
 * 上传时间（相对）。后端 `list_skills` 本来就返回 created_at，前端不用额外请求。
 *
 * 为什么是「上传」而不是「更新」：`skills` 表**只有 created_at，没有 updated_at**，
 * 而且 `publish_skill` 从不 update 已有行 —— 内容相同直接返回 exists，
 * 内容不同则换一个带后缀的新 slug 插一行。也就是说这个站现在**根本没有「更新」这件事**，
 * 加个 updated_at 只会得到一列永远等于 created_at 的假信息。
 */
const uploaded = computed(() => relativeTime(props.skill?.created_at))
const uploadedAbs = computed(() => absoluteTime(props.skill?.created_at))

async function onDelete() {
  const ok = await remove(props.skill.slug, adminToken.value)
  confirmOpen.value = false
  if (ok) emit('deleted', props.skill.slug)
}

function fmt(n) {
  const v = Number(n) || 0
  if (v < 1000) return String(v)
  return `${(v / 1000).toFixed(v < 10000 ? 1 : 0)}k`
}
</script>

<template>
  <div class="skill-card card" :class="{ managing: isAdmin }">
    <router-link class="sc-body" :to="`/skills/${skill.slug}`">
      <div class="sc-head">
        <span class="sc-icon" :title="categoryLabel(skill.category)">
          <AppIcon :name="categoryIcon(skill.category)" :size="17" fill="#fff" />
        </span>
        <h3 class="sc-name">{{ skill.name }}</h3>
        <span class="sc-ver">v{{ skill.version }}</span>
      </div>

      <p class="sc-desc">{{ skill.description || '（这个技能还没写描述）' }}</p>

      <div class="sc-tags">
        <span v-for="t in (skill.tags || []).slice(0, 3)" :key="t" class="tag">{{ t }}</span>
        <span v-if="(skill.tags || []).length > 3" class="tag more">+{{ skill.tags.length - 3 }}</span>
      </div>

      <div class="sc-foot">
        <span class="sc-stat" :title="metricNotes.downloads">
          <AppIcon name="download" :size="13" />{{ fmt(skill.downloads) }}
        </span>
        <span class="sc-stat" :title="metricNotes.installs">
          <AppIcon name="terminal" :size="13" />{{ fmt(skill.installs) }}
        </span>

        <!-- 作者 + 上传时间，右侧一组（布局理由见 .sc-meta 的注释） -->
        <span class="sc-meta">
          <span class="sc-author">{{ skill.author }}</span>
          <template v-if="uploaded">
            <span class="sc-dot">·</span>
            <span class="sc-time" :title="`上传于 ${uploadedAbs}`">{{ uploaded }}</span>
          </template>
        </span>
      </div>
    </router-link>

    <!-- 站主专属。绝对定位在卡片右下角 —— 这样它是 <router-link> 的**兄弟**而不是后代 -->
    <button
      v-if="isAdmin"
      class="sc-del no-select"
      type="button"
      :title="adminNotes.deleteButton"
      :aria-label="`删除 ${skill.name}`"
      @click="confirmOpen = true"
    >
      <AppIcon name="trash" :size="13" />
    </button>

    <AppDialog
      :open="confirmOpen"
      danger
      icon="trash"
      :title="adminNotes.deleteTitle"
      @close="confirmOpen = false"
    >
      <p class="dlg-p">确定要删除 <b>{{ skill.name }}</b> 吗？</p>
      <p class="dlg-p">
        <code>{{ skill.slug }}</code> 会立刻从站上消失，别人再打开这个链接会看到「没有找到」。
      </p>
      <p class="dlg-p sc-dlg-note">
        服务端会先存一份快照到回收站（保留 90 天），恢复见仓库的 supabase/README.md。
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
  </div>
</template>

<style scoped>
.skill-card {
  display: flex;
  flex-direction: column;
  padding: 16px;
  /* 删除按钮是绝对定位的，锚点就是这张卡 */
  position: relative;
  transition:
    background-color 0.2s ease,
    border-color 0.2s ease,
    transform 0.25s ease;
}

.skill-card:hover {
  background: var(--item_hover_color);
  border-color: var(--hub_line_strong);
  transform: translateY(-3px);
}

.sc-body {
  display: flex;
  flex-direction: column;
  gap: 11px;
}

.sc-head {
  align-items: center;
  display: flex;
  gap: 9px;
}

.sc-icon {
  align-items: center;
  background: var(--gradient);
  border-radius: 7px;
  display: flex;
  flex-shrink: 0;
  height: 28px;
  justify-content: center;
  width: 28px;
}

.sc-name {
  flex: 1;
  font-size: 15px;
  font-weight: 600;
  line-height: 1.3;
  margin: 0;
  min-width: 0;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.sc-ver {
  color: var(--hub_muted);
  flex-shrink: 0;
  font-size: 12px;
}

/* 描述固定两行高 —— 长短不一的描述会让卡片高度参差，网格看起来是乱的 */
.sc-desc {
  color: var(--hub_muted);
  display: -webkit-box;
  font-size: 13px;
  -webkit-line-clamp: 2;
  line-clamp: 2;
  line-height: 1.55;
  -webkit-box-orient: vertical;
  margin: 0;
  min-height: 40px;
  overflow: hidden;
}

.sc-tags {
  display: flex;
  flex-wrap: wrap;
  gap: 5px;
  min-height: 22px;
}

.sc-tags .more {
  opacity: 0.6;
}

.sc-foot {
  align-items: center;
  border-top: 1px solid var(--hub_line);
  color: var(--hub_muted);
  display: flex;
  font-size: 12px;
  gap: 10px;
  padding-top: 10px;
}

/* 有删除按钮时把这一行整体右移，免得时间戳被按钮压住。
   按钮是绝对定位的，不参与 flex 计算，所以只能这样让位。 */
.skill-card.managing .sc-foot {
  padding-right: 28px;
}

.sc-stat {
  align-items: center;
  display: flex;
  flex-shrink: 0;
  gap: 4px;
}

.sc-stat svg {
  fill: var(--hub_muted);
}

/* 右侧元信息组：作者 + 上传时间。卡片最窄 272px（减 padding 后内容约 240px），
   左侧两个统计约 60px，所以这组可用宽度不到 170px。
   `.sc-time` 是 flex-shrink:0 而 `.sc-author` 会省略号截断 ——
   作者名再长也**不能把时间挤掉**，时间才是这一行里更难从别处获得的信息。 */
.sc-meta {
  align-items: center;
  display: flex;
  gap: 5px;
  margin-left: auto;
  min-width: 0;
}

.sc-author {
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.sc-dot {
  flex-shrink: 0;
  opacity: 0.55;
}

.sc-time {
  flex-shrink: 0;
  white-space: nowrap;
}

/* 站主删除按钮。平时压得很低（opacity .45），hover 卡片才亮起来 ——
   它是一个破坏性操作，不该跟「下载量 / 安装量」抢注意力。 */
.sc-del {
  align-items: center;
  background: transparent;
  border: 1px solid transparent;
  border-radius: 7px;
  bottom: 11px;
  color: var(--hub_muted);
  cursor: pointer;
  display: flex;
  height: 22px;
  justify-content: center;
  opacity: 0.45;
  position: absolute;
  right: 11px;
  transition:
    background-color 0.2s ease,
    border-color 0.2s ease,
    color 0.2s ease,
    opacity 0.2s ease;
  width: 22px;
}

.skill-card:hover .sc-del {
  opacity: 0.85;
}

.sc-del:hover {
  background: #ff6b6b1a;
  border-color: #ff6b6b59;
  color: var(--hub_err);
  opacity: 1;
}

.sc-del svg {
  fill: currentColor;
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

.sc-dlg-note {
  font-size: 12.5px;
  opacity: 0.8;
}
</style>
