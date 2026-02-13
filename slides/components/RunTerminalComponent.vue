<template>
  <Teleport to="body">
    <Transition name="modal">
      <div v-show="isOpen" class="modal-overlay" @click.self="close" :style="overlayStyle">
        <div class="modal-container">
          <div class="modal-header">
            <h3>Terminal</h3>
            <div class="modal-actions">
              <span v-if="!isConnected" class="status-badge error">Disconnected</span>

              <button @click="close" class="close-btn" title="Close (Ctrl+Esc)">×</button>
            </div>
          </div>
          <div class="modal-body">
            <div ref="terminalRef" class="terminal-container"></div>
          </div>
          <div class="modal-footer">
            <kbd>Ctrl+C</kbd> to interrupt · <kbd>Ctrl+Shift+C</kbd> to copy · <kbd>Ctrl+Esc</kbd> to close · <kbd>Ctrl+L</kbd> to clear · <kbd>Ctrl+F</kbd> to search · <kbd>Ctrl+±</kbd> to zoom
          </div>
        </div>
      </div>
    </Transition>
  </Teleport>
</template>

<script setup>
import { ref, onMounted, onUnmounted, nextTick } from 'vue'
import { Terminal } from '@xterm/xterm'
import { FitAddon } from '@xterm/addon-fit'
import { WebLinksAddon } from '@xterm/addon-web-links'
import { SearchAddon } from '@xterm/addon-search'
import '@xterm/xterm/css/xterm.css'

const emit = defineEmits(['close'])

const isOpen = ref(false)
const isConnected = ref(false)
const terminalRef = ref(null)
const overlayStyle = ref({})

let terminal = null
let fitAddon = null
let webLinksAddon = null
let searchAddon = null
let ws = null
let pendingScript = null
let lastSearchTerm = ''
let fontSize = 20
const MIN_FONT_SIZE = 10
const MAX_FONT_SIZE = 40
const FONT_SIZE_STORAGE_KEY = 'slidev-terminal-font-size'

const WS_URL = 'ws://127.0.0.1:3031'

function createTerminal() {
  terminal = new Terminal({
    cursorBlink: true,
    fontSize,
    fontFamily: 'Menlo, Monaco, "Courier New", monospace',
    theme: {
      background: '#1e1e1e',
      foreground: '#d4d4d4',
      cursor: '#aeafad',
      black: '#000000',
      red: '#cd3131',
      green: '#0dbc79',
      yellow: '#e5e510',
      blue: '#2472c8',
      magenta: '#bc3fbc',
      cyan: '#11a8cd',
      white: '#e5e5e5',
      brightBlack: '#666666',
      brightRed: '#f14c4c',
      brightGreen: '#23d18b',
      brightYellow: '#f5f543',
      brightBlue: '#3b8eea',
      brightMagenta: '#d670d6',
      brightCyan: '#29b8db',
      brightWhite: '#e5e5e5'
    },
    allowProposedApi: true
  })

  // Add addons
  fitAddon = new FitAddon()
  webLinksAddon = new WebLinksAddon()
  searchAddon = new SearchAddon()

  terminal.loadAddon(fitAddon)
  terminal.loadAddon(webLinksAddon)
  terminal.loadAddon(searchAddon)

  terminal.attachCustomKeyEventHandler((event) => {
    if (!isOpen.value) return true

    if (event.ctrlKey && event.shiftKey && event.key.toLowerCase() === 'c') {
      event.preventDefault()
      copySelectionToClipboard()
      return false
    }

    if ((event.ctrlKey || event.metaKey) && event.key === 'Escape') {
      event.preventDefault()
      close()
      return false
    }

    if ((event.ctrlKey || event.metaKey) && isZoomInKey(event)) {
      event.preventDefault()
      adjustFontSize(1)
      return false
    }

    if ((event.ctrlKey || event.metaKey) && isZoomOutKey(event)) {
      event.preventDefault()
      adjustFontSize(-1)
      return false
    }

    if ((event.ctrlKey || event.metaKey) && isZoomResetKey(event)) {
      event.preventDefault()
      resetFontSize()
      return false
    }

    if ((event.ctrlKey || event.metaKey) && event.key.toLowerCase() === 'l') {
      event.preventDefault()
      terminal.clear()
      terminal.write('\x1b[H')
      return false
    }

    if ((event.ctrlKey || event.metaKey) && event.key.toLowerCase() === 'f') {
      event.preventDefault()
      const term = window.prompt('Search terminal output', lastSearchTerm || '')
      if (!term) return false
      lastSearchTerm = term
      searchAddon?.findNext(term)
      return false
    }

    if (event.key === 'F3') {
      event.preventDefault()
      if (!lastSearchTerm) return false
      if (event.shiftKey) {
        searchAddon?.findPrevious(lastSearchTerm)
      } else {
        searchAddon?.findNext(lastSearchTerm)
      }
      return false
    }

    return true
  })

  terminal.open(terminalRef.value)
  fitAddon.fit()

  // Handle resize
  window.addEventListener('resize', handleResize)

  return terminal
}

