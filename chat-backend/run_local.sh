#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CHAT_DIR="${ROOT_DIR}/chat-backend"
RQLITE_DATA_DIR="${CHAT_DIR}/.rqlite"
RQLITE_LOG="${CHAT_DIR}/.rqlite.log"
RQLITE_HTTP_ADDR="127.0.0.1:4001"
RQLITE_RAFT_ADDR="127.0.0.1:4002"
APP_PORT="${PORT:-8080}"

mkdir -p "${RQLITE_DATA_DIR}"

cleanup() {
  if [[ -n "${RQLITE_PID:-}" ]]; then
    kill "${RQLITE_PID}" >/dev/null 2>&1 || true
  fi
}
trap cleanup EXIT

echo "Starting rqlite..."
SERVER_BIN=""
if command -v rqlited >/dev/null 2>&1; then
  SERVER_BIN="rqlited"
elif command -v rqlite >/dev/null 2>&1; then
  SERVER_BIN="rqlite"
fi

if [[ -z "${SERVER_BIN}" ]]; then
  echo "rqlited (server) binary not found in PATH" >&2
  exit 1
fi

rm -f "${RQLITE_LOG}"
"${SERVER_BIN}" -http-addr "${RQLITE_HTTP_ADDR}" -raft-addr "${RQLITE_RAFT_ADDR}" "${RQLITE_DATA_DIR}" >"${RQLITE_LOG}" 2>&1 &
RQLITE_PID=$!

echo "Waiting for rqlite on ${RQLITE_HTTP_ADDR}..."
for _ in {1..30}; do
  if curl -fsS "http://${RQLITE_HTTP_ADDR}/status" >/dev/null 2>&1; then
    break
  fi
  sleep 0.5
done

if ! curl -fsS "http://${RQLITE_HTTP_ADDR}/status" >/dev/null 2>&1; then
  echo "rqlite did not start on ${RQLITE_HTTP_ADDR}" >&2
  echo "--- rqlite log ---" >&2
  tail -n 50 "${RQLITE_LOG}" >&2 || true
  exit 1
fi

echo "Building chat backend..."
cd "${CHAT_DIR}"
mvn -q -DskipTests clean package

echo "Starting chat backend on port ${APP_PORT}..."
export PORT="${APP_PORT}"
export RQLITE_JDBC_URL="jdbc:rqlite:http://${RQLITE_HTTP_ADDR}"
export COMMANDS_FILE="${CHAT_DIR}/commands.conf"
java -jar "${CHAT_DIR}/target/phone-chat-1.0.0.jar"
