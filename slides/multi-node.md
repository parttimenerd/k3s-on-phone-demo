---
layout: statement
---

# Thank you!


---
layout: statement
---

# Wait? An <OrangeText>encore</OrangeText>?

---
layout: statement
---

# Let's add another <RedText>phone</RedText> 
# to the <OrangeText>cluster</OrangeText>

---
layout: statement
---

# But how can the <RedText>phones</RedText>
# <OrangeText>see</OrangeText> <BlueText>each other</BlueText>?

<!--
"When you have multiple nodes, they need to talk to each other.
The control plane needs to reach the worker nodes.
Pods need to communicate across nodes.

But here's the problem: these are mobile phones.
They might be on different WiFi networks, different mobile carriers.
They can't see each other."

Pause. Build tension.
-->

---

# Solution: A VPN

<div style=" text-align: center; margin-top: 6em;">
```mermaid
flowchart LR
  subgraph vpn[VPN]
    direction LR
    phoneA[📱 Phone A]
    internet((☁️))
    phoneB[📱 Phone B]
    phoneA --- internet --- phoneB
  end
  style vpn stroke-dasharray:6 6,stroke:#94a3b8,fill:#ffffff00
  style internet font-size:48px,stroke-width:2px
```
</div>

<div v-click class="mt-8 text-2xl text-center">
In our case: <img src="./img/mn/tailscale-logo.svg" alt="Tailscale logo" style="display: inline-block; height: 3em; margin-left: 8px;" />
</div>

<!--
"The solution is a VPN - a virtual private network.
It makes all your devices appear as if they're on the same local network,
even if they're on opposite sides of the world.
No port forwarding or firewall changes needed, works across different physical networks and is encrypted for security.

For this demo, we're using Tailscale.
It's free for personal use, zero-config, and works great on Android."
-->

---

# What is Tailscale?

- Zero-config VPN based on WireGuard
- Mesh network - devices connect directly
- Free for personal use (up to 100 devices)
- Each device gets a stable IP address (100.x.x.x)

This is not an advertisement, just a great tool.

<!--
"Tailscale is a modern VPN that just works.
You install it, authenticate once, and your devices can talk to each other.

Each device gets a stable IP address in the 100.x.x.x range.
That's what we'll use for our cluster communication."
-->

<!--
# Setup Tailscale: UI Method

<PhoneTwoColumn
  :img="['./img/echo-demo/tailscale_install.png', './img/echo-demo/tailscale_auth.png', './img/echo-demo/tailscale_connected.png']"
>

You can also install via the Tailscale Android app:

1. Install from Google Play
2. Authenticate with your account
3. Grant VPN permissions

<div class="text-orange-400 font-bold mt-8">
For this demo, we'll use the terminal method instead
</div>

</PhoneTwoColumn>-->

<!--
"You can also install Tailscale through the Android app.
Install from Play Store, authenticate, grant permissions.

But for this demo, we're going to use the terminal method.
It's faster, more repeatable, and fits the theme."
-->

---

<CroppedImage src="./img/mn/tailscale-token-gen.png" alt="Tailscale Token Generation" />

---

<PhoneTwoColumnZoom
  img="./img/mn/setup_tailscale.png"
  :zoom="1"
  :offsetY="-381"
  :clickToReveal="true"
>

# Setup Tailscale

Prerequisites:
- Create `.tailscale-key` file with your Tailscale auth key

<br/>

<CodeWithScript scriptPath="./echo-demo/scripts/07-setup-tailscale.sh">
```bash
./echo-demo/scripts/07-setup-tailscale.sh phone-a
# Essentially:
curl -fsSL https://tailscale.com/install.sh | sh
sudo tailscale up --auth-key "$AUTH_KEY" \
  --hostname "$HOSTNAME"
```
</CodeWithScript>

Installs Tailscale and connects with hostname `phone-a`.

</PhoneTwoColumnZoom>

<!--
"For the terminal method, you'll need a Tailscale auth key.
Create one in your Tailscale admin console.
Put it in a .tailscale-key file in the repo root.

Then run the script with the hostname you want - like phone-a.
It installs Tailscale and automatically connects using the auth key.

Much faster than the manual authentication flow."
-->

---
layout: statement
---

# Now let's <BlueText>join</BlueText>
# the <RedText>second phone</RedText>


---

<PhoneTwoColumnZoom
  img="./img/mn/setup-tailscale2.png"
  :zoom="1"
  :offsetY="-400"
  :clickToReveal="true"
>

# Setup Tailscale

1. Pull the GitHub repo on the second phone

