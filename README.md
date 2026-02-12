# Kubernetes on a Phone 📱☸️

> Running a multi-node Kubernetes cluster on Android phones — with a distributed chat app and an on-device LLM.

This project explores a simple but slightly absurd idea:

> Modern smartphones are more powerful than early cloud servers.
> So… can we use them as Kubernetes nodes?

The answer is: **yes**.

This repository documents how to:

* Run **k3s** on Android phones
* Form a **multi-node Kubernetes cluster**
* Connect nodes using **Tailscale**
* Deploy lightweight demo applications
* Run a distributed **chat app**
* Integrate an **LLM running locally on a phone**
* Demonstrate Kubernetes core concepts in a beginner-friendly way

This was built for a 45-minute beginner conference talk.

---

## 🎤 For the Talk

**Full talk script with speaker notes, demos, and timing:** [TALK_DRAFT.md](./TALK_DRAFT.md)

Includes:
- Minute-by-minute breakdown
- Slide titles and speaker notes  
- 13 live demo commands with expected output
- Pacing and delivery tips
- Pre-talk checklist
- Q&A preparation

---

# Table of Contents

* [Architecture Overview](#architecture-overview)
* [Why This Works](#why-this-works)
* [Hardware Setup](#hardware-setup)
* [Software Stack](#software-stack)
* [Installing k3s on Android](#installing-k3s-on-android)
* [Creating a Multi-Node Cluster](#creating-a-multi-node-cluster)
* [Networking with Tailscale](#networking-with-tailscale)
* [Demo Applications](#demo-applications)

  * [Pong Server](#pong-server)
  * [Distributed Chat](#distributed-chat)
  * [LLM Integration](#llm-integration)
* [Kubernetes Concepts Used](#kubernetes-concepts-used)
* [References](#references)
* [Why You Probably Shouldn’t Do This in Production](#why-you-probably-shouldnt-do-this-in-production)

---

# Architecture Overview

```
           +------------------+
           |   Phone A        |
           |  (Control Plane) |
           |  k3s server      |
           +------------------+
                    |
                    |  (Tailscale VPN)
                    |
           +------------------+
           |   Phone B        |
           |  k3s agent       |
           +------------------+
```

Optional:

```
+------------------+
|  MacBook         |
|  kubectl client  |
+------------------+
```

Workloads are distributed across phones.

The LLM runs only on a labeled node.

---

# Why This Works

Android runs on the **Linux kernel**.

Kubernetes relies on:

* Linux namespaces
* cgroups
* container runtimes (containerd)
* networking primitives

k3s is a lightweight Kubernetes distribution packaged as a single binary:

👉 [https://k3s.io/](https://k3s.io/)

As long as we have:

* A Linux userspace
* containerd
* networking

We can run Kubernetes.

---

# Hardware Setup

* Phone A (Control Plane)
* Phone B (Worker)
* Optional MacBook (kubectl access)
* WiFi network
* Phones plugged into power
* Developer mode enabled
* Disable battery optimization

⚠ Important: Phones will throttle if overheating.

---

# Software Stack

* Android 16 terminal environment (or Termux)
* k3s
* containerd (bundled with k3s)
* Tailscale
* Lightweight container images
* Optional: llama.cpp or MLC LLM for on-device inference

---

# Installing k3s on Android

On Phone A (control plane):

```bash
curl -sfL https://get.k3s.io | sh -
```

Verify:

```bash
sudo k3s kubectl get nodes
```

Or configure kubectl:

```bash
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
kubectl get nodes
```

You should see:

```
phone-a   Ready   control-plane
```

k3s documentation:
[https://docs.k3s.io/](https://docs.k3s.io/)

---

# Creating a Multi-Node Cluster

Install k3s agent on Phone B:

```bash
curl -sfL https://get.k3s.io | \
K3S_URL=https://<phone-a-ip>:6443 \
K3S_TOKEN=<node-token> sh -
```

Get token from Phone A:

```bash
cat /var/lib/rancher/k3s/server/node-token
```

Verify cluster:

```bash
kubectl get nodes
```

Now you have:

```
phone-a   Ready   control-plane
phone-b   Ready   <none>
```

---

# Networking with Tailscale

Phones are usually behind NAT.

Kubernetes nodes must communicate directly.

We use Tailscale (WireGuard-based mesh VPN):

[https://tailscale.com/](https://tailscale.com/)

Install on each device:

```bash
curl -fsSL https://tailscale.com/install.sh | sh
sudo tailscale up
```

Check connectivity:

```bash
tailscale status
```

Each node gets a stable tailnet IP.

Tailscale Kubernetes operator:
[https://tailscale.com/blog/kubernetes-operator](https://tailscale.com/blog/kubernetes-operator)

Blog: Using Tailscale with Kubernetes:
[https://tailscale.com/blog/kubernetes-operator/](https://tailscale.com/blog/kubernetes-operator/)

Advanced example (each node as subnet router):
[https://blog.6nok.org/tailsk8s/](https://blog.6nok.org/tailsk8s/)

---

# Demo Applications

---

# Pong Server

Purpose:

* Demonstrate Pods
* Demonstrate Deployments
* Demonstrate Services
* Show scheduling

`pong.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: pong
spec:
  replicas: 1
  selector:
    matchLabels:
      app: pong
  template:
    metadata:
      labels:
        app: pong
    spec:
      containers:
      - name: pong
        image: your/pong-image
        ports:
        - containerPort: 8080
---
apiVersion: v1
kind: Service
metadata:
  name: pong
spec:
  selector:
    app: pong
  ports:
  - port: 80
    targetPort: 8080
```

Deploy:

```bash
kubectl apply -f pong.yaml
kubectl get pods -o wide
```

Scale:

```bash
kubectl scale deployment pong --replicas=3
```

Delete pod:

```bash
kubectl delete pod <pod-name>
```

Kubernetes will recreate it automatically.

---

# Distributed Chat

Chat backend:

* Lightweight HTTP server
* Logs hostname
* Loads commands from config
* Executes shell commands
* Returns container + node name

Each response includes:

```
Handled by: <container>
Node: <node>
```

Scale:

```bash
kubectl scale deployment chat --replicas=3
```

Refresh UI repeatedly to see load balancing across phones.

---

# LLM Integration

**Purpose:** Show local inference on a phone node without cloud APIs

**Tool:** [local-android-ai](https://github.com/parttimenerd/local-android-ai) by Johannes Bechberger

The LLM runs only on Phone B (native Android app).

## Setup

1. Download APK from [GitHub Releases](https://github.com/parttimenerd/local-android-ai/releases)
2. Install on phone-b
3. Download model (Gemma 3.1B recommended for speed)
   - Download from [HuggingFace](https://huggingface.co/) after accepting license
   - Or let app download other models directly
4. Load model into app ("Load Model" button)
5. Test endpoint:
   ```bash
   curl http://localhost:8005
   # Shows available APIs
   ```
6. Register command in chat ConfigMap:
   ```yaml
   llm=curl -s -d '{"text":"${ARG}","model":"GEMMA_3_1B_IT"}' http://localhost:8005/ai/text | jq -r '.response'
   ```
7. Label node:
   ```bash
   kubectl label node phone-b llm=true
   ```

## Usage

In the chat interface:

```
/llm Write a poem about containers
```

LLM generates response on phone-b (2-5 seconds), returned through chat.

## Models Available

- **Gemma 3.1B** (fast, recommended for demos)
- **Qwen 2.5 1.5B** (faster, but less capable)
- **EfficientDet Lite 2** (object detection via camera)

## API Details

- **Port:** 8005
- **Endpoints:**
  - `/ai/text` — Text generation
  - `/camera/detect` — Object detection
  - `/orientation` — Phone orientation data

**Reference:** [Blog Post: Running LLM on Android Phone](https://mostlynerdless.de/blog/2025/11/05/running-an-llm-on-an-android-phone/)

**Alternative Options:**

If you prefer a different LLM stack:

- [llama.cpp](https://github.com/ggerganov/llama.cpp) (C/C++ implementation)
- [MLC LLM](https://mlc.ai/) (Android support)

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
* [https://mostlynerdless.de/blog/2025/11/05/running-an-llm-on-an-android-phone/](https://mostlynerdless.de/blog/2025/11/05/running-an-llm-on-an-android-phone/)

Raspberry Pi Clusters:

* [https://k3s.io/](https://k3s.io/)
* [https://github.com/k3s-io/k3s-ansible](https://github.com/k3s-io/k3s-ansible)

Tailscale:

* [https://tailscale.com/blog/kubernetes-operator/](https://tailscale.com/blog/kubernetes-operator/)
* [https://blog.6nok.org/tailsk8s/](https://blog.6nok.org/tailsk8s/)

---

# Why You Probably Shouldn’t Do This in Production

* Phones throttle under load
* No redundant power
* Limited storage
* Thermal instability
* Not designed for 24/7 uptime

This is a learning and demo environment.

But:

It demonstrates that Kubernetes is not about data centers.

It is about orchestrating Linux machines.

And phones are Linux machines.

---

# Final Thought

> The cloud is just someone else’s computer.
> This is Kubernetes on someone else’s phone.

---

If you'd like, I can next:

* Turn this into a polished GitHub-ready README with badges and repo structure
* Add a `demo/` directory layout
* Or write a blog-post version with narrative tone instead of technical tone
