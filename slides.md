---
theme: default
background: img/cover.jpg
class: text-center
highlighter: shiki
lineNumbers: false
info: |
  ## Running Kubernetes on a Phone

  Running a multi-node cluster on Android devices

drawings:
  persist: false
transition: slide-left
title: Kubernetes on a Phone
mdc: true
---

# Kubernetes on a Phone

Running a multi-node cluster on Android devices

<div class="text-sm opacity-1">
Johannes Bechberger @ SAP SE
</div>

<!--
Take a deep breath. Smile. Make eye contact.
This is going to be fun.
-->

---
layout: center
---

# This Is Not a Joke

```sh
$ kubectl get nodes
NAME      STATUS   ROLES           AGE
phone-a   Ready    control-plane   30m
phone-b   Ready    <none>          10m
```

TODO: actual screenshot

<!--
<!--
Physically hold up the two phones.
Shock and awe. Make them lean forward.

Say slowly, with pauses:
"This is not a virtual machine.
This is not a Raspberry Pi.
This is my actual phone.
Running Kubernetes."

Pause for 3 seconds. Let it sink in.
-->

---

# What You'll See Today

- Multi-node Kubernetes cluster on Android phones
- VPN connecting them across networks
- Deploy apps, scale them, kill them
- Run an AI on one of them
- <span v-mark.orange="5">Learning the basics of Kubernetes along the way.</span>

<div class="text-sm text-orange-400 mt-8">
<strong>Caveat:</strong> I'm not a Kubernetes expert. This is all for fun. Think of it as an extreme educational exercise.
</div>

<!--
Confident. Slightly amused. You've done this before.

Pause before the last bullet.
"Today I'll show you how to run a multi-node Kubernetes cluster on Android phones,
connect them with a VPN, deploy apps, scale them, kill them,
and even run an AI on one of them."

Pause. "And if you understand what's happening today,
you understand Kubernetes."
-->

---

# Why Should You Care?

<div class="text-6xl font-bold text-center mt-12">
Kubernetes feels like magic
</div>

<!--
Build the case for why this matters.

"Kubernetes feels like magic to most people."

Pause. Let that sink in.
-->

---

# Why Should You Care?

<div class="text-6xl font-bold text-center mt-12">
Magic is intimidating
</div>

<!--
"And magic is intimidating.

When you don't understand how something works,
it's hard to trust it.
Hard to debug it.
Hard to use it effectively."
-->

---

# But on a Phone...

<div class="text-6xl font-bold text-center mt-8 text-orange-400">
You can see what's happening
</div>

<v-clicks>

<div class="text-5xl text-center mt-8">
You can <span class="font-bold">touch</span> the nodes
</div>

<div class="text-4xl text-center mt-4">
You can <span class="font-bold">feel</span> them heat up under load
</div>

<div class="text-3xl text-center mt-4">
You can <span class="font-bold">watch</span> the battery drain
</div>

</v-clicks>

<!--
"But on a phone, everything changes.

You can SEE what's happening.

You can touch the nodes. Actually hold them in your hand.

You can feel them heat up when the CPU is busy.

You can watch the battery drain as containers start.

It makes Kubernetes real."
-->

---
layout: statement
---

# Let's have some fun, 
# shall we?

<!--
"Here's the key insight:

When you understand Kubernetes on a phone—
where you can see and touch everything—

You understand Kubernetes everywhere.

AWS. Google Cloud. Azure. On-premises.

The concepts are the same.
The only difference is you can't hold an EC2 instance in your hand."

Pause. Let them absorb this.
-->

---
layout: section
---

# But first, who am I?

---
layout: image
image: img/playfull_sapmachine.png
---

---
layout: section
---

# Part 1: The Hardware Story

Why phones can run Kubernetes


---
image: img/server.jpg
layout: image-left
---

# Remember 2010?

This was a production server:

- 4 CPU cores @ 2.4 GHz
- 4-8 GB DDR3 RAM
- 500 GB HDD (7200 RPM)
- <span v-mark.orange="5">It ran WordPress for 50,000 daily users</span>

<ImageAttribution>
By Victor Grigas - Own work, CC BY-SA 3.0
</ImageAttribution>