function handleResize() {
  updateOverlayBounds()
  if (fitAddon && isOpen.value) {
    fitAddon.fit()
    if (ws && ws.readyState === WebSocket.OPEN) {
      ws.send(JSON.stringify({
        type: 'resize',
        cols: terminal.cols,
        rows: terminal.rows
      }))
    }
  }
}

function applyFontSize() {
  if (!terminal) return
  terminal.options.fontSize = fontSize
  terminal.refresh(0, terminal.rows - 1)
  if (fitAddon && isOpen.value) {
    requestAnimationFrame(() => {
      fitAddon.fit()
    })
  }

  if (typeof window !== 'undefined') {
    try {
      window.localStorage.setItem(FONT_SIZE_STORAGE_KEY, String(fontSize))
    } catch (error) {
      console.warn('[terminal] failed to persist font size', error)
    }
  }
}

async function copySelectionToClipboard() {
  if (!terminal) return
  const selection = terminal.getSelection()
  if (!selection) return

  try {
    if (navigator?.clipboard?.writeText) {
      await navigator.clipboard.writeText(selection)
    } else {
      const textarea = document.createElement('textarea')
      textarea.value = selection
      textarea.style.position = 'fixed'
      textarea.style.opacity = '0'
      document.body.appendChild(textarea)
      textarea.select()
      document.execCommand('copy')
      document.body.removeChild(textarea)
    }
  } catch (error) {
    console.warn('[terminal] copy failed', error)
  }
}

function adjustFontSize(delta) {
  const nextSize = Math.min(MAX_FONT_SIZE, Math.max(MIN_FONT_SIZE, fontSize + delta))
  if (nextSize === fontSize) return
  fontSize = nextSize
  applyFontSize()
}

function resetFontSize() {
  fontSize = 16
  applyFontSize()
}

function isZoomInKey(event) {
  return event.key === '+' || event.key === '=' || event.code === 'NumpadAdd'
}

function isZoomOutKey(event) {
  return event.key === '-' || event.key === '_' || event.code === 'NumpadSubtract'
}

function isZoomResetKey(event) {
  return event.key === '0' || event.code === 'Digit0' || event.code === 'Numpad0'
}

function updateOverlayBounds() {
  if (typeof window === 'undefined') return

  const selectors = [
    '.slidev-layout',
    '.slidev-page',
    '.slidev-container',
    '#slide-container',
    '#app'
  ]

  let target = null
  for (const selector of selectors) {
    const candidate = document.querySelector(selector)
    if (candidate) {
      target = candidate
      break
    }
  }

  if (!target) {
    overlayStyle.value = {}
    return
  }

  const rect = target.getBoundingClientRect()
  if (!rect?.width || !rect?.height) {
    overlayStyle.value = {}
    return
  }

  overlayStyle.value = {
    '--terminal-slide-width': `${rect.width}px`,
    '--terminal-slide-height': `${rect.height}px`
  }
}

