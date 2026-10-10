<script setup>
import { computed } from 'vue'
import { useRoute } from 'vue-router'
import AppIcon from './AppIcon.vue'
import { brand, footer } from '@/data/site'
import { useSearch } from '@/composables/useSearch'

const route = useRoute()
const { query, hasQuery, clear } = useSearch()

/* 搜索框只在首页出现 —— 详情页/上传页的顶栏留白给面包屑用 */
const showSearch = computed(() => route.name === 'home')
</script>

<template>
  <nav class="hub-nav">
    <div class="hub-nav-inner">
      <router-link to="/" class="hub-brand no-select" aria-label="回到首页">
        <span class="hub-brand-logo"><AppIcon name="bolt" :size="18" fill="#fff" /></span>
        <span class="hub-brand-name">{{ brand.name }}</span>
      </router-link>

      <div v-if="showSearch" class="hub-search">
        <AppIcon name="search" :size="16" />
        <input
          v-model="query"
          type="search"
          placeholder="搜索技能名、描述、标签、作者…"
          aria-label="搜索技能"
        />
        <button v-if="hasQuery" class="hub-search-clear" aria-label="清空搜索" @click="clear">×</button>
      </div>

      <div class="hub-nav-spacer" />

      <a
        class="btn nav-icon-btn"
        :href="footer.repo"
        target="_blank"
        rel="noopener noreferrer"
        aria-label="GitHub 仓库"
      >
        <AppIcon name="github" :size="16" />
      </a>

      <router-link to="/upload" class="btn primary">
        <AppIcon name="upload" :size="16" fill="#fff" />
        上传技能
      </router-link>
    </div>
  </nav>
</template>

<style scoped>
/*
 * 图标按钮：做成 38×38 的正方形。
 *
 * ⚠️ 这里**不能**用 `.btn.sm`（32px）。顶栏的搜索框是 38px，
 *    如果按钮是 32px，同一排控件就会参差不齐；而 Hero / 空状态里的
 *    「上传技能」都是默认的 38px —— 同一个按钮在三个地方两个尺寸，
 *    看起来就是「UI 不统一」。现在顶栏整排（搜索框 / 图标按钮 / 上传技能）
 *    统一 38px。
 *
 * 窄屏只留图标。
 */
.nav-icon-btn {
  padding: 0;
  width: 38px;
}

@media (max-width: 520px) {
  .nav-icon-btn {
    display: none;
  }
}
</style>
