# Kubernetes on a Phone

[![Slidev Build](https://github.com/parttimenerd/k3s-on-phone-demo/actions/workflows/slidev-build.yml/badge.svg)](https://github.com/parttimenerd/k3s-on-phone-demo/actions/workflows/slidev-build.yml)

> Running a multi-node Kubernetes cluster on Android phones for educational purposes.

Modern smartphones are more powerful than early cloud servers. This project demonstrates running **k3s** (lightweight Kubernetes) on Android phones.

## Quick Start

**Slides & Presentation:** See [slides/](./slides/)

To run the slides locally:
```bash
cd slides
npm install
npm run dev
```

Or use the convenient launcher:
```bash
cd slides
./launch.sh              # Presentation only
./launch.sh --terminal   # With interactive terminal server
```

Then open http://localhost:3032 in your browser.

### Interactive Terminal Feature

The presentation includes an **interactive terminal** for running demo scripts directly from slides.

**Features:**
- Execute scripts in a real terminal emulator (xterm.js)
- Press `t` to toggle terminal or click "Run" buttons
- See live command output in the presentation

**⚠️ Security Notice:**
- **Network access** - Terminal server can bind to all interfaces for remote access
- **No encryption** - WebSocket traffic is unencrypted
- **Not for production** - Educational/demo purposes only
- Scripts are whitelisted to `echo-demo/`, `chat-demo/`, and `demo/` directories

**Setup:**
```bash
cd slides
./launch.sh --terminal
```

The launcher will automatically install dependencies and start both the terminal server and presentation.

**Demo Scripts:**
- `echo-demo/` — Simple echo server deployment
- `chat-demo/` — Distributed chat application

## Table of Contents

- [Kubernetes on a Phone](#kubernetes-on-a-phone)
  - [Quick Start](#quick-start)
    - [Interactive Terminal Feature](#interactive-terminal-feature)
  - [Table of Contents](#table-of-contents)
  - [Architecture](#architecture)
  - [Setup](#setup)
- [Kubernetes Concepts Used](#kubernetes-concepts-used)
- [Additional Useful References](#additional-useful-references)
- [Final Thought](#final-thought)

---

## Architecture

```
Phone A (k3s server) ←→ Tailscale VPN ←→ Phone B (k3s agent)
```

## Setup

**Requirements:**
- Android 15+ with Linux Terminal App (or Termux)
- Tailscale account
- Phones plugged in and battery optimization disabled

**Install k3s on Phone A:**
```bash
curl -sfL https://get.k3s.io | sh -
```

**Connect Phone B:**
```bash
# Get token from Phone A
cat /var/lib/rancher/k3s/server/node-token

# On Phone B
curl -sfL https://get.k3s.io | \
  K3S_URL=https://<phone-a-ip>:6443 \
  K3S_TOKEN=<token> sh -
```

**Setup Tailscale (both phones):**
```bash
curl -fsSL https://tailscale.com/install.sh | sh
sudo tailscale up
```

---

# Kubernetes Concepts Used

This demo intentionally focuses on beginner concepts.

Pods
[https://kubernetes.io/docs/concepts/workloads/pods/](https://kubernetes.io/docs/concepts/workloads/pods/)

Deployments
[https://kubernetes.io/docs/concepts/workloads/controllers/deployment/](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/)

Services
[https://kubernetes.io/docs/concepts/services-networking/service/](https://kubernetes.io/docs/concepts/services-networking/service/)

Nodes
[https://kubernetes.io/docs/concepts/architecture/nodes/](https://kubernetes.io/docs/concepts/architecture/nodes/)

Scheduler
[https://kubernetes.io/docs/concepts/scheduling-eviction/kube-scheduler/](https://kubernetes.io/docs/concepts/scheduling-eviction/kube-scheduler/)

k3s
[https://docs.k3s.io/](https://docs.k3s.io/)

---

# Additional Useful References

Running Kubernetes on Phones:

* [https://hackaday.com/2025/04/20/old-phones-become-a-kubernetes-cluster/](https://hackaday.com/2025/04/20/old-phones-become-a-kubernetes-cluster/)

Raspberry Pi Clusters:

* [https://k3s.io/](https://k3s.io/)
* [https://github.com/k3s-io/k3s-ansible](https://github.com/k3s-io/k3s-ansible)

Tailscale:

* [https://tailscale.com/blog/kubernetes-operator/](https://tailscale.com/blog/kubernetes-operator/)
* [https://blog.6nok.org/tailsk8s/](https://blog.6nok.org/tailsk8s/)

---

# Final Thought

> The cloud is just someone else’s computer.
> This is Kubernetes on someone else’s phone.

