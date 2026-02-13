<template>
  <div class="code-with-script">
    <div class="code-block">
      <slot></slot>
    </div>
    <div class="script-pill">
      <span class="script-icon" aria-hidden="true">
        <svg viewBox="0 0 12 12" width="10" height="10" role="presentation">
          <path d="M3 2.2v7.6L9.2 6 3 2.2z" fill="currentColor" />
        </svg>
      </span>
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

let terminalAvailabilityPromise: Promise<boolean> | null = null
let terminalAvailabilityResult: boolean | null = null

function getAvailabilityCache() {
  if (typeof window === 'undefined') {
    return null
  }

  const win = window as Window & {
    __terminalAvailabilityResult?: boolean | null
    __terminalAvailabilityPromise?: Promise<boolean> | null
  }

  if (typeof win.__terminalAvailabilityResult !== 'undefined') {
    terminalAvailabilityResult = win.__terminalAvailabilityResult ?? null
  }

  if (typeof win.__terminalAvailabilityPromise !== 'undefined') {
    terminalAvailabilityPromise = win.__terminalAvailabilityPromise ?? null
  }

  return win
}

const props = defineProps<{
  scriptPath: string
}>()

const isTerminalAvailable = ref(false)

const showRunButton = computed(() => isTerminalAvailable.value)

async function checkTerminalAvailability() {
  const cacheWindow = getAvailabilityCache()

  if (terminalAvailabilityResult !== null) {
    isTerminalAvailable.value = terminalAvailabilityResult
    return
  }

  if (terminalAvailabilityPromise) {
    isTerminalAvailable.value = await terminalAvailabilityPromise
    return
  }

  if (typeof window === 'undefined') {
    isTerminalAvailable.value = false
    return
  }

  terminalAvailabilityPromise = (async () => {
    const controller = new AbortController()
    const timeout = window.setTimeout(() => controller.abort(), 500)

    try {
      const response = await fetch('http://127.0.0.1:3031/health', {
        method: 'GET',
        signal: controller.signal
      })
      terminalAvailabilityResult = response.ok
      if (cacheWindow) {
        cacheWindow.__terminalAvailabilityResult = terminalAvailabilityResult
      }
      return response.ok
    } catch (error) {
      terminalAvailabilityResult = false
      if (cacheWindow) {
        cacheWindow.__terminalAvailabilityResult = terminalAvailabilityResult
      }
      return false
    } finally {
      window.clearTimeout(timeout)
    }
  })()

  if (cacheWindow) {
    cacheWindow.__terminalAvailabilityPromise = terminalAvailabilityPromise
  }

  isTerminalAvailable.value = await terminalAvailabilityPromise
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
  display: inline-flex;
  align-items: center;
  opacity: 0.8;
}

.script-icon svg {
  display: block;
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
