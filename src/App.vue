<script setup>
import TopBar from '@/components/TopBar.vue'
import HubToast from '@/components/HubToast.vue'
import HubFooter from '@/components/HubFooter.vue'
</script>

<template>
  <div class="hub-veil" />
  <TopBar />
  <main class="hub-main">
    <router-view v-slot="{ Component }">
      <component :is="Component" />
    </router-view>
  </main>
  <HubFooter />
  <HubToast />
</template>

<style scoped>
.hub-main {
  animation: fadeIn 0.4s ease-out forwards;
  min-height: calc(100vh - 62px);
  padding-top: 26px;
}
</style>
