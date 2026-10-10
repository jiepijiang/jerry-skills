<script setup>
import AppIcon from './AppIcon.vue'
import { categoryIcon, categoryLabel } from '@/data/site'

/**
 * 技能卡片。
 * 视觉沿用主站 ProjectCard 的玻璃卡语言（--item_bg_color + 圆角 + hover 上浮），
 * 但改成纵向布局 —— 技能的信息密度比项目卡片高（描述 / 标签 / 三个统计）。
 */
defineProps({
  skill: { type: Object, required: true },
})

function fmt(n) {
  const v = Number(n) || 0
  if (v < 1000) return String(v)
  return `${(v / 1000).toFixed(v < 10000 ? 1 : 0)}k`
}
</script>

<template>
  <router-link class="skill-card card" :to="`/skills/${skill.slug}`">
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
      <span class="sc-stat" title="下载量">
        <AppIcon name="download" :size="13" />{{ fmt(skill.downloads) }}
      </span>
      <span class="sc-stat" title="安装量">
        <AppIcon name="terminal" :size="13" />{{ fmt(skill.installs) }}
      </span>
      <span class="sc-author">{{ skill.author }}</span>
    </div>
  </router-link>
</template>

<style scoped>
.skill-card {
  display: flex;
  flex-direction: column;
  gap: 11px;
  padding: 16px;
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
  gap: 12px;
  padding-top: 10px;
}

.sc-stat {
  align-items: center;
  display: flex;
  gap: 4px;
}

.sc-stat svg {
  fill: var(--hub_muted);
}

.sc-author {
  margin-left: auto;
  max-width: 40%;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}
</style>
