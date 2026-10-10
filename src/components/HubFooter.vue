<script setup>
import { ref } from 'vue'
import AppIcon from './AppIcon.vue'
import AppDialog from './AppDialog.vue'
import { adminNotes, footer } from '@/data/site'
import { READY } from '@/lib/skills-api'
import { adminToken, clearAdminToken, isAdmin } from '@/lib/admin'
import { useAdminUnlock } from '@/composables/useAdmin'
import { toast } from '@/composables/useToast'

/**
 * 页脚。
 *
 * 站主管理的入口就藏在这里（一个小字按钮）—— 删除权只属于一个人，
 * 没必要让每个访客都看见「这里能删东西」并去试口令。
 * 弹窗挂在这个组件里而不是 App.vue：页脚每页都在，等于弹窗随处可用，
 * 又不用往 App 里塞全局状态。
 */
const open = ref(false)
const pass = ref('')
const { busy, error, submit, reset } = useAdminUnlock()

function openDialog() {
  pass.value = ''
  reset()
  open.value = true
}

async function onUnlock() {
  if (busy.value || !pass.value) return
  if (await submit(pass.value)) {
    open.value = false
    pass.value = ''
    toast(adminNotes.unlocked)
  }
}

function onLogout() {
  clearAdminToken()
  open.value = false
  pass.value = ''
  toast('已退出管理')
}
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
      <span class="sep">·</span>
      <button class="admin-entry no-select" :class="{ on: isAdmin }" type="button" @click="openDialog">
        <AppIcon :name="isAdmin ? 'shield' : 'lock'" :size="12" />
        {{ isAdmin ? adminNotes.entryActive : adminNotes.entry }}
      </button>
    </div>

    <AppDialog
      :open="open"
      icon="lock"
      :title="adminNotes.title"
      @close="open = false"
    >
      <template v-if="isAdmin">
        <p class="dlg-p">{{ adminNotes.unlocked }}</p>
      </template>
      <template v-else>
        <p class="dlg-p">{{ adminNotes.desc }}</p>
        <p v-if="!READY" class="dlg-warn">{{ adminNotes.localHint }}</p>

        <input
          v-model="pass"
          class="input dlg-input"
          type="password"
          autocomplete="current-password"
          :placeholder="adminNotes.placeholder"
          data-autofocus
          @keyup.enter="onUnlock"
        />
        <p v-if="error" class="dlg-err">{{ error }}</p>
        <p class="dlg-hint">{{ adminNotes.storageHint }}</p>
      </template>

      <template #actions>
        <template v-if="isAdmin">
          <button class="btn sm" type="button" @click="open = false">关闭</button>
          <button class="btn sm danger" type="button" @click="onLogout">
            <AppIcon name="lock" :size="14" />{{ adminNotes.logout }}
          </button>
        </template>
        <template v-else>
          <button class="btn sm" type="button" @click="open = false">{{ adminNotes.cancel }}</button>
          <button
            class="btn sm primary"
            :class="{ loading: busy }"
            type="button"
            :disabled="busy || !pass"
            @click="onUnlock"
          >
            {{ adminNotes.submit }}
          </button>
        </template>
      </template>
    </AppDialog>
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

/* 管理入口：故意做成最弱的一档 —— 它是站主自己用的，
   不该跟「GitHub / 姊妹站」这些给访客看的链接抢注意力 */
.admin-entry {
  align-items: center;
  background: transparent;
  border: 0;
  border-radius: 6px;
  color: inherit;
  cursor: pointer;
  display: inline-flex;
  font-family: inherit;
  font-size: 13px;
  gap: 4px;
  opacity: 0.6;
  padding: 2px 6px;
  transition:
    background-color 0.2s ease,
    color 0.2s ease,
    opacity 0.2s ease;
}

.admin-entry:hover {
  background: var(--item_hover_color);
  color: var(--hub_accent);
  opacity: 1;
}

.admin-entry.on {
  color: var(--hub_ok);
  opacity: 0.9;
}

.admin-entry svg {
  fill: currentColor;
}

/* ---------------------------------------------------------- 弹窗里的内容 */
.dlg-p {
  margin: 0;
}

.dlg-input {
  font-family: inherit;
  margin-top: 14px;
  width: 100%;
}

.dlg-warn,
.dlg-err,
.dlg-hint {
  font-size: 12.5px;
  line-height: 1.6;
  margin: 9px 0 0;
}

.dlg-warn {
  background: #ffb0201f;
  border-radius: 7px;
  color: var(--hub_warn);
  padding: 8px 10px;
}

.dlg-err {
  color: var(--hub_err);
}

.dlg-hint {
  color: var(--hub_muted);
  opacity: 0.8;
}
</style>
