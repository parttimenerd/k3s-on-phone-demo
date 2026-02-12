#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

sudo apt install -y curl > /dev/null 2>&1 || apt install -y curl > /dev/null 2>&1

curl -sfL https://get.k3s.io | sh -
