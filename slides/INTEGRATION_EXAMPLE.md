# Terminal Integration Example

Add this to your Slidev setup or main layout.

## Option 1: Add to `slides.md` frontmatter setup

Add this after the frontmatter in `slides.md`:

```vue
<script setup>
import { provide, ref } from 'vue'
import RunTerminalComponent from './components/RunTerminalComponent.vue'

const terminalRef = ref(null)

function openTerminal(scriptPath = null) {
  if (terminalRef.value) {
    terminalRef.value.open()
    if (scriptPath) {
      // Wait for terminal to connect before executing
      setTimeout(() => {
        terminalRef.value.executeScript(scriptPath)
      }, 500)
    }
  }
}

// Provide to all child components
provide('openTerminal', openTerminal)
</script>

<!-- Add terminal component (will be invisible until opened) -->
<RunTerminalComponent ref="terminalRef" />

<!-- Your slides start here -->
```

## Option 2: Create custom layout

Create `slides/layouts/terminal.vue`:

```vue
<template>
  <div class="slidev-layout terminal-enabled">
    <slot />
    <RunTerminalComponent ref="terminalRef" />
  </div>
</template>

<script setup>
import { provide, ref } from 'vue'
import RunTerminalComponent from '../components/RunTerminalComponent.vue'

const terminalRef = ref(null)

function openTerminal(scriptPath = null) {
  if (terminalRef.value) {
    terminalRef.value.open()
    if (scriptPath) {
      setTimeout(() => {
        terminalRef.value.executeScript(scriptPath)
      }, 500)
    }
  }
}

provide('openTerminal', openTerminal)
</script>
```

Then in your slides:

```md
---
layout: terminal
---

# Your Slide

Content here...
```

## Using with CodeWithScript

The CodeWithScript component will automatically show a "Run" button when the terminal server is running:

```vue
<CodeWithScript scriptPath="./echo-demo/scripts/01-install-k3s.sh">
\`\`\`bash
curl -sfL https://get.k3s.io | sh -
\`\`\`
</CodeWithScript>
```

## Keyboard Shortcuts

- **Press 't'**: Toggle terminal (open/close)
- **Press 'Esc'**: Close terminal
- **Ctrl+C**: Interrupt running process in terminal
- **Ctrl+L**: Clear terminal

## Full Example Slide

\`\`\`markdown
---
layout: terminal
---

<PhoneTwoColumnZoom img="./img/install.png">

# Install k3s

<CodeWithScript scriptPath="./echo-demo/scripts/01-install-k3s.sh">
\`\`\`bash
curl -sfL https://get.k3s.io | sh -
\`\`\`
</CodeWithScript>

Click the Run button or press 't' to execute!

</PhoneTwoColumnZoom>
\`\`\`

The terminal will open in a modal overlay, execute the script, and show real-time output.