<!--
"In 2010, a typical production server looked like this.

Four cores. Eight gigs of RAM. A spinning disk.

And that server handled real workloads. Fifty thousand users a day."

Pause.

"Now look at what's in your pocket."
-->

---
layout: image-right
image: img/cover.jpg
---

# My somewhat modern phone (2024)

- 9 CPU cores (1x 3.0GHz Cortex-X3, 4x 2.45GHz A715, 4x 2.15GHz A510)
- ARM Mali-G715 MP7 GPU
- 12 GB LPDDR5X memory
- 256 GB UFS 4.0 storage (faster than SATA SSDs)
- <span v-mark.orange="5">More powerful than that 2010 server</span>

<!--
"A modern phone has nine cores—more than twice what that server had.
Faster RAM. Storage that's faster than SSDs from just a few years ago.

And it costs half as much."

Pause.

"Your phone is a server. You just use it for texting."
-->

---

# Phones Are Ridiculous Now

| Spec | 2010 Server | 2024 Phone | 2025 Phone |
|------|-------------|------------|------------|
| CPU Cores | 4 | <span class="text-orange-400 font-bold">9</span> | <span class="text-orange-400 font-bold">8</span> |
| CPU Speed | 2.4 GHz | <span class="text-orange-400 font-bold">3.0 GHz (prime core)</span> | <span class="text-orange-400 font-bold">4.47 GHz (Oryon L)</span> |
| RAM | 4-8 GB DDR3 | <span class="text-orange-400 font-bold">12 GB LPDDR5X</span> | <span class="text-orange-400 font-bold">12 GB LPDDR5X</span> |
| Storage | HDD (100 MB/s) | <span class="text-orange-400 font-bold">UFS 4.0 (4,000 MB/s)</span> | <span class="text-orange-400 font-bold">UFS 4.0 (4,000 MB/s)</span> |
| GPU | - | Mali-G715 MP7 | <span class="text-orange-400 font-bold">Adreno 830</span> |
| Process | 45nm+ | 4nm | <span class="text-orange-400 font-bold">3nm</span> |

<div v-click class="text-xl text-orange-400 font-bold mt-4">
2025 phones: 8 cores (2x 4.47 GHz + 6x 3.53 GHz Oryon), Samsung S25 Ultra
</div>

<!--
"Look at these numbers.

Storage is forty times faster.
CPUs are faster and more efficient.
RAM is faster and denser.

And yet we use this hardware to watch cat videos."

Pause for laughs.

"But if phones have server-grade hardware, can they run server software?"
-->

---
layout: statement
---

# They are the perfect 
# <span color="red">IOT</span> device.

---

<div class="text-6xl font-bold text-center mt-8 text-orange-400">
It has everything you need
</div>

<v-clicks>

<div class="text-5xl text-center mt-8">
A <span class="font-bold">battery</span> to power it anywhere
</div>

<div class="text-4xl text-center mt-6">
A <span class="font-bold">screen</span> to interact with it directly
</div>

<div class="text-3xl text-center mt-5">
<span class="font-bold">Cellular connection</span> to stay online
</div>

<div class="text-3xl text-center mt-4">
And all this in a <span class="font-bold">readily available, compact</span> package.
</div>

</v-clicks>
---

# Geekbench

<div class="mt-8">

**Single-Core Performance:**

<div class="flex items-center gap-4 mt-4">
<div class="text-sm w-32">2010 Server</div>
<div class="bg-gray-600 h-8" style="width: 17.5%">350</div>
</div>

<div class="flex items-center gap-4 mt-2">
<div class="text-sm w-32 text-orange-400 font-bold">2024 Phone</div>
<div class="bg-orange-400 h-8" style="width: 64.4%">1288</div>
</div>

**Multi-Core Performance:**

<div class="flex items-center gap-4 mt-8">
<div class="text-sm w-32">2010 Server</div>
<div class="bg-gray-600 h-8" style="width: 24.7%">1112</div>
</div>

<div class="flex items-center gap-4 mt-2">
<div class="text-sm w-32 text-orange-400 font-bold">2024 Phone</div>
<div class="bg-orange-400 h-8" style="width: 75.3%">3393</div>
</div>

