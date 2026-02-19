# Slide Components

## Interactive Terminal

### CodeWithScript

Wraps code blocks with a "Run" button that executes scripts in the terminal.

```md
<CodeWithScript scriptPath="./echo-demo/scripts/01-install-k3s.sh">
\```bash
curl -sfL https://get.k3s.io | K3S_TOKEN=abc sh -
\```
</CodeWithScript>
```

**With specific terminal host** (for multi-host setups):

```md
<CodeWithScript 
  scriptPath="./echo-demo/scripts/01-install-k3s.sh"
  terminalHost="phone-a">
\```bash
curl -sfL https://get.k3s.io | K3S_TOKEN=abc sh -
\```
</CodeWithScript>
```

### Multi-Host Terminal Setup

Launch presentation with multiple terminal servers:

```bash
# On phone-a (terminal server)
cd terminal-server && ./launch-terminal.sh

# On phone-b (terminal server)  
cd terminal-server && ./launch-terminal.sh

# On laptop (presentation)
./launch.sh --terminal-host phone-a,phone-b
```

**Features:**
- Terminal shows a host selector dropdown (when 2+ hosts available) in the header
- Switch between servers instantly without losing your session
- Each host maintains its own persistent WebSocket connection
- Connections stay open in the background when switching hosts
- The first host is used as the default for `CodeWithScript` components
- Override default with the `terminalHost` prop on individual code blocks
- Selected host is saved to localStorage and restored on reload

## Text helpers

- **OrangeText**
  ```md
  <OrangeText>important</OrangeText>
  ```

- **BlueText**
  ```md
  <BlueText>note</BlueText>
  ```

- **RedText**
  ```md
  <RedText>warning</RedText>
  ```

## Callouts

```md
<Callout variant="orange">Short highlight</Callout>
<Callout variant="blue">Info callout</Callout>
<Callout variant="red">Warning callout</Callout>
<Callout variant="green">Success callout</Callout>
```

## Captions

```md
<Caption>Source: mostlynerdless.de</Caption>
```

## Badges

```md
<Badge variant="orange">NEW</Badge>
<Badge variant="blue">INFO</Badge>
<Badge variant="red">RISK</Badge>
<Badge variant="green">OK</Badge>
<Badge variant="gray">DRAFT</Badge>
```

## Key/Value rows

```md
<KeyValue>
  <template #key>Port</template>
  <template #value>8005</template>
</KeyValue>
```
