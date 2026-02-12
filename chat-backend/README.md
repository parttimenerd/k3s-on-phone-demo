# Chat Backend

A Java-based chat server built with Javalin, jOOQ, and rqlite, designed to run on Kubernetes or locally.

## Features

- **REST API** for messaging (`/api/message`, `/api/messages`)
- **Command execution** - runs shell commands via `/command` syntax
- **rqlite integration** - distributed SQLite via JDBC
- **JSON output highlighting** - Prism.js syntax highlighting
- **Local and pod-based commands** - extensible command config
- **Built-in commands**: `/help` (list commands), `/clear` (clear database)

## Technology Stack

- **Java 25** - modern JVM with latest features
- **Javalin 6.3.0** - lightweight HTTP framework
- **jOOQ 3.19.16** - type-safe SQL builder
- **rqlite 1.0.1** - JDBC driver for rqlite
- **Jackson** - JSON serialization
- **Docker** - multi-stage build with Alpine runtime

## Building

### Local Build

```bash
mvn clean package
```

Produces `target/phone-chat-1.0.0.jar`

### Docker Build

```bash
docker build -t phone-chat:latest .
```

Or use the publish script:

```bash
./publish.sh docker.io/parttimenerd/phone-chat:v1.0.0
```

## Running

### rqlite Requirement

Both local and Kubernetes deployments require an **rqlite server** for persistent message storage.

- **Locally**: `run_local.sh` automatically starts rqlite on port 4001
- **Kubernetes**: rqlite runs as a sidecar in the chat pod

### Locally

Requires rqlite server running on localhost:4001:

```bash
./run_local.sh
```

This script:
1. Starts rqlite server (if available)
2. Waits for rqlite HTTP endpoint to be ready
3. Builds the project with Maven
4. Starts the chat server on port 8080

Access: `http://localhost:8080`

### Docker

```bash
docker run -p 8080:8080 phone-chat:latest
```

### Kubernetes

See `demo/manifests/chat.yaml` for pod definition with rqlite sidecar.

## Kubernetes Setup

### Prerequisites

- Kubernetes cluster (k3s, minikube, etc.)
- `kubectl` configured to access your cluster
- Docker registry access (e.g., Docker Hub)

### Step 1: Build and Push Image

```bash
cd chat-backend
./publish.sh docker.io/parttimenerd/phone-chat:v1.0.0
```

This builds the Docker image and pushes it to your registry.

### Step 2: Update Deployment Manifest

The `chat.yaml` in this folder includes rqlite as a sidecar container. Update the image reference to your registry:

```yaml
containers:
  - name: chat
    image: docker.io/parttimenerd/phone-chat:v1.0.0  # Update here
  - name: rqlite
    image: rqlite/rqlite:8.27.0  # Already set up as sidecar
```

#### chat.yaml Walkthrough

The manifest defines the complete chat service with integrated rqlite database. Here's a detailed breakdown:

**Deployment Section** (lines 1-63)
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: chat
  labels:
    app: chat
spec:
  replicas: 2  # Two pod replicas for redundancy
```
- Creates a Deployment named `chat` with 2 replicas
- Labels help identify and select the pods

**Pod Spec Containers** (lines 19-62)
Two containers run in each pod:

1. **rqlite Sidecar** (lines 21-31)
```yaml
- name: rqlite
  image: rqlite/rqlite:8.27.0
  args:
    - -http-addr 0.0.0.0:4001      # HTTP API on 4001
    - -raft-addr 0.0.0.0:4002      # Raft consensus on 4002
    - /rqlite/file/data             # Data directory
  volumeMounts:
    - name: chat-data
      mountPath: /rqlite
```
- rqlite database server runs in the same pod as the chat app
- Accessible to chat via `localhost:4001` (they share pod network namespace)
- Data stored in shared `chat-data` volume

2. **Chat Application** (lines 32-62)
```yaml
- name: chat
  image: docker.io/parttimenerd/phone-chat:v1.0.0
  ports:
    - containerPort: 8080
```
- Your Java application, listening on port 8080

**Environment Variables** (lines 37-45)
```yaml
env:
  - name: POD_NAME
    valueFrom:
      fieldRef:
        fieldPath: metadata.name    # Pod name injected automatically
  - name: NODE_NAME
    valueFrom:
      fieldRef:
        fieldPath: spec.nodeName    # Node name injected automatically
  - name: RQLITE_JDBC_URL
    value: jdbc:rqlite:http://localhost:4001  # Connects to rqlite sidecar
  - name: COMMANDS_FILE
    value: /config/commands.conf    # ConfigMap path
```
- `POD_NAME` and `NODE_NAME` are injected from Kubernetes metadata
- Chat app uses these to tag messages with pod/node info
- `RQLITE_JDBC_URL` points to localhost because rqlite is in the same pod

**Volume Mounts** (lines 46-50)
```yaml
volumeMounts:
  - name: chat-data
    mountPath: /rqlite              # Shared with rqlite container
  - name: chat-config
    mountPath: /config              # ConfigMap mounted here