</div>

<div v-click class="text-2xl text-orange-400 font-bold mt-8 text-center">
Your pocket is more powerful than a 2010 data center
</div>

<!--
"These bars tell the story.

Single-core: The phone is nearly 4 times faster.
Multi-core: Over 3 times faster.

And this is comparing to a real production server.
The Dell PowerEdge M610 powered thousands of websites.

Now that power fits in your pocket."
-->

---

# PassMark

<div class="mt-8">

**Single-Thread Performance:**

<div class="flex items-center gap-4 mt-4">
<div class="text-sm w-32">2010 Server</div>
<div class="bg-gray-600 h-8" style="width: 28.3%">944</div>
</div>

<div class="flex items-center gap-4 mt-2">
<div class="text-sm w-32 text-orange-400 font-bold">2024 Phone</div>
<div class="bg-orange-400 h-8" style="width: 71.7%">2385</div>
</div>

**Multithread Performance:**

<div class="flex items-center gap-4 mt-8">
<div class="text-sm w-32">2010 Server</div>
<div class="bg-gray-600 h-8" style="width: 23.3%">2443</div>
</div>

<div class="flex items-center gap-4 mt-2">
<div class="text-sm w-32 text-orange-400 font-bold">2024 Phone</div>
<div class="bg-orange-400 h-8" style="width: 76.7%">8041</div>
</div>

</div>

<div v-click class="text-2xl text-orange-400 font-bold mt-8 text-center">
Every benchmark confirms it: phones have server-grade power
</div>

<!--
"Two different benchmarks. Same conclusion.

Geekbench: 3-4x faster.
PassMark: 2.5-3.3x faster.

Your phone is genuinely more powerful than a 2010 production server.

This isn't marketing. This is measured performance."
-->

---

# But Can Your Phone Run Kubernetes?

<div class="text-2xl font-bold mt-8">
If you have an iPhone: sorry
</div>

<!--
"First, let's address the elephant in the room.

This is Android-only.

iOS doesn't allow terminal emulators with package managers.
Apple's App Store guidelines prohibit running arbitrary code.
You can't access Linux kernel features.

So if you have an iPhone... sorry.

But if you have Android, keep watching."
-->

---

# But Can Android Run Kubernetes?

<v-clicks>

- Android runs on Linux
- Kubernetes runs on Linux
<div class="text-5xl text-orange-400 font-bold mt-4">So... yes?</div>

</v-clicks>

<!--
"Android is based on the Linux kernel.
Kubernetes runs on Linux.

So theoretically, yes.

But let's dig deeper."
-->

---
layout: section
---

# Part 2: The Software Story

Why Android can run Kubernetes

---

# What Does Kubernetes Need?

- **Namespaces** — Process isolation (PID, network, mount)
- **cgroups** — Resource limits (CPU, memory, I/O)
- **iptables** — Network routing and firewall
- **Overlay filesystem** — Layered container images

<!--
"Kubernetes needs four kernel features.

While Android's kernel has many of these,
running Kubernetes directly on Android is complex.

The solution: Run Debian inside Android via emulation.
Debian's environment is standard, tested, and reliable.

Kubernetes runs in Debian. Debian runs on Android. Simple."
-->

---

# Android Is Linux (But We Need Debian)

<v-clicks>

1. Android OS runs on Linux kernel
2. Use proot-distro or Linux Terminal App
3. Create emulated Debian environment
4. Install k3s inside Debian
5. Run your containers

</v-clicks>

<!--
"Android runs on the Linux kernel, but running Kubernetes directly on Android is tricky.

So we use an emulated Debian environment.

Either via proot-distro (slower, but more compatible)
Or via Linux Terminal App on Android 16+ (faster, more native).

Inside that Debian, Kubernetes runs normally."
-->

---
layout: center
---

<div class="text-6xl font-bold text-orange-400">
Demo Time!
</div>

<div class="text-2xl mt-8">
Let's see this Linux Terminal App for ourselves
</div>

<!--
"Enough theory. Let me show you what this looks like.

I'm going to open the Linux Terminal app on my phone.

