const http = require('http');
const { WebSocketServer } = require('ws');
const pty = require('node-pty');
const path = require('path');
const fs = require('fs');
const { spawn } = require('child_process');

let PORT = 3031;
const HOST = '127.0.0.1'; // Localhost only for security
const SESSION_TIMEOUT_MS = 10 * 60 * 1000;

// Try to use PORT, increment if unavailable
function startServer() {
  const server = http.createServer((req, res) => {
    // Set CORS headers for localhost only
    res.setHeader('Access-Control-Allow-Origin', 'http://localhost:3032');
    res.setHeader('Access-Control-Allow-Methods', 'GET, OPTIONS');
    res.setHeader('Access-Control-Allow-Headers', 'Content-Type');

    if (req.method === 'OPTIONS') {
      res.writeHead(204);
      res.end();
      return;
    }

    if (req.url === '/health') {
      res.writeHead(200, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({ status: 'ok', port: PORT }));
    } else {
      res.writeHead(404);
      res.end('Not Found');
    }
  });

  server.listen(PORT, HOST, () => {
    console.log(`Terminal server running on http://${HOST}:${PORT}`);
    console.log(`WebSocket ready for xterm.js connections`);
    console.log(`Security: Only accepting connections from localhost`);
    setupWebSocket(server);
  });

  server.on('error', (err) => {
    if (err.code === 'EADDRINUSE') {
      console.log(`Port ${PORT} is in use, trying ${PORT + 1}...`);
      PORT++;
      startServer();
    } else {
      throw err;
    }
  });
}

function setupWebSocket(server) {
  // WebSocket server for terminal connections
  const wss = new WebSocketServer({ server });

  // Allowed script directories (whitelist)
  const ALLOWED_DIRS = [
    path.resolve(__dirname, '../..')
  ];

  function isScriptAllowed(scriptPath) {
    const resolved = path.resolve(scriptPath);
    return ALLOWED_DIRS.some(dir => resolved.startsWith(dir));
  }

  wss.on('connection', (ws, req) => {
    const clientIp = req.socket.remoteAddress;
    
    // Only accept localhost connections
    if (clientIp !== '127.0.0.1' && clientIp !== '::1' && clientIp !== '::ffff:127.0.0.1') {
      console.log(`Rejected connection from ${clientIp}`);
      ws.close(1008, 'Only localhost connections allowed');
      return;
    }

    console.log('Terminal connected from localhost');

    let ptyProcess = null;
    let session = null;
    let sessionTimeout = null;
    let cleanupDone = false;

    function cleanupPty(reason) {
      if (cleanupDone) return;
      cleanupDone = true;

      if (sessionTimeout) {
        clearTimeout(sessionTimeout);
        sessionTimeout = null;
      }

      if (session) {
        try {
          session.kill();
        } catch (err) {
          console.error('Failed to kill PTY process:', err);
        }

        const fd = session.fd;
        if (typeof fd === 'number') {
          try {
            fs.closeSync(fd);
            console.log('Closed PTY master FD', { fd, reason });
          } catch (err) {
            console.error('Failed to close PTY master FD:', err);
          }
        }
      }
    }

    ws.on('message', (data) => {
      try {
        const message = JSON.parse(data.toString());

        if (message.type === 'start') {
          // Start a new terminal session
          const shell = resolveShell();
          const cwd = path.resolve(__dirname, '../..');

          try {
            session = spawnShell(shell, message, cwd);
            ptyProcess = session.process;
          } catch (err) {
            console.error('Failed to spawn shell:', shell, err);
            ws.send(JSON.stringify({
              type: 'error',
              message: `Failed to spawn shell (${shell}): ${err.message}`
            }));
            return;
          }

          session.onData((data) => {
            ws.send(JSON.stringify({ type: 'data', data }));
          });

          session.onExit((exitCode) => {
            ws.send(JSON.stringify({ type: 'exit', exitCode }));
            cleanupPty('process-exit');
          });

          if (sessionTimeout) {
            clearTimeout(sessionTimeout);
          }
          sessionTimeout = setTimeout(() => {
            console.warn('Session timeout reached, closing PTY');
            ws.send(JSON.stringify({ type: 'error', message: 'Session timeout reached' }));
            cleanupPty('timeout');
            try {
              ws.close(1000, 'Session timeout');
            } catch (err) {
              console.error('Failed to close websocket after timeout:', err);
            }
          }, SESSION_TIMEOUT_MS);

          ws.send(JSON.stringify({ type: 'started' }));

        } else if (message.type === 'data') {
          // Forward input to terminal
          if (session) {
            session.write(message.data);
          }

        } else if (message.type === 'resize') {
          // Resize terminal
          if (session && session.resize) {
            session.resize(message.cols, message.rows);
          }

        } else if (message.type === 'stop') {
          ws.send(JSON.stringify({ type: 'exit', exitCode: 0 }));
          cleanupPty('session-stop');

        } else if (message.type === 'execute') {
          // Execute a script
          const scriptPath = message.script;

          if (!isScriptAllowed(scriptPath)) {
            ws.send(JSON.stringify({
              type: 'error',
              message: 'Script not in allowed directories'
            }));
            return;
          }

          if (session) {
            // Make script executable and run it
            const command = `bash "${scriptPath}"\n`;
            session.write(command);
          }
        }

      } catch (err) {
        console.error('Error processing message:', err);
        ws.send(JSON.stringify({ type: 'error', message: err.message }));
      }
    });

    ws.on('close', () => {
      console.log('Terminal disconnected');
      cleanupPty('ws-close');
    });

    ws.on('error', (err) => {
      console.error('WebSocket error:', err);
      cleanupPty('ws-error');
    });
  });
}