```
- `chat-data`: shared storage between chat and rqlite
- `chat-config`: commands configuration from ConfigMap

**Health Checks** (lines 51-62)
```yaml
readinessProbe:
  httpGet:
    path: /api/healthz
    port: 8080
  initialDelaySeconds: 3
  periodSeconds: 5                  # Check every 5 seconds
livenessProbe:
  httpGet:
    path: /api/healthz
    port: 8080
  initialDelaySeconds: 10
  periodSeconds: 10                 # Check every 10 seconds
```
- **Readiness**: Wait 3s, then check if pod can receive traffic
- **Liveness**: After 10s, periodically verify pod is still alive
- Both hit `/api/healthz` endpoint

**Volumes** (lines 63-69)
```yaml
volumes:
  - name: chat-data
    emptyDir: {}                    # Temporary storage, lost on pod restart
  - name: chat-config
    configMap:
      name: chat-commands           # References ConfigMap named "chat-commands"
```
- `emptyDir`: Created when pod starts, destroyed when pod stops
  - Good for development; use `PersistentVolumeClaim` for production
- `configMap`: Kubernetes ConfigMap containing command definitions

**Service Section** (lines 71-82)
```yaml
apiVersion: v1
kind: Service
metadata:
  name: chat
  labels:
    app: chat
spec:
  selector:
    app: chat
  ports:
    - name: http
      port: 80                      # External port
      targetPort: 8080              # Container port
```
- Exposes the chat pods as a service
- External port 80 maps to container port 8080
- Service DNS: `chat.default.svc.cluster.local` (or just `chat` in same namespace)
- Type defaults to `ClusterIP` (accessible only within cluster)

**Key Design Points:**
- Both containers in one pod = localhost communication = no network latency
- Shared `chat-data` volume = both containers see same data
- ConfigMap mounting = commands can be updated without rebuilding image
- Service abstraction = clients don't need to know which pod they hit
- Health probes = Kubernetes automatically restarts unhealthy pods


### Step 3: Create ConfigMap for Commands

Create a ConfigMap with your command definitions:

```bash
kubectl apply -f manifest/chat-config.yaml
```

### Step 4: Deploy to Cluster

```bash
kubectl apply -f manifest/chat.yaml
```

This creates:
- **chat** Deployment with rqlite sidecar
- **chat** Service (ClusterIP on port 8080)

### Step 5: Access the Service

#### Port Forward (Local Testing)

```bash
kubectl port-forward svc/chat 8080:8080
```

Then open `http://localhost:8080` in your browser.

#### Expose as NodePort

```bash
kubectl patch svc chat -p '{"spec":{"type":"NodePort"}}'
kubectl get svc chat
```

Find the NodePort (e.g., 30123) and access via `http://<node-ip>:30123`

#### Ingress (Production)

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: chat-ingress
spec:
  rules:
  - host: chat.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: chat
            port:
              number: 8080
```

```bash
kubectl apply -f chat-ingress.yaml
```

### Scaling

Scale the deployment:

```bash
kubectl scale deployment chat --replicas=3
```

All replicas connect to the same rqlite instance via the sidecar.

### Viewing Logs

```bash
kubectl logs -f deployment/chat
```

Follow a specific pod:

```bash
kubectl logs -f pod/chat-xxxxx
```

### Cleanup

```bash
kubectl delete -f manifest/chat.yaml
kubectl delete configmap chat-commands
```

## Configuration

Environment variables:

- `PORT` - HTTP server port (default: 8080)
- `POD_NAME` - pod identifier (default: unknown-pod)
- `NODE_NAME` - node identifier (default: unknown-node)
- `RQLITE_JDBC_URL` - rqlite JDBC URL (default: `jdbc:rqlite:http://localhost:4001`)
- `COMMANDS_FILE` - path to commands config (default: `/config/commands.conf`)

## Commands

Commands are defined in `commands.conf` (or via configmap in k8s).

Format: `commandname=shell command with ${ARG} ${POD_NAME} ${NODE_NAME}`

Example:

```
llm=curl -s http://localhost:8000/api/text -d "input=${ARG}"
whoami=echo "Pod: ${POD_NAME}, Node: ${NODE_NAME}"
```

## API

### GET /api/messages

Returns last 50 messages as JSON array.

### POST /api/message

Send a message or execute a command.

```json
{
  "text": "/llm hello"
}
```

Response includes executed command output if applicable.

### GET /api/healthz

Health check endpoint.

## Database

SQLite via rqlite. Schema auto-created on startup:

```sql
CREATE TABLE messages (
  id BIGINT PRIMARY KEY AUTOINCREMENT,
  text VARCHAR(2048),
  created_at VARCHAR(64),
  pod_name VARCHAR(128),
  node_name VARCHAR(128),
  command VARCHAR(128),
  command_output CLOB
)
```

## UI

Vanilla JavaScript frontend in `src/main/resources/static/`:

- `index.html` - layout
- `js/app.js` - application logic
  - Auto-refresh every 3s
  - Prism.js syntax highlighting
  - Focus-aware rendering