Watch the screen."
-->

---

# How to Install Linux Terminal App

<div class="text-sm mt-4">
For Android 15+ (Google Pixel devices)
</div>

**Step 1: Enable Developer Options**
- Go to Settings → About Phone
- Tap "Build number" seven times

**Step 2: Enable Linux Development Environment**
- Go to Settings → System → Developer Options
- Find "Linux development environment, toggle it **On**

**Step 3: Install the Terminal**
- Find the Terminal app launcher
- Tap to install (~500 MB download)

<!--
"If you want to try this yourself, here's how.

First, enable developer options by tapping build number seven times.
Yes, seven times. Google has a sense of humor.

Then enable the Linux development environment in developer settings.

Finally, install the terminal app. It downloads about 500 MB.

And you're done. You have a real Linux terminal on your phone."
-->

---

# On Non-Pixel Phones: Use Termux

<div class="text-sm mt-4">
For any Android device (Android 7+)
</div>

**Step 1: Install Termux**
- Download from F-Droid (f-droid.org/packages/com.termux)

**Step 2: Install proot-distro**
```bash
pkg install proot-distro
```

**Step 3: Install Debian and Login**
```bash
proot-distro install debian
proot-distro login debian
```

**Step 4: Update Apt**
```bash
apt update
````

<div class="text-orange-400 font-bold mt-4">
You now have a Debian environment ready for k3s!
</div>

<!--
"If you don't have a Pixel, use Termux instead.

Download it from F-Droid, not Google Play.
The Play Store version is outdated and won't work.

Then install proot-distro, install Debian, and log in.

Four commands. That's it.

You now have a full Debian environment on any Android phone."
-->

---
layout: quote
---

# ⚠️ Important: Proot Performance

<div class="text-lg italic mt-8 px-12">
"Proot is slower. It uses Linux debugging interface (ptrace) to control the process execution and hijack arguments and return values of system calls, so it can simulate a different file system layout and user/group ids. This causes a lot of overhead. In my experience the biggest performance penalty can be observed when working with a lot of files (e.g. extracting tarball)."
</div>

<div class="text-sm text-gray-400 mt-8 text-right pr-12">
Source: Reddit r/termux
</div>

<div v-click class="text-orange-400 font-bold text-xl mt-8 text-center">
Linux Terminal App (Pixel) is faster — but proot works on any phone
</div>

<!--
"One important caveat: proot-distro is slower than the Linux Terminal App.

It uses the Linux debugging interface to simulate a different environment.
This adds overhead, especially when working with many files.

But here's the trade-off:
Linux Terminal App only works on Pixels.
Proot works on ANY Android phone.

So if you have a Pixel, use Linux Terminal App.
If you don't, proot is your only option—and it still works fine for k3s."
-->

---

# Linux Terminal App Performance

Even the "fast" option has limitations:

<v-clicks>

- **PassMark Multithread CPU**: 3629 (vs 8041 native)
- **Memory Access**: Only 2GB (vs 12GB total)
- **Reason**: VM overhead and resource isolation

<div class="text-orange-400 font-bold text-2xl mt-8">
Still 1.5x faster than the 2010 server! (2443)
</div>

<div v-click class="text-sm mt-4 text-gray-400">
For comparison: Mac M4 Pro (12 cores) scores 32,751 multithread, 4,563 single thread
</div>

<div v-click class="text-orange-400 font-bold mt-4">
Not desktop-fast, but fast enough for edge computing
</div>

</v-clicks>

<!--
"The Linux Terminal App is faster than proot, but it's not native performance.

The VM has overhead. Resource limits. Isolation.

Your PassMark score drops from 8041 to 3629.
You only get access to 2GB of memory, not the full 12GB.

But here's the key insight:
Even with these limitations, it's STILL faster than that 2010 production server.

This is a phone running a VM, and it beats a data center machine from 2010.

Now, is it as fast as a modern laptop? No. 
My Mac M4 Pro scores over 32,000 on PassMark multithread.
That's 9 times faster than the phone.

But for edge computing? For learning Kubernetes?
The phone is fast enough.

That's what matters."
-->

---
layout: image-left
image: img/k3s.png
backgroundSize: 60%
---

# k3s: Kubernetes for Edge

<div class="mt-6 mx-auto max-w-3xl text-left">
  <div class="text-2xl italic leading-relaxed text-gray-600 border-l-4 border-orange-400 pl-6">
    “K3s is a highly available, certified Kubernetes distribution designed for production workloads in unattended, resource-constrained, remote locations or inside IoT appliances.”
  </div>
  <div class="mt-4 text-sm text-gray-400 text-right">
    — K3s documentation
  </div>
</div>

<!--
"k3s is a lightweight Kubernetes.

Same API. Same concepts. Same kubectl.
But optimized for edge devices.

Single binary. Embedded database.

It's designed for devices exactly like phones."
-->

---

# So Can Phones Run Kubernetes?


<v-clicks>

- **Hardware?** <span class="text-orange-400 font-bold">More powerful than 2010 servers</span>
- **Environment?** <span class="text-orange-400 font-bold">Debian (emulated on Android)</span>
- **Software?** <span class="text-orange-400 font-bold">k3s in Debian</span>

<div class="text-4xl text-orange-400 font-bold mt-8">
Yes.
</div>

</v-clicks>

<!--
"Hardware? Check.
Linux environment? Check.
Kubernetes? Check.

Phones can run Kubernetes.

Now let me show you how."
-->


---
layout: section
---

# Part 3: Understanding Kubernetes

5 Concepts. That's all you need.

<!--
IMPORTANT: No deep dives. No etcd. No API servers.
Only what you need to understand the demo.

"Before we start the demos, you need to understand five concepts.
Not twenty. Not fifty. Five.

After this, everything else is just details."
-->

---
layout: image-left
image: img/kubernetes_logo.svg
backgroundSize: 90%
---

# Kubernetes in One Sentence:

<div class="text-3xl text-orange-400 font-bold">
"Tell Kubernetes what you want, and it makes it happen."
</div>

<div v-click class="text-sm mt-4">
That's it. Everything else is implementation details.
</div>

<!--
"Kubernetes is declarative orchestration.

You declare what you want.
Kubernetes figures out how to do it.

You say: 'I want three copies of this app running.'
Kubernetes says: 'Okay, I'll schedule them, monitor them, and restart them if they crash.'

Simple."
-->

---
layout: image-right
image: img/nodes.svg
backgroundSize: 90%
---

# Concept 1: Node

A (virtual) machine in the cluster

<div class="text-sm">In our case: <code>phone-a</code>, <code>phone-b</code></div>

<v-clicks>

<div class="text-sm mt-4">
Could be a server in AWS.<br>
Could be a Raspberry Pi in your closet.<br>
Could be a phone in your pocket.
</div>

<div class="text-orange-400 font-bold">
Kubernetes doesn't care what the hardware is
</div>

</v-clicks>

<!--
"A node is just a Linux machine that's joined a cluster.

Kubernetes treats all nodes the same.

Phone. Server. VM. Doesn't matter.

If it runs Linux and has the kernel features, it's a node."
-->

<ImageAttribution>
Kubernetes Documentation
</ImageAttribution>

---
image: img/phone_in_closet.jpg
layout: image-left
---

# Pods are just a compute resource.

And this is a phone in my closet

---
layout: image-right
image: img/nodes.svg
backgroundSize: 90%
---

# Concept 2: Pod

Smallest deployable unit. Usually wraps one container.

```
Pod: echo-abc123
  └─ Container: ealen/echo-server
     └─ Process: HTTP server on port 80
