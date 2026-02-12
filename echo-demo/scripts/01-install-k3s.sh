#!/usr/bin/env bash
set -euo pipefail

sudo apt install -y curl git > /dev/null 2>&1 || apt install -y curl git > /dev/null 2>&1

curl -sfL https://get.k3s.io | sh -
