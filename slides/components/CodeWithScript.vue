<template>
  <div class="code-with-script">
    <div class="code-block">
      <slot></slot>
    </div>
    <div class="script-pill">
      <button
        class="script-icon-button"
        type="button"
        :disabled="!canRun"
        :title="canRun ? 'Run script in terminal' : 'Terminal not available'"
        @click="handleRunClick"
      >
        <span class="script-icon" aria-hidden="true">
          <slot v-if="!canRun" name="run-icon-disabled">
            <svg viewBox="0 0 12 12" width="10" height="10" role="presentation">
              <path d="M3 2.2v7.6L9.2 6 3 2.2z" fill="currentColor" />
            </svg>
          </slot>
          <slot v-else name="run-icon">
            <svg viewBox="0 0 12 12" width="10" height="10" role="presentation">
              <path d="M3 2.2v7.6L9.2 6 3 2.2z" fill="currentColor" />
            </svg>
          </slot>
        </span>
      </button>
      <code>{{ scriptPath }}</code>
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed, onMounted, onUnmounted, ref } from 'vue'

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

const canRun = computed(() => isTerminalAvailable.value)

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
  if (!canRun.value) {
    return
  }
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

function handleGlobalRunShortcut(event: KeyboardEvent) {
  if (event.key !== 'r' || event.ctrlKey || event.metaKey || event.altKey) {
    return
  }
  if (event.target && ['INPUT', 'TEXTAREA'].includes((event.target as HTMLElement).tagName)) {
    return
  }
  if (!isTerminalAvailable.value) {
    return
  }
  const isOpen = (window as Window & { __terminalIsOpen?: boolean }).__terminalIsOpen
  if (isOpen) {
    return
  }

  event.preventDefault()
  handleRunClick()
}

onMounted(() => {
  checkTerminalAvailability()
  window.addEventListener('keydown', handleGlobalRunShortcut)
})

onUnmounted(() => {
  window.removeEventListener('keydown', handleGlobalRunShortcut)
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

.script-icon-button {
  border: none;
  background: rgba(255, 255, 255, 0.18);
  color: white;
  width: 18px;
  height: 18px;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  border-radius: 999px;
  cursor: pointer;
  transition: background 0.2s ease, transform 0.2s ease;
  padding: 0;
}

.script-icon-button:hover {
  background: rgba(255, 255, 255, 0.32);
  transform: scale(1.05);
}

.script-icon-button:disabled {
  background: rgba(255, 255, 255, 0.12);
  color: rgba(255, 255, 255, 0.5);
  cursor: not-allowed;
  transform: none;
}
</style>
