<script setup>
import AppIcon from './AppIcon.vue'
import { toastState } from '@/composables/useToast'
</script>

<template>
  <div
    class="hub-toast"
    :class="[toastState.type, { active: toastState.active }]"
    role="status"
    aria-live="polite"
  >
    <AppIcon :name="toastState.type === 'error' ? 'warn' : 'check'" :size="18" />
    <span class="hub-toast-text">{{ toastState.text }}</span>
  </div>
</template>