```

<div v-click class="text-sm mt-4">
Think of it as: <span class="text-orange-400 font-bold">Container + Kubernetes metadata</span>
</div>

<!--
"A Pod is a container with a Kubernetes passport.

The container runs your app.
The Pod is what Kubernetes schedules and tracks.

One sentence: That's all they need."
-->

<ImageAttribution>
Kubernetes Documentation
</ImageAttribution>

---
layout: image-right
image: img/deployment.png
backgroundSize: 90%
---

# Concept 3: Deployment

Declares desired state. "I want 3 of these running."

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: echo
spec:
  replicas: 3
  selector:
    matchLabels:
      app: echo
  template:
    metadata:
      labels:
        app: echo
    spec:
      containers:
      - name: echo
        image: ealen/echo-server
        ports:
        - containerPort: 80
```

<!--
"You tell Kubernetes what you want.
You don't tell it HOW to do it.
You say 'I want 3 replicas of this app.'
Kubernetes figures out the rest."

"If one crashes, Kubernetes notices and creates a new one. Automatically."
-->

<ImageAttribution>
Kubernetes Documentation
</ImageAttribution>

---

# The Magic of Reconciliation

Kubernetes constantly checks:

<v-clicks>

- **Desired state:** What you said you want (3 replicas)
- **Current state:** What actually exists (maybe only 2 running)
- <span class="text-orange-400 font-bold">**Action:**</span> Fix the difference (create 1 more)

