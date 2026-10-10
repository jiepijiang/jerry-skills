<script setup>
import AppIcon from './AppIcon.vue'

/**
 * 空状态。
 *
 * ⚠️ 装饰图标必须走**组件自己的 scoped 样式 + 专属 class**，
 *    不能像原来那样在全局 hub.css 里写 `.empty svg { width:40px }` ——
 *    那是个**后代选择器**，会连插槽里的按钮图标一起命中：
 *    「上传技能」按钮的图标被撑成 40px、染成灰色、还带 0.6 透明度，
 *    而别的按钮是 16px 纯白。三处同名按钮看起来就是「不统一」。
 *    当时的元凶是**源码顺序**：`.empty svg` 和 `.btn svg` 特异度相同（都是 0,1,1），
 *    后者写在前面，于是被覆盖。
 *    改成专属 class 之后，插槽里的任何图标都不再可能被这里影响。
 */
defineProps({
  icon: { type: String, default: 'box' },
  text: { type: String, default: '' },
})
</script>

<template>
  <div class="empty">
    <AppIcon :name="icon" :size="40" class="empty-icon" />
    <p>{{ text }}</p>
    <slot />
  </div>
</template>

<style scoped>
/* 只管这颗装饰图标。插槽内容完全不受影响。 */
.empty-icon {
  fill: var(--hub_muted);
  opacity: 0.6;
}
</style>
