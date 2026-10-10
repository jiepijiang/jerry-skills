<script setup>
import AppIcon from './AppIcon.vue'
import { formatBytes } from '@/lib/parseSkill'

/**
 * 文件结构树。
 * 自引用递归 —— 技能包通常只有两三层，不需要虚拟滚动或折叠。
 * `depth` 只用于缩进；`node` 是 buildTree() 的产物。
 */
defineProps({
  node: { type: Object, required: true },
  depth: { type: Number, default: 0 },
})
</script>

<template>
  <ul class="ft-list" :class="{ root: depth === 0 }">
    <li v-for="child in node.children" :key="child.path" class="ft-item">
      <div class="ft-row" :style="{ paddingLeft: `${depth * 15 + 8}px` }">
        <AppIcon
          :name="child.type === 'dir' ? 'folder' : 'file'"
          :size="14"
          :class="child.type === 'dir' ? 'ft-dir' : 'ft-file'"
        />
        <span class="ft-name">{{ child.name }}</span>
        <span v-if="child.type === 'file'" class="ft-size">{{ formatBytes(child.size) }}</span>
      </div>

      <FileTree v-if="child.type === 'dir' && child.children.length" :node="child" :depth="depth + 1" />
    </li>
  </ul>
</template>

<style scoped>
.ft-list {
  list-style: none;
  margin: 0;
  padding: 0;
}

.ft-row {
  align-items: center;
  border-radius: 6px;
  display: flex;
  font-size: 13px;
  gap: 7px;
  padding-bottom: 4px;
  padding-right: 8px;
  padding-top: 4px;
}

.ft-row:hover {
  background: var(--item_bg_color);
}

.ft-row svg {
  flex-shrink: 0;
}

.ft-dir {
  fill: #ffcf6b;
}

.ft-file {
  fill: var(--hub_muted);
}

.ft-name {
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.ft-size {
  color: var(--hub_muted);
  flex-shrink: 0;
  font-size: 12px;
  margin-left: auto;
  padding-left: 10px;
}
</style>