function connectWebSocket() {
  ws = new WebSocket(WS_URL)

  ws.onopen = () => {
    console.log('WebSocket connected')
    isConnected.value = true

    // Start terminal session
    ws.send(JSON.stringify({
      type: 'start',
      cols: terminal.cols,
      rows: terminal.rows
    }))
  }

  ws.onmessage = (event) => {
    const message = JSON.parse(event.data)

    if (message.type === 'data') {
      terminal.write(message.data)
    } else if (message.type === 'started') {
      console.log('Terminal session started')
      
      // Auto-execute pending script if any
      if (pendingScript) {
        executeScript(pendingScript)
        pendingScript = null
      }
    } else if (message.type === 'exit') {
      terminal.write(`\r\n\x1b[33mProcess exited with code ${message.exitCode}\x1b[0m\r\n`)
    } else if (message.type === 'error') {
      terminal.write(`\r\n\x1b[31mError: ${message.message}\x1b[0m\r\n`)
    }
  }

  ws.onerror = (error) => {
    console.error('WebSocket error:', error)
    terminal.write('\r\n\x1b[31mConnection error\x1b[0m\r\n')
  }

  ws.onclose = () => {
    console.log('WebSocket closed')
    isConnected.value = false
    terminal.write('\r\n\x1b[33mDisconnected from server\x1b[0m\r\n')
  }

  // Forward terminal input to server
  terminal.onData((data) => {
    if (ws && ws.readyState === WebSocket.OPEN) {
      ws.send(JSON.stringify({
        type: 'data',
        data
      }))
    }
  })
}

function executeScript(scriptPath) {
  if (ws && ws.readyState === WebSocket.OPEN) {
    ws.send(JSON.stringify({
      type: 'execute',
      script: scriptPath
    }))
  } else {
    // Store for later execution when connected
    pendingScript = scriptPath
  }
}

function open(scriptPath = null) {
  console.info('[terminal] open requested', { scriptPath })
  updateOverlayBounds()
  isOpen.value = true
  if (typeof window !== 'undefined') {
    window.__terminalIsOpen = true
  }
  if (scriptPath) {
    pendingScript = scriptPath
  }
  nextTick(() => {
    if (!terminal) {
      console.info('[terminal] creating terminal instance')
      createTerminal()
      console.info('[terminal] connecting websocket')
      connectWebSocket()
      terminal?.focus()
    } else {
      fitAddon.fit()
      terminal?.focus()
      // If already connected and have a script, execute it
      if (scriptPath && ws && ws.readyState === WebSocket.OPEN) {
        console.info('[terminal] executing script immediately', { scriptPath })
        executeScript(scriptPath)
      } else if (scriptPath) {
        console.info('[terminal] queued script until connection', { scriptPath })
      }
    }
  })
}

function close() {
  isOpen.value = false
  if (typeof window !== 'undefined') {
    window.__terminalIsOpen = false
  }
  emit('close')
}

function handleKeydown(event) {
  // Global keyboard shortcuts
  if (event.key === 't' && !event.ctrlKey && !event.metaKey && !event.altKey) {
    // Don't trigger if typing in an input
    if (event.target.tagName === 'INPUT' || event.target.tagName === 'TEXTAREA') {
      return
    }
    event.preventDefault()
    if (isOpen.value) {
      close()
    } else {
      open()
    }
  } else if (isOpen.value && (event.ctrlKey || event.metaKey) && event.key.toLowerCase() === 'l') {
    event.preventDefault()
    if (terminal) {
      terminal.clear()
      terminal.write('\x1b[H')
    }
  } else if (isOpen.value && event.ctrlKey && event.shiftKey && event.key.toLowerCase() === 'c') {
    event.preventDefault()
    copySelectionToClipboard()
  } else if (isOpen.value && (event.ctrlKey || event.metaKey) && isZoomInKey(event)) {
    event.preventDefault()
    adjustFontSize(1)
  } else if (isOpen.value && (event.ctrlKey || event.metaKey) && isZoomOutKey(event)) {
    event.preventDefault()
    adjustFontSize(-1)
  } else if (isOpen.value && (event.ctrlKey || event.metaKey) && isZoomResetKey(event)) {
    event.preventDefault()
    resetFontSize()
  } else if (isOpen.value && (event.ctrlKey || event.metaKey) && event.key === 'Escape') {
    event.preventDefault()
    close()
  } else if (isOpen.value && (event.ctrlKey || event.metaKey) && event.key.toLowerCase() === 'f') {
    event.preventDefault()
    if (!searchAddon) return
    const term = window.prompt('Search terminal output', lastSearchTerm || '')
    if (!term) return
    lastSearchTerm = term
    searchAddon.findNext(term)
  } else if (isOpen.value && event.key === 'F3') {
    event.preventDefault()
    if (!searchAddon || !lastSearchTerm) return
    if (event.shiftKey) {
      searchAddon.findPrevious(lastSearchTerm)
    } else {
      searchAddon.findNext(lastSearchTerm)
    }
  } else if (event.key === 'Escape' && isOpen.value) {
    event.preventDefault()
    close()
  }
}