```bash
sudo apt update; sudo apt install git curl
git clone https://github.com/parttimenerd/k3s-on-phone-demo
cd k3s-on-phone-demo
```
<v-click>

2. Create `.tailscale-key` file <br/>

</v-click>

<v-click>

3. Run the setup script with a different hostname:

```bash
./echo-demo/scripts/07-setup-tailscale.sh phone-b
```

</v-click>

</PhoneTwoColumnZoom>

---

<CroppedImage src="./img/mn/tailscale-machines.png" alt="Tailscale Machines" />


---
layout: image
image: "./img/phone_in_closet.jpg"
---


---

<PhoneTwoColumnZoom
  img="./img/mn/join-cluster.png"
  :zoom="1"
  :offsetY="-401"
  :clickToReveal="true"
>

# Join Second Phone to Cluster

```bash{1|3-|3,8|4|5|6|7|all}
./echo-demo/scripts/08-join-cluster.sh
# Essentially:
curl -sfL https://get.k3s.io | \
  K3S_URL=https://$CONTROL_PLANE_HOSTNAME:6443 \
  K3S_TOKEN=$K3S_TOKEN K3S_NODE_NAME=$NODE_NAME \
  K3S_CLUSTER_CIDR=10.42.0.0/16 \
  INSTALL_K3S_EXEC="--flannel-iface=tailscale0" \
  sh -
```

<v-clicks>

*These settings also need to be on the control plane.*
</v-clicks>

</PhoneTwoColumnZoom>

<!--
Three critical settings:
- `K3S_CLUSTER_CIDR=10.42.0.0/16` — pod address space
- `--flannel-iface=tailscale0` — use Tailscale for tunneling
- `K3S_NODE_NAME=phone-b` — node identity
-->

---

# Why These Settings Matter

<div class="text-center mb-8">

**Without both of these, cross-node pods can't talk.**

</div>

<div class="grid grid-cols-2 gap-8">

<div>

**`K3S_CLUSTER_CIDR=10.42.0.0/16`**

Enables routing:
- `10.42.0.0/24` → phone-a ✓
- `10.42.1.0/24` → phone-b ✓

Without it:
- Uncoordinated ranges ❌
- Flannel has no routes ❌

</div>

<div>

**`--flannel-iface=tailscale0`**

Enables tunneling:
- Packets go via VPN ✓
- phone-b is reachable ✓

Without it:
- Tries WiFi/cellular ❌
- Packets get lost ❌

</div>

</div>

<!--
"Let me explain what's actually happening here.

**What is Flannel?**
Flannel is k3s's Container Network Interface plugin - think of it as the postal service for pods across nodes. It creates an overlay network using VXLAN, which is basically encapsulation.

When a pod on phone-a wants to talk to a pod on phone-b, Flannel takes that packet and wraps it up - encapsulates it - so it can be sent over the physical network. The catch is: Flannel needs to know which physical node to send it to.

**Why K3S_CLUSTER_CIDR matters:**
Without it, each node independently assigns pod IP ranges. Phone-a might use 10.42.0.0/24 and phone-b gets 10.42.3.0/24 - completely different ranges with no coordination. Flannel can't build routes because it doesn't know which pod CIDRs belong to which node.

With K3S_CLUSTER_CIDR=10.42.0.0/16, we're telling both nodes: 'allocate your pod IPs from this /16 range.' Phone-a gets 10.42.0.0/24 as its sub-range, phone-b gets 10.42.1.0/24. Now Flannel knows: anything in 10.42.1.0/24 goes to phone-b.

**Why --flannel-iface=tailscale0 matters:**
Here's the subtle part: Flannel knows it needs to send packets to phone-b. But how? Over which interface? On a normal Kubernetes cluster, all nodes are on the same physical network - Flannel just sends the encapsulated packet on the main network interface.

But our nodes are on different phones. They might be on different WiFi networks, or cellular. The only connection between them is the Tailscale VPN tunnel - the tailscale0 interface.

Without --flannel-iface=tailscale0, Flannel auto-detects and tries to use eth0 or wlan0 - the WiFi or cellular interface. But phone-b isn't reachable there! The packet gets lost.

With --flannel-iface=tailscale0, we're telling Flannel: 'Use the Tailscale interface to tunnel encapsulated packets to remote nodes.' Now the VXLAN traffic goes through the VPN, and both phones can reach each other.

That's the magic of this setup: Flannel + Tailscale. Flannel handles the pod networking, Tailscale handles the VPN. Together, they give you a real Kubernetes cluster across phones."
-->

---

<PhoneTwoColumnZoom
  img="./img/mn/verify-cluster.png"
  :zoom="1"
  :offsetY="-30"
>

# Verify Multi-Node Cluster

