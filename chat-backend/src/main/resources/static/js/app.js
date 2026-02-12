/**
 * Phone Chat UI - Vanilla JS application
 * 
 * Features:
 * - Sends messages to /api/message endpoint
 * - Fetches message list from /api/messages
 * - Supports commands (e.g., /llm, /help, /whoami)
 * - Syntax highlighting for JSON output via Prism.js
 * - Auto-refresh every 3s (pauses while typing)
 * - Focus-aware rendering (preserves input focus)
 */

(() => {
  // ============================================================================
  // Library Loading Utilities
  // ============================================================================

  /** Load a script from src or fallback URL. */
  const loadScript = (src) => new Promise((resolve, reject) => {
    const script = document.createElement("script");
    script.src = src;
    script.defer = true;
    script.onload = () => resolve();
    script.onerror = () => reject(new Error(`Failed to load ${src}`));
    document.head.appendChild(script);
  });

  /** Load a stylesheet from href or fallback URL. */
  const loadStylesheet = (href) => new Promise((resolve, reject) => {
    const link = document.createElement("link");
    link.rel = "stylesheet";
    link.href = href;
    link.onload = () => resolve();
    link.onerror = () => reject(new Error(`Failed to load ${href}`));
    document.head.appendChild(link);
  });

  /** Try loading from primary URL; fall back to fallback URL on failure. */
  const withFallback = async (primary, fallback, loader) => {
    try {
      await loader(primary);
    } catch (err) {
      await loader(fallback);
    }
  };

  /** Ensure Prism.js and styling are loaded for syntax highlighting. */
  const ensureLibraries = async () => {
    if (typeof Prism === "undefined") {
      await withFallback(
        "/prism-tomorrow.min.css",
        "https://unpkg.com/prismjs@1.29.0/themes/prism-tomorrow.min.css",
        loadStylesheet
      );
      await withFallback(
        "/prism.js",
        "https://unpkg.com/prismjs@1.29.0/prism.js",
        loadScript
      );
      await withFallback(
        "/prism-json.min.js",
        "https://unpkg.com/prismjs@1.29.0/components/prism-json.min.js",
        loadScript
      );
    }
  };

  // ============================================================================
  // Application State
  // ============================================================================

  const state = {
    messages: [],    // Array of message objects from backend
    text: "",        // Current input field value
    loading: false,  // True while sending a message
    error: "",       // Error message to display, if any
  };

  // ============================================================================
  // HTML & Text Utilities
  // ============================================================================

  /** Escape HTML special characters to prevent XSS. */
  const escapeHtml = (value) => String(value)
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;");

  /** Format ISO timestamp to HH:MM:SS format. */
  const formatTime = (isoString) => {
    if (!isoString) return "";
    try {
      const date = new Date(isoString);
      return date.toLocaleTimeString('en-US', { hour12: false, hour: '2-digit', minute: '2-digit', second: '2-digit' });
    } catch (err) {
      return isoString;
    }
  };

  /** Parse JSON string and return pretty-printed version, or null if not valid JSON. */
  const prettyJson = (value) => {
    try {
      const parsed = JSON.parse(value);
      return JSON.stringify(parsed, null, 2);
    } catch (err) {
      return null;
    }
  };

  /** Render command output as HTML: if JSON, show as syntax-highlighted block; otherwise show as text. */
  const renderCommand = (msg) => {
    if (!msg || !msg.command) return "";
    const output = msg.commandOutput || "";
    const pretty = output ? prettyJson(output) : null;
    if (pretty) {
      return `<div><strong>/${msg.command}</strong></div><pre class="json language-json"><code class="language-json">${escapeHtml(pretty)}</code></pre>`;
    }
    return `<div><strong>/${msg.command}</strong> → ${escapeHtml(output)}</div>`;
  };

  /** Apply Prism.js syntax highlighting to all code blocks in messages container. */
  const highlightCode = () => {
    if (typeof Prism === "undefined") return;
    const container = document.querySelector(".messages");
    if (!container) return;
    Prism.highlightAllUnder(container);
  };

  /** Scroll messages container to the bottom. */
  const scrollBottom = () => {
    const el = document.querySelector(".messages");
    if (el) {
      el.scrollTop = el.scrollHeight;
    }
  };

  // ============================================================================
  // Rendering
  // ============================================================================

  /** 
   * Main render function: updates DOM with current state.
   * Auto-scrolls to last message on each render.
   */
  const render = () => {
    const root = document.getElementById("app");
    if (!root) return;
    const messages = Array.isArray(state.messages) ? state.messages : [];
    const error = state.error ?? "";
    const loading = Boolean(state.loading);

    root.innerHTML = `
      ${error ? `<div class="error-pill">${escapeHtml(error)}<button id="retry-btn">Retry</button></div>` : ""}
      <div class="title">Phone Chat</div>
      <div class="subtitle">${messages.length} messages • try <code>/llm</code>, <code>/help</code>, or <code>/whoami</code></div>
      <div class="messages">
        ${messages.map((msg) => `
          <div class="message">
            <div>${escapeHtml(msg.text ?? "")}</div>
            ${renderCommand(msg)}
            <div class="meta">${formatTime(msg.createdAt ?? "")} · ${escapeHtml(msg.podName ?? "")} · ${escapeHtml(msg.nodeName ?? "")}</div>
          </div>
        `).join("")}
      </div>
      <div class="input-row">
        <input id="message-input" value="${escapeHtml(state.text)}" placeholder="Type a message or /command" ${loading ? "disabled" : ""} />
        <button id="send-btn" ${loading ? "disabled" : ""}>${loading ? "..." : "Send"}</button>
      </div>
      ${error ? `<div class="hint">${escapeHtml(error)}</div>` : `<div class="hint">Commands come from config file on each pod.</div>`}
    `;

    const input = document.getElementById("message-input");
    const sendBtn = document.getElementById("send-btn");
    const retryBtn = document.getElementById("retry-btn");

    if (input) {
      input.addEventListener("input", (event) => {
        state.text = event.target.value;
      });
      input.addEventListener("keydown", (event) => {
        if (event.key === "Enter") {
          sendMessage();
        }
      });
    }

    if (sendBtn) {
      sendBtn.addEventListener("click", () => sendMessage());
    }

    if (retryBtn) {
      retryBtn.addEventListener("click", () => fetchMessages());
    }

    highlightCode();
    scrollBottom();
  };

  // ============================================================================
  // API Functions
  // ============================================================================

  /** Fetch messages from backend /api/messages endpoint. */
  const fetchMessages = async () => {
    try {
      const res = await fetch("/api/messages");
      if (!res.ok) {
        state.error = `Backend error: ${res.status}`;
        render();
        return;
      }
      state.messages = await res.json();
      state.error = "";
    } catch (err) {
      state.error = "Backend unreachable";
    }
    render();
  };

  /** Send current message text to /api/message endpoint and refresh. */
  const sendMessage = async () => {
    if (!state.text.trim()) return;
    state.loading = true;
    state.error = "";
    render();

    try {
      const res = await fetch("/api/message", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ text: state.text }),
      });
      if (!res.ok) {
        state.error = `Backend error: ${res.status}`;
        return;
      }
      state.text = "";
      await fetchMessages();
    } catch (err) {
      state.error = "Backend unreachable";
    } finally {
      state.loading = false;
      render();
    }
  };

  // ============================================================================
  // Initialization
  // ============================================================================

  /** Initialize app: load libs, render UI, fetch messages, set up auto-refresh. */
  const start = async () => {
    await ensureLibraries();
    render();
    fetchMessages();
    // Auto-refresh every 3s, but skip refresh if input is focused (user is typing)
    setInterval(() => {
      if (document.activeElement?.id !== "message-input") {
        fetchMessages();
      }
    }, 3000);
  };

  // ============================================================================
  // Bootstrap
  // ============================================================================

  start().catch((err) => {
    console.error(err);
    const root = document.getElementById("app");
    if (root) {
      root.innerHTML = "<div class=\"card\">Failed to load UI libraries.</div>";
    }
  });
})();
