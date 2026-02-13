<template>
  <div class="code-with-script">
    <div class="code-block">
      <slot></slot>
    </div>
    <div class="script-pill">
      <span class="script-icon">▶</span>
      <code>{{ scriptPath }}</code>
      <button
        v-if="showRunButton"
        class="run-button"
        type="button"
        title="Run script in terminal"
        @click="handleRunClick"
      >
        Run
      </button>
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'

const props = defineProps<{
  scriptPath: string
}>()

const isTerminalAvailable = ref(false)

const showRunButton = computed(() => isTerminalAvailable.value)

async function checkTerminalAvailability() {
  if (typeof window === 'undefined') {
    isTerminalAvailable.value = false
    return
  }

  const controller = new AbortController()
  const timeout = window.setTimeout(() => controller.abort(), 500)

  try {
    const response = await fetch('http://127.0.0.1:3031/health', {
      method: 'GET',
      signal: controller.signal
    })
    isTerminalAvailable.value = response.ok
  } catch (error) {
    isTerminalAvailable.value = false
  } finally {
    window.clearTimeout(timeout)
  }
}

function handleRunClick() {
  console.info('[code-with-script] run clicked', { scriptPath: props.scriptPath })
  const openTerminal = (window as Window & { openTerminal?: (scriptPath: string) => void })
    .openTerminal

  if (typeof openTerminal === 'function') {
    console.info('[code-with-script] using window.openTerminal')
    openTerminal(props.scriptPath)
    return
  }

  console.warn('[code-with-script] window.openTerminal missing; dispatching terminal:run event')
  window.dispatchEvent(
    new CustomEvent('terminal:run', {
      detail: { scriptPath: props.scriptPath }
    })
  )
}

onMounted(() => {
  checkTerminalAvailability()
})
</script>

<style scoped>
.code-with-script {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.code-block {
  width: 100%;
}

.script-pill {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  background: linear-gradient(135deg, #f97316 40%, #ea580c 100%);
  color: white;
  padding: 4px 12px;
  border-radius: 16px;
  font-size: 11px;
  font-weight: 500;
  width: fit-content;
  box-shadow: 0 1px 4px rgba(249, 115, 22, 0.2);
  opacity: 0.85;
}

.script-icon {
  font-size: 10px;
  opacity: 0.8;
}

.script-pill code {
  background: rgba(0, 0, 0, 0.15);
  padding: 1px 6px;
  border-radius: 3px;
  font-family: 'Courier New', monospace;
  font-size: 10px;
}

.run-button {
  margin-left: 6px;
  border: none;
  background: rgba(255, 255, 255, 0.15);
  color: white;
  font-size: 10px;
  font-weight: 600;
  padding: 2px 8px;
  border-radius: 10px;
  cursor: pointer;
  transition: background 0.2s ease;
}

.run-button:hover {
  background: rgba(255, 255, 255, 0.28);
}
</style>