<CodeWithScript scriptPath="./echo-demo/scripts/02-verify-cluster.sh">
```bash
kubectl get nodes
```
</CodeWithScript>

</PhoneTwoColumnZoom>

<!--
"Back on the control plane, let's verify both nodes are in the cluster.

You should see two nodes - phone-a as control plane, phone-b as worker.
Both should show STATUS: Ready."

Point at the screen. "This is a real multi-node Kubernetes cluster."
-->

---

<CroppedImage src="./img/mn/tailscale-dns.png" alt="Tailscale DNS" />

<!--
You might need to change the DNS, so that the docker registry can be resolved. 
Tailscale provides MagicDNS for this purpose, but it seems to fail.
-->
---



<PhoneTwoColumnZoom
  img="./img/mn/deploy_multi_node.png"
  :zoom="1"
  :offsetY="-30"
  :clickToReveal="true"
>

# Deploy Echo Server

<CodeWithScript scriptPath="./echo-demo/scripts/03-deploy-echo.sh">

```bash{all|1}
kubectl apply -f echo-demo/manifests/echo.yaml
kubectl wait --for=condition=ready \
  pod -l app=echo \
  --timeout=60s
kubectl get pods -o wide
```
</CodeWithScript>

Same deployment, but now Kubernetes can schedule pods on **both phones**.

</PhoneTwoColumnZoom>

<!--
"Let's deploy the echo server again.
Same script as before.
But now Kubernetes has two nodes to work with.

Watch as it schedules pods across both phones."
-->

---

<PhoneTwoColumnZoom
  img="./img/mn/curl.png"
  :zoom="2"
  :offsetY="-30"
  :clickToReveal="false"
>

# Cross-Node Load Balancing


<CodeWithScript scriptPath="./echo-demo/scripts/04c-curl-nodename.sh">
```bash
curl http://127.0.0.1:30080?echo_env_body=NODE_NAME
```
</CodeWithScript>


Notice how traffic is distributed across **different physical devices**.

</PhoneTwoColumnZoom>

<!--
"Now for the cool part.

This script makes several requests to the service.
But it asks for the NODE_NAME environment variable.

Watch as the responses come from different nodes.
That's Kubernetes load balancing traffic across two physical phones."

Click through slowly. Let each one sink in.
"phone-a... phone-b... phone-a again.

This is real distributed computing."
-->

---

<PhoneTwoColumnZoom
  img="./img/mn/delete.png"
  :zoom="1"
  :offsetY="-25"
>

# Remove Second Phone from Cluster


<CodeWithScript scriptPath="./echo-demo/scripts/09-delete-phone-b.sh">
```bash
kubectl drain "$NODE_NAME" \
  --ignore-daemonsets \
  --delete-emptydir-data --force
kubectl delete node "$NODE_NAME"
```
</CodeWithScript>

Drains and removes phone-b from the cluster.

After this, the cluster is back to a single node.

</PhoneTwoColumnZoom>

<!--
"Before we undeploy, let's remove phone-b from the cluster.

This drains the node first - moving any running pods to other nodes.
Then it deletes the node registration from the cluster.

Let me explain those flags:
- --ignore-daemonsets: DaemonSets are system pods that run on every node.
  We can't move them, so we tell kubectl to ignore them during the drain.
- --delete-emptydir-data: Some pods use temporary storage called emptyDir.
  This flag allows the drain to proceed by deleting that temporary data.
- --force: Sometimes pods aren't managed by a controller. Force lets us delete them anyway.

Now we're back to a single-node cluster, just like we started."
-->

---

<PhoneTwoColumnZoom
  img="./img/mn/undeploy.png"
  :zoom="1"
  :offsetY="-30"
>

# Cleanup: Undeploy

<CodeWithScript scriptPath="./echo-demo/scripts/06-undeploy-echo.sh">
```bash
kubectl delete -f echo-demo/manifests/echo.yaml
```
</CodeWithScript>

Removes the deployment and service from the cluster.

Both phones are now idle, ready for the next demo.

</PhoneTwoColumnZoom>

<!--
"And when we're done, we clean up.

Same undeploy script as before.
It removes the deployment and service from both phones.

The cluster is still running, both nodes are still connected.
But the echo pods are gone."
-->

---
layout: statement
---

# So, <RedText>yes</RedText>, you can build a
# <OrangeText>Kubernetes</OrangeText> <BlueText>cluster</BlueText>
# from <RedText>phones</RedText>


---
layout: statement
---

# A truly <RedText>mobile</RedText>
# (and <BlueText>distributed</BlueText>) 
# <OrangeText>cluster</OrangeText>!
