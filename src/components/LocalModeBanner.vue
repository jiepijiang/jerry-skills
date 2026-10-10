<script setup>
import AppIcon from './AppIcon.vue'
import { READY } from '@/lib/skills-api'
</script>

<template>
  <!--
    未配置 Supabase 时的显式提示。
    「看着像发出去了、其实只存在本机」是这个站点最容易让人误解的失败模式，
    所以这里不用一句 console.warn 打发，而是在页面上一直挂着。
  -->
  <div v-if="!READY" class="local-banner" role="status">
    <AppIcon name="info" :size="16" />
    <span>
      当前是<b>本地演示模式</b>（未配置 Supabase）：上传的技能只存在这台机器的浏览器里，
      别人看不到，下载量也不会真的累计。
    </span>
  </div>
</template>

<style scoped>
.local-banner {
  align-items: center;
  background: #ffb0201f;
  border: 1px solid #ffb02066;
  border-radius: 9px;
  color: #ffd489;
  display: flex;
  font-size: 13px;
  gap: 8px;
  line-height: 1.5;
  margin-bottom: 18px;
  padding: 10px 13px;
}

.local-banner svg {
  fill: #ffb020;
  flex-shrink: 0;
}

.local-banner b {
  font-weight: 700;
}
</style>
