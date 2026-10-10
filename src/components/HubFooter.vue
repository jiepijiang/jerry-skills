<script setup>
import { footer } from '@/data/site'
</script>

<template>
  <footer class="hub-footer">
    <div class="hub-footer-inner">
      <span>{{ footer.text }}</span>
      <span class="sep">·</span>
      <a :href="footer.repo" target="_blank" rel="noopener noreferrer">GitHub</a>
      <span class="sep">·</span>
      <template v-for="(s, i) in footer.siblings" :key="s.href">
        <a :href="s.href" target="_blank" rel="noopener noreferrer">{{ s.label }}</a>
        <span v-if="i < footer.siblings.length - 1" class="sep">·</span>
      </template>
    </div>
  </footer>
</template>

<style scoped>
.hub-footer {
  border-top: 1px solid var(--hub_line);
  color: var(--footer_text_color);
  margin-top: 40px;
  padding: 18px 20px 26px;
}

.hub-footer-inner {
  align-items: center;
  display: flex;
  flex-wrap: wrap;
  font-size: 13px;
  gap: 6px;
  justify-content: center;
  margin: 0 auto;
  max-width: 1150px;
  opacity: 0.75;
}

.hub-footer a:hover {
  color: var(--hub_accent);
  opacity: 1;
}

.sep {
  opacity: 0.5;
}
</style>