function resolveShell() {

  const candidates = [
    '/bin/bash',
    '/usr/bin/bash',
    process.env.SHELL,
    '/bin/zsh',
    '/usr/bin/zsh',
    '/bin/sh'
  ].filter(Boolean);

  for (const candidate of candidates) {
    if (candidate && fs.existsSync(candidate)) {
      return candidate;
    }
  }

  return 'sh';
}

function spawnShell(shell, message, cwd) {
  const baseEnv = {
    ...process.env,
    PATH: process.env.PATH || '/usr/bin:/bin:/usr/sbin:/sbin'
  };

  const options = {
    name: 'xterm-color',
    cols: message.cols || 80,
    rows: message.rows || 24,
    cwd: cwd,
    env: baseEnv
  };

  try {
    const ptyProcess = pty.spawn(shell, [], options);
    return wrapPtySession(ptyProcess);
  } catch (err) {
    console.error('Retrying spawn with /bin/sh after failure:', err);
    try {
      const ptyProcess = pty.spawn('/bin/sh', [], options);
      return wrapPtySession(ptyProcess);
    } catch (ptyErr) {
      console.error('PTY spawn failed, falling back to child_process:', ptyErr);
      return spawnFallbackShell(shell, cwd, baseEnv);
    }
  }
}

function wrapPtySession(ptyProcess) {
  return {
    process: ptyProcess,
    fd: ptyProcess._fd,
    onData: (handler) => ptyProcess.onData(handler),
    onExit: (handler) => ptyProcess.onExit(({ exitCode }) => handler(exitCode)),
    write: (data) => ptyProcess.write(data),
    resize: (cols, rows) => ptyProcess.resize(cols, rows),
    kill: () => ptyProcess.kill()
  };
}

function spawnFallbackShell(shell, cwd, env) {
  const child = spawn(shell, [], {
    cwd,
    env,
    stdio: ['pipe', 'pipe', 'pipe']
  });

  return {
    process: child,
    fd: undefined,
    onData: (handler) => {
      child.stdout.on('data', (data) => handler(data.toString()));
      child.stderr.on('data', (data) => handler(data.toString()));
    },
    onExit: (handler) => child.on('exit', (code) => handler(code ?? 0)),
    write: (data) => {
      if (!child.stdin.destroyed) {
        child.stdin.write(data);
      }
    },
    resize: null,
    kill: () => child.kill('SIGTERM')
  };
}

startServer();