function handleRunEvent(event) {
  const detail = event?.detail || {}
  console.info('[terminal] run event received', detail)
  if (detail.scriptPath) {
    open(detail.scriptPath)
  } else {
    open()
  }
}

onMounted(() => {
  if (typeof window !== 'undefined') {
    const storedFontSize = window.localStorage.getItem(FONT_SIZE_STORAGE_KEY)
    if (storedFontSize) {
      const parsed = Number.parseInt(storedFontSize, 10)
      if (!Number.isNaN(parsed)) {
        fontSize = Math.min(MAX_FONT_SIZE, Math.max(MIN_FONT_SIZE, parsed))
      }
    }
  }
  nextTick(() => {
    updateOverlayBounds()
  })
  window.__terminalIsOpen = false
  window.addEventListener('keydown', handleKeydown)
  window.addEventListener('terminal:run', handleRunEvent)
  window.openTerminal = (scriptPath = null) => {
    console.info('[terminal] window.openTerminal invoked', { scriptPath })
    open(scriptPath)
  }
})

onUnmounted(() => {
  window.removeEventListener('keydown', handleKeydown)
  window.removeEventListener('terminal:run', handleRunEvent)
  if (window.openTerminal) {
    delete window.openTerminal
  }
  window.removeEventListener('resize', handleResize)
  
  if (ws) {
    ws.close()
  }
  
  if (terminal) {
    terminal.dispose()
  }
})

// Expose methods for parent components
defineExpose({
  open,
  close,
  executeScript
})
</script>

<style scoped>
.modal-overlay {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: rgba(0, 0, 0, 0.8);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 9999;
  padding: 20px;
  user-select: text;
}

.modal-container {
  background: #1e1e1e;
  border-radius: 8px;
  width: 100%;
  height: 100%;
  display: flex;
  flex-direction: column;
  box-shadow: 0 20px 60px rgba(0, 0, 0, 0.5);
  user-select: text;
}

.modal-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 16px 20px;
  border-bottom: 1px solid #333;
}

.modal-header h3 {
  margin: 0;
  color: #fff;
  font-size: 18px;
  font-weight: 600;
}

.modal-actions {
  display: flex;
  align-items: center;
  gap: 12px;
}

.status-badge {
  font-size: 12px;
  padding: 4px 8px;
  border-radius: 4px;
  font-weight: 500;
}

.status-badge.success {
  background: #0dbc79;
  color: #fff;
}

.status-badge.error {
  background: #cd3131;
  color: #fff;
}

.close-btn {
  background: transparent;
  border: none;
  color: #999;
  font-size: 28px;
  line-height: 1;
  cursor: pointer;
  padding: 0;
  width: 32px;
  height: 32px;
  display: flex;
  align-items: center;
  justify-content: center;
  border-radius: 4px;
  transition: all 0.2s;
}

.close-btn:hover {
  background: #333;
  color: #fff;
}

.modal-body {
  flex: 1;
  overflow: hidden;
  padding: 12px;
}

.terminal-container {
  width: 100%;
  height: 100%;
  border-radius: 4px;
  overflow: hidden;
}

.terminal-container,
.terminal-container .xterm,
.terminal-container .xterm-screen,
.terminal-container .xterm-viewport {
  user-select: text !important;
}

.modal-footer {
  padding: 12px 20px;
  border-top: 1px solid #333;
  font-size: 12px;
  color: #999;
  text-align: center;
}

.modal-footer kbd {
  background: #333;
  padding: 2px 6px;
  border-radius: 3px;
  font-family: monospace;
  font-size: 11px;
  color: #fff;
}

/* Transition animations */
.modal-enter-active,
.modal-leave-active {
  transition: opacity 0.2s;
}

.modal-enter-from,
.modal-leave-to {
  opacity: 0;
}

.modal-enter-active .modal-container,
.modal-leave-active .modal-container {
  transition: transform 0.2s;
}

.modal-enter-from .modal-container,
.modal-leave-to .modal-container {
  transform: scale(0.95);
}
</style>
