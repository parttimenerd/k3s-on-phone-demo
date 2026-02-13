# Terminal Integration Setup

## Installation

### 1. Install Slidev (if not already installed)

```bash
cd slides
npm init -y
npm install -D @slidev/cli @slidev/theme-default
npm install -D vite
```

### 2. Install Terminal Dependencies

```bash
npm install xterm @xterm/addon-fit @xterm/addon-web-links @xterm/addon-search
```

### 3. Setup Terminal Server

```bash
cd terminal-server
npm install
```

## Running

### Start Terminal Server (Terminal 1)

```bash
cd slides/terminal-server
./start.sh
```

This starts the WebSocket server on `http://127.0.0.1:3031`

### Start Slides (Terminal 2)

```bash
cd slides
npm run dev
```

This starts Slidev on `http://localhost:3030`

## Usage

### In Slides

1. **Press 't'** anywhere in the presentation to open the terminal
2. **Click the "Run" button** on any `<CodeWithScript>` component when the server is running
3. **Press 'Esc'** to close the terminal

### Integration in Slides

Add this to your slide layout or setup file:

```vue
<script setup>
import { provide, ref } from 'vue'
import RunTerminalComponent from './components/RunTerminalComponent.vue'

const terminalRef = ref(null)

function openTerminal(scriptPath) {
  if (terminalRef.value) {
    terminalRef.value.open()
    if (scriptPath) {
      // Wait a bit for terminal to connect
      setTimeout(() => {
        terminalRef.value.executeScript(scriptPath)
      }, 500)
    }
  }
}

provide('openTerminal', openTerminal)
</script>

<template>
  <!-- Your slides content -->
  <RunTerminalComponent ref="terminalRef" />
</template>
```

## Features

✅ Full terminal emulation with xterm.js  
✅ Execute demo scripts with one click  
✅ Keyboard shortcut ('t') to toggle terminal  
✅ Security: localhost-only connections  
✅ Whitelisted script directories  
✅ Auto-resize terminal  
✅ Clickable web links  
✅ Copy/paste support  

## Security

- Server only accepts connections from `127.0.0.1`
- CORS restricted to `http://localhost:3030`
- Script execution limited to whitelisted directories:
  - `echo-demo/scripts/`
  - `chat-demo/scripts/`
  - `demo/scripts/`

## Troubleshooting

**Terminal won't connect:**
- Ensure terminal server is running (`./terminal-server/start.sh`)
- Check http://127.0.0.1:3031/health returns `{"status":"ok"}`

**Run button doesn't appear:**
- Server must be running before loading slides
- Check browser console for fetch errors

**Scripts won't execute:**
- Ensure script path is absolute
- Verify script is in a whitelisted directory
- Check terminal server logs for errors
