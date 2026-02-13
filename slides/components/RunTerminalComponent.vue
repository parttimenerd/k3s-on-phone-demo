<template>
  <Transition name="modal">
    <div v-if="isOpen" class="modal-overlay" @click.self="close">
      <div class="modal-container">
        <div class="modal-header">
          <h3>Terminal</h3>
          <div class="modal-actions">
            <span v-if="!isConnected" class="status-badge error">Disconnected</span>
            <span v-else class="status-badge success">Connected</span>
            <button @click="close" class="close-btn" title="Close (Esc)">×</button>
          </div>
        </div>
        <div class="modal-body">
          <div ref="terminalRef" class="terminal-container"></div>
        </div>
        <div class="modal-footer">
          <kbd>Ctrl+C</kbd> to interrupt · <kbd>Esc</kbd> to close · <kbd>Ctrl+L</kbd> to clear
        </div>
      </div>
    </div>
  </Transition>
</template>

<script setup>
import { ref, onMounted, onUnmounted, watch, nextTick } from 'vue'
import { Terminal } from '@xterm/xterm'
import { FitAddon } from '@xterm/addon-fit'
import { WebLinksAddon } from '@xterm/addon-web-links'
import { SearchAddon } from '@xterm/addon-search'
import '@xterm/xterm/css/xterm.css'

const emit = defineEmits(['close'])

const isOpen = ref(false)
const isConnected = ref(false)
const terminalRef = ref(null)

let terminal = null
let fitAddon = null
let webLinksAddon = null
let searchAddon = null
let ws = null
let pendingScript = null

const WS_URL = 'ws://127.0.0.1:3031'

function createTerminal() {
  terminal = new Terminal({
    cursorBlink: true,
    fontSize: 14,
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

  terminal.open(terminalRef.value)
  fitAddon.fit()

  // Handle resize
  window.addEventListener('resize', handleResize)

  return terminal
}

function handleResize() {
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
  isOpen.value = true
  if (scriptPath) {
    pendingScript = scriptPath
  }
  nextTick(() => {
    if (!terminal) {
      console.info('[terminal] creating terminal instance')
      createTerminal()
      console.info('[terminal] connecting websocket')
      connectWebSocket()
    } else {
      fitAddon.fit()
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
}

.modal-container {
  background: #1e1e1e;
  border-radius: 8px;
  width: 90vw;
  max-width: 1200px;
  height: 80vh;
  display: flex;
  flex-direction: column;
  box-shadow: 0 20px 60px rgba(0, 0, 0, 0.5);
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
