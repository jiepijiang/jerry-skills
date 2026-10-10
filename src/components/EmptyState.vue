<script setup>
import AppIcon from './AppIcon.vue'

defineProps({
  icon: { type: String, default: 'box' },
  text: { type: String, default: '' },
})
</script>

<template>
  <div class="empty">
    <AppIcon :name="icon" :size="40" />
    <p>{{ text }}</p>
    <slot />
  </div>
</template>