<div class="mt-4">This happens automatically, forever</div>

</v-clicks>

<!--
"This is the core of Kubernetes.

It compares what you want with what exists.
If they don't match, it fixes the difference.

You delete a Pod? Kubernetes creates a new one.
A node dies? Kubernetes reschedules the Pods elsewhere.

This is reconciliation. It's automatic self-healing."
-->

---
layout: image-right
image: img/service.svg
backgroundSize: 90%
---

# Concept 4: Service

A stable network address for Pods

```
Service: echo (stable IP: 10.0.0.1)
  ├─ Pod 1 (IP: 10.1.2.1)
  ├─ Pod 2 (IP: 10.1.2.2)
  └─ Pod 3 (IP: 10.1.2.3)

Client 
→ Service IP 
→ One of the Pods (load balanced)
```

<!--
"Pods change. They come and go.
But the Service is always there, at the same address.
Clients don't care which Pod handles their request.
They just call the Service."
-->

<ImageAttribution>
Kubernetes Documentation
</ImageAttribution>

---
layout: image-right
image: img/service.svg
backgroundSize: 90%
---

# Why Services Matter

Without Services:
- Pod dies → IP changes → app breaks
- You'd need to track every Pod's IP
- No load balancing

<div v-click>
<div class="text-orange-400 font-bold mt-4">
With Services:</div>

- Always the same IP
- Automatic load balancing
- Kubernetes handles the routing
</div>

<!--
"Services solve the stability problem.

Pods are ephemeral. They come and go.
Services are stable. They stay the same.

You call the Service. Kubernetes routes to a healthy Pod.

Simple."
-->

<ImageAttribution>
Kubernetes Documentation
</ImageAttribution>

---

# Concept 5: Scheduler

Decides which Node gets which Pod

<div class="grid grid-cols-2 gap-8">

<div>

Scheduler looks at:
- Which nodes have capacity?
- Which nodes match constraints? 
  - memory
  - CPU
  - labels
- How to balance the load?

</div>

<div v-click>

<strong>Decision:</strong>

<table class="mt-4">
<thead>
<tr>
<th>Pod</th>
<th>Node</th>
</tr>
</thead>
<tbody>
<tr>
<td>Pod 1</td>
<td class="text-orange-400 font-bold">phone-a</td>
</tr>
<tr>
<td>Pod 2</td>
<td class="text-orange-400 font-bold">phone-b</td>
</tr>
<tr>
<td>Pod 3</td>
<td class="text-orange-400 font-bold">phone-a</td>
</tr>
</tbody>
</table>

</div>

</div>

<!--
"The scheduler is basically the cluster's traffic cop.
It looks at your Pods and your Nodes and says
'you go here, you go there.'"

Pause.

"That's it. That's Kubernetes."

Tone: Confident. You just explained Kubernetes in 4 minutes.
-->

---
layout: section
---

# YAML files galore

All this is configured by a few YAML files and the `kubectl` command-line tool.

---
layout: section
---

# Wrap up

---

<div class="text-6xl font-bold text-center mt-8 text-orange-400">
Thats everything you need
</div>

<v-clicks>

<div class="text-5xl text-center mt-8">
The <span class="font-bold">hardware</span> changes
</div>

<div class="text-4xl text-center mt-6">
The <span class="font-bold">tooling</span> changes
</div>

