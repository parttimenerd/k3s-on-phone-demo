---
theme: default
background: slides/img/cover.jpg
class: text-center
highlighter: shiki
lineNumbers: false
drawings:
  persist: false
transition: slide-left
title: Kubernetes on a Phone — Q&A
mdc: true
---

---
layout: section
---

# Questions?

Repository: github.com/parttimenerd/k3s-on-phone-demo  
Blog: mostlynerdless.de

<!--
Common questions coming...
-->

---

# Common Questions

Here's what people usually ask:

---

# Q: Won't the phone overheat?

<v-clicks>

A: **Yes. Absolutely.**

- After 10-15 minutes of heavy load, phones hit 50-60°C
- CPUs throttle to prevent damage
- Performance drops 30-50%

<span class="text-orange-400 font-bold">That's why this is a demo, not production</span>

</v-clicks>

<!--
"Yes, phones overheat.

But here's the thing:
Kubernetes handles thermal throttling fine.

Performance drops, but apps keep running.
Scheduler might even reschedule heavy workloads.

In production, you'd use servers with active cooling.
But the Kubernetes behavior is the same."
-->

---

# Q: What about battery life?

<v-clicks>

A: **Terrible.**

- 5,000 mAh battery @ 14W load = ~1.5 hours
- That's why both phones are plugged in during demos

<span class="text-orange-400 font-bold">Mobile edge devices would have external power</span>

</v-clicks>

<!--
"Batteries die fast under load.

Running k3s + containers drains power quickly.

But edge devices in the real world—
IoT gateways, retail kiosks, factory sensors—
they all have external power.

Battery life only matters for truly mobile use cases."
-->

---

# Q: Can I really use this in production?

<v-clicks>

A: **Not on phones, no.**

But the concepts apply to real edge computing:
- Raspberry Pi clusters in retail stores
- NVIDIA Jetson for AI at the edge
- Intel NUCs in factory floors
- ARM servers in cell towers

<span class="text-orange-400 font-bold">Same k3s. Same Kubernetes. Different hardware.</span>

</v-clicks>

<!--
"Phones are a demo platform.

But k3s runs on real edge devices.

Retailers use it in stores.
Factories use it on shop floors.
Telcos use it in cell towers.

The techniques you saw today apply directly."
-->

---

# Q: Why would anyone do this?

<v-clicks>

A: **Three reasons:**

1. **Learning:** Understand Kubernetes without cloud costs
2. **Research:** Explore mobile edge computing patterns
3. **Fun:** Because it's cool

Also: Completely local LLM inference (no API fees, no cloud)

</v-clicks>

<!--
"The learning value is huge.

You can experiment for free.
Break things without cost.
See abstractions become concrete.

And yes, it's fun.

Plus, the LLM demo shows something important:
On-device AI with zero cloud dependency.

That's valuable for privacy and cost."
-->

---

# Q: How long does the LLM take to respond?

<v-clicks>

A: **2-5 seconds for short responses**

Factors affecting speed:
- Prompt length
- Desired response length
- CPU temperature (throttling)
- Model size (3.1B vs 7B)

<span class="text-orange-400 font-bold">Not instant, but fast enough for interactive use</span>

</v-clicks>

<!--
"Gemma 3.1B on a modern phone is surprisingly fast.

Short prompts: 2-3 seconds.
Long responses: 5-8 seconds.

Compare that to network latency to OpenAI's API
(which can be 1-2 seconds just for the round-trip),
and local inference is competitive.

Plus: no usage fees, no rate limits, works offline."
-->

---

# Q: What's the biggest challenge?

<v-clicks>

A: **Port restrictions**

- Termux can't bind to ports < 1024
- Solution: Use non-standard ports (6444 instead of 6443)

Second challenge: **Limited cgroup controllers**
- Some controllers (like pids) aren't enabled by default
- But enough work for basic orchestration

</v-clicks>

<!--
"The biggest gotcha is port restrictions.

Termux runs as a normal user, not root.
So you can't bind to privileged ports.

But Kubernetes is flexible.
Just change the port in the config.

The cgroup issue is minor.
Some advanced features won't work.
But Pods, Services, Deployments—all fine."
-->

---

# Q: How do you handle storage?

<v-clicks>

A: **Local filesystem + rqlite for distributed state**

- Each Pod can use emptyDir volumes (ephemeral)
- For persistent data: hostPath (node-local)
- For distributed state: rqlite (Raft-based replication)

<span class="text-orange-400 font-bold">No persistent volume claims (phones don't have NFS or Ceph)</span>

</v-clicks>

<!--
"Storage is tricky on phones.

No network storage.
No cloud volumes.
Just local flash.

For demos, that's fine.
For real apps, you'd use rqlite or similar
for state replication.

Or you'd keep state in a database on a server."
-->

---

# Q: Can you run this on iOS?

<v-clicks>

A: **No.**

- iOS doesn't allow terminal emulators with package managers
- App Store guidelines prohibit running arbitrary code
- No access to Linux kernel features

<span class="text-orange-400 font-bold">This is Android-only (specifically via Termux)</span>

</v-clicks>

<!--
"iOS is locked down.

Apple doesn't allow terminal emulators that can install packages.
You can't run Docker or k3s.
You can't access kernel features.

This demo requires Android with Termux.

Sorry, iPhone users."
-->

---

# Q: Where can I learn more?

- Repository: **github.com/parttimenerd/k3s-on-phone-demo**
- Blog post: **mostlynerdless.de**
- local-android-ai: **github.com/parttimenerd/local-android-ai**

<div v-click class="text-orange-400 font-bold mt-4">
Full setup guide, manifests, and documentation included
</div>

<!--
"Everything is open source.

Full README with setup instructions.
All manifests.
All code.
Troubleshooting guide.

You can reproduce this entire demo.

And if you do, let me know!"
-->

---

# Q: What's next?

Possible extensions:
- Add monitoring (Prometheus + Grafana)
- Service mesh (Linkerd/Istio)
- CI/CD pipeline (deploy from GitHub)
- More LLM models (7B, multimodal)
- Multi-phone scaling (3+ nodes)

<div v-click class="text-orange-400 font-bold mt-4">
The platform is real. The possibilities are endless.
</div>

<!--
"There's so much more you could do.

Add monitoring to see CPU/memory in real-time.
Add a service mesh for advanced routing.
Set up CI/CD to deploy from git pushes.

Or just use it to learn Kubernetes.

The choice is yours."
-->

---

# More Questions?

<div class="text-orange-400 font-bold text-2xl">
Let's discuss!
</div>

<!--
"I'm happy to answer more questions.

About Kubernetes.
About phones.
About edge computing.
About LLMs.

Whatever you're curious about."
-->