<div class="text-3xl text-center mt-5">
But the <span class="font-bold">concepts</span> stay the same
</div>

<div class="text-3xl text-center mt-4">
Nodes. Pods. Services. Scheduling.
</div>

<div class="text-3xl text-center mt-6">
This is <span class="font-bold">Kubernetes</span> in a nutshell</div>
</v-clicks>

---
layout: statement
---

But enough with the theory. Let's see it in action.

---
layout: section
---

# Part 4: A tiny k3s cluster 
# in your pocket

---
add intro slides into k3s and how to setup with a single node, get the cluster running,
deploy the [pong](https://hub.docker.com/r/ealen/echo-server) app, also mention whath the echo app does and go over the whole yaml file step by step
then deploy and also scale it

(I should do the same on the phone)

---


TODO: now to the middle part of the presentation where we do the demos and show how this all works in practice. We can refer back to these concepts as we go through each demo.


# Conclusion

What we've built and what it means

---

# We Started With a Claim

<div class="text-3xl text-orange-400 font-bold">
"Phones can run Kubernetes"
</div>

<div v-click class="mt-4">
You probably thought I was joking
</div>

<!--
"At the start, I showed you kubectl get nodes.

Two phones.

You might have thought it was a trick.
Or a joke.
Or some kind of VM."
-->

---
layout: statement
---

# Then We Proved It

<!--

- Deployed apps
- Scaled them
- Load-balanced across nodes
- Watched self-healing in action
- Connected two phones with a VPN
- Deployed a stateful chat app
- Ran an AI on one of them
- <span class="text-orange-400 font-bold">All with Kubernetes</span>
"And it all worked.

Not perfectly. Phones get hot. Batteries die.

But it worked.

Because Kubernetes doesn't care what the hardware is."
-->

---

# The Real Lesson

<div class="text-4xl text-orange-400 font-bold">
Kubernetes isn't magic
</div>

<v-clicks>

- It's just software
- Running on Linux
- Making decisions based on rules

<div class="text-orange-400 font-bold mt-4">You can understand it</div>

</v-clicks>

<!--
"Kubernetes feels intimidating.

There's so much to learn.
So many concepts.
So many YAML files.

But at its core, it's simple:

You say what you want.
Kubernetes makes it happen.

That's it."
-->

---

# Resources

- **This project:** github.com/parttimenerd/k3s-on-phone-demo
- **LLM app:** github.com/parttimenerd/local-android-ai
- **k3s docs:** k3s.io
- **Tailscale:** tailscale.com
- **Termux:** f-droid.org/packages/com.termux
- **proot-distro:** github.com/termux/proot-distro - **Linux Terminal App:** Google Play (Pixel devices, Android 15+) <div v-click class="text-orange-400 font-bold mt-4"> Everything is open source. Everything is documented. </div>

---

# Thank You

<div class="text-2xl mt-8">
For your time, your attention, and your curiosity
</div>

<div class="text-3xl text-orange-400 font-bold mt-8">
Now go build something impossible
</div>

<div class="grid grid-cols-2 gap-8 mt-10 text-center">
  <div>
    <div class="text-lg font-bold mb-3">Blog</div>
    <img
      src="/img/qr-mostlynerdless.png"
      alt="QR code for mostlynerdless.de"
      class="mx-auto rounded-lg"
      style="width: 50%"
    />
    <div class="mt-3 text-sm text-gray-500">
      <a href="https://mostlynerdless.de">mostlynerdless.de</a>
    </div>
  </div>
  <div>
    <div class="text-lg font-bold mb-3">SapMachine</div>
    <img
      src="/img/qr-sapmachine.png"
      alt="QR code for sapmachine.io"
      class="mx-auto rounded-lg"
      style="width: 50%"
    />
    <div class="mt-3 text-sm text-gray-500">
      <a href="https://sapmachine.io">sapmachine.io</a>
    </div>
  </div>
</div>

<!--
"We've covered a lot today.

From hardware to software to orchestration to AI.

The technology is real.
The concepts are portable.

<!--
"I'm happy to answer more questions.

About Kubernetes.
About phones.
About edge computing.
About LLMs.

Whatever you're curious about."
-->
