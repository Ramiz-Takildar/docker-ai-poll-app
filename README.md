# AI Poll Voting Application - Complete Docker Guide

A comprehensive guide to running the AI Poll application using pure Docker (without Docker Compose).

---

## Table of Contents

1. [Quick Start (Scripts)](#quick-start-scripts)
2. [Overview](#overview)
3. [Architecture](#architecture)
4. [Prerequisites](#prerequisites)
5. [Installation & Setup](#installation--setup)
6. [Running the Application](#running-the-application)
7. [Docker Concepts Explained](#docker-concepts-explained)
8. [API Endpoints](#api-endpoints)
9. [Container Management](#container-management)
10. [Troubleshooting](#troubleshooting)
11. [Advanced Topics](#advanced-topics)
12. [Script Reference](#script-reference)
13. [Quick Reference](#quick-reference)

---

## Quick Start (Scripts)

The easiest way to get started is using the provided scripts. These scripts handle all Docker operations safely without affecting other applications.

### Using Automated Scripts (Recommended)

**Start the application:**
```bash
bash start.sh
```

Expected output:
```
🐳 AI Poll Application - Docker Launcher

🧹 Cleaning up old containers from this application...
   (Nothing to clean)

1️⃣  Creating Docker network (poll-network)...
   ✓ Network created
2️⃣  Starting PostgreSQL container (postgres-db)...
   ✓ Container created
   Waiting for PostgreSQL to initialize...
   ✓ Ready
3️⃣  Building Flask application image (ai-poll-app:v1)...
   ✓ Image built
4️⃣  Starting Flask application container (flask-app)...
   ✓ Container created
   Waiting for Flask app to initialize...
   ✓ Ready

✅ Application is ready!

📍 Access the application:
   Web:     http://localhost:8000
   Results: http://localhost:8000/results
   Health:  http://localhost:8000/health
```

**Stop and cleanup:**
```bash
bash stop.sh
```

Expected output:
```
🧹 AI Poll Application - Cleanup Script

⚠️  This will only remove this application's containers:
   - flask-app
   - postgres-db
   - poll-network
   - ai-poll-app:v1

   Other Docker containers will NOT be affected.

1️⃣  Stopping Flask application container...
   ✓ Stopped
2️⃣  Stopping PostgreSQL container...
   ✓ Stopped
3️⃣  Removing Flask application container...
   ✓ Removed
4️⃣  Removing PostgreSQL container...
   ✓ Removed
5️⃣  Removing Docker network...
   ✓ Removed
6️⃣  Removing application image (ai-poll-app:v1)...
   ✓ Image removed

✅ Cleanup complete! (6 items removed)
```

### What the Scripts Do

**`start.sh`** — Automated startup
- Cleans up old containers from THIS application only
- Creates Docker network named `poll-network`
- Starts PostgreSQL database container
- Builds Flask application Docker image
- Starts Flask application container
- Displays access information and useful commands
- Runs cleanly every time (removes old, creates fresh)

**`stop.sh`** — Safe cleanup
- Stops and removes only THIS application's containers
- Removes only THIS application's network
- Removes only THIS application's Docker image
- **Does NOT affect other Docker containers/applications**
- Safe to run multiple times (skips items already removed)

### Safety Guarantee

Both scripts explicitly check for and only remove this application's containers:

| Item | Script Target | Safe? |
|------|---------------|-------|
| Container: `flask-app` | ✓ Removed only by these scripts | ✓ Safe |
| Container: `postgres-db` | ✓ Removed only by these scripts | ✓ Safe |
| Network: `poll-network` | ✓ Removed only by these scripts | ✓ Safe |
| Image: `ai-poll-app:v1` | ✓ Removed only by these scripts | ✓ Safe |
| Other containers | ✗ Never touched | ✓ Protected |
| Other networks | ✗ Never touched | ✓ Protected |
| Other images | ✗ Never touched | ✓ Protected |

**Example:** If you have an nginx container running, it will remain completely untouched.

### Running Scripts Multiple Times

The `start.sh` script is safe to run multiple times:

```bash
bash start.sh  # First run: Creates everything from scratch
bash start.sh  # Second run: Removes old, creates fresh
bash start.sh  # Third run: Removes old, creates fresh
```

Each run produces a clean, fresh environment with no conflicts.

---

## Overview

### What is This Application?

The AI Poll Voting Application is a Flask-based web application that allows users to vote on poll questions and view results in real-time. It uses PostgreSQL as the database to store votes.

### Why Pure Docker?

Pure Docker (using `docker run` commands directly) gives you:
- **Full control** over container configuration
- **Transparency** — see exactly what runs and how
- **Learning value** — understand Docker fundamentals
- **Flexibility** — easy to modify and debug individual components
- **Script automation** — easy to automate with bash scripts

### Key Technologies

| Component | Technology | Purpose |
|-----------|-----------|---------|
| Web Framework | Flask 2.3.2 | Python web application framework |
| Database | PostgreSQL 15 | Relational database for storing votes |
| ORM | SQLAlchemy 2.0 | Python object-relational mapping tool |
| Container Runtime | Docker | Application containerization |
| Base Image | python:3.11-slim | Lightweight Python 3.11 runtime |

---

## Architecture

### System Diagram

```
┌─────────────────────────────────────────────────┐
│            Docker Host (Your Machine)            │
│                                                  │
│  ┌────────────────────────────────────────────┐ │
│  │          poll-network (Bridge Network)     │ │
│  │                                            │ │
│  │  ┌──────────────────┐  ┌──────────────┐  │ │
│  │  │                  │  │              │  │ │
│  │  │   flask-app      │  │ postgres-db  │  │ │
│  │  │   Container      │  │ Container    │  │ │
│  │  │                  │  │              │  │ │
│  │  │ Port: 5000       │  │ Port: 5432   │  │ │
│  │  │ (app runs here)  │  │ (DB runs)    │  │ │
│  │  │                  │  │              │  │ │
│  │  └──────────────────┘  └──────────────┘  │ │
│  │           ▲                ▲              │ │
│  │           │ (DNS: localhost:5000)        │ │
│  │           └────────────────┘              │ │
│  │                                           │ │
│  │  Containers communicate via network name │ │
│  └────────────────────────────────────────────┘ │
│            ▲                                    │
│            │ Port Mapping                      │
│            │ (docker run -p 8000:5000)        │
│            ▼                                    │
│  ┌────────────────────────────────────────────┐ │
│  │  Host Machine Ports (Your Browser)         │ │
│  │  8000 → 5000 (Flask)                       │ │
│  │  5432 → 5432 (PostgreSQL)                  │ │
│  └────────────────────────────────────────────┘ │
│            ▲                                    │
│            │ HTTP Requests                     │
│            │ http://localhost:8000             │
│            │                                    │
└────────────┼────────────────────────────────────┘
             │
       ┌─────▼──────┐
       │   Browser  │
       └────────────┘
```

### Container Communication

**Inside Docker Network (`poll-network`):**
- `flask-app` → connects to `postgres-db` using hostname `postgres-db:5432`
- Containers resolve container names via Docker's embedded DNS server
- No need to know IP addresses

**From Your Machine:**
- `http://localhost:8000` → routed to container port 5000 (Flask app)
- PostgreSQL available on `localhost:5432` (optional, for direct DB access)

---

## Prerequisites

### System Requirements

**Minimum:**
- 2 GB RAM
- 2 GB free disk space
- Multi-core CPU

**Recommended:**
- 4 GB RAM
- 4 GB free disk space
- Recent Docker version (20.10+)

### Required Software

1. **Docker Desktop** (macOS, Windows) or **Docker Engine** (Linux)
   - [Install Docker Desktop](https://www.docker.com/products/docker-desktop)
   - [Install Docker Engine on Linux](https://docs.docker.com/engine/install/)

2. **Verify Installation**

   ```bash
   docker --version
   # Output: Docker version 25.0.0, build abcdef1
   
   docker ps
   # Output: CONTAINER ID IMAGE COMMAND CREATED STATUS PORTS NAMES
   # (empty list is fine)
   ```

### Port Availability

The application requires two ports to be available:

- **Port 8000** — Flask web application (accessed from browser)
- **Port 5432** — PostgreSQL database (optional, only for direct DB access)

**Check if ports are in use:**

```bash
# macOS/Linux
lsof -i :8000
lsof -i :5432

# Windows (PowerShell)
netstat -ano | findstr :8000
netstat -ano | findstr :5432
```

If ports are in use, either:
- Stop the conflicting application
- Use different ports (modify `-p` flag in docker run commands)

---

## Installation & Setup

### Step 1: Verify Project Structure

Ensure your project has these files:

```
ai-poll-app/
├── app/
│   ├── app.py                 # Flask application
│   ├── database.py            # Database models and functions
│   ├── requirements.txt        # Python dependencies
│   ├── templates/
│   │   ├── index.html         # Voting page
│   │   ├── results.html       # Results page
│   │   └── 404.html           # Error page
│   └── static/
│       ├── style.css          # Styling
│       └── script.js          # Frontend JavaScript
├── Dockerfile                 # Container build instructions
├── .dockerignore              # Files to exclude from build
├── start.sh                   # Start script (creates fresh containers)
├── stop.sh                    # Stop script (safe cleanup)
└── START.md                   # This documentation
```

**Verify files exist:**

```bash
ls -la app/app.py app/requirements.txt Dockerfile start.sh stop.sh
```

### Step 2: Review the Dockerfile

The Dockerfile defines how the Flask app image is built:

```dockerfile
FROM python:3.11-slim

ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

WORKDIR /app

RUN useradd -m -u 1000 appuser

COPY app/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app/ .
RUN chown -R appuser:appuser /app

USER appuser

EXPOSE 5000

HEALTHCHECK --interval=30s --timeout=10s --start-period=10s --retries=3 \
    CMD python -c "import requests; requests.get('http://localhost:5000/health', timeout=5)" || exit 1

CMD ["python", "app.py"]
```

**What each instruction does:**

| Instruction | Purpose |
|-------------|---------|
| `FROM python:3.11-slim` | Base image (minimal Python 3.11) |
| `ENV ...` | Set environment variables for build optimization |
| `WORKDIR /app` | Set container's working directory |
| `RUN useradd` | Create non-root user for security |
| `COPY app/requirements.txt .` | Copy dependencies file |
| `RUN pip install` | Install Python packages |
| `COPY app/ .` | Copy application code |
| `RUN chown` | Change file ownership to non-root user |
| `USER appuser` | Run container as non-root user |
| `EXPOSE 5000` | Document that app listens on port 5000 |
| `HEALTHCHECK` | Periodic health checks (Docker monitors container) |
| `CMD ["python", "app.py"]` | Default command when container starts |

---

## Running the Application

### Method 1: Using Automated Script (Recommended)

The `start.sh` script automates all Docker commands:

```bash
bash start.sh
```

**What it does automatically:**
1. Cleans up old containers from THIS application (not other apps)
2. Creates Docker network `poll-network`
3. Starts PostgreSQL container named `postgres-db`
4. Builds Flask app image named `ai-poll-app:v1`
5. Starts Flask app container named `flask-app`
6. Displays access information

**Output:**
```
🐳 AI Poll Application - Docker Launcher

🧹 Cleaning up old containers from this application...
   (Nothing to clean)

1️⃣  Creating Docker network (poll-network)...
   ✓ Network created
2️⃣  Starting PostgreSQL container (postgres-db)...
   ✓ Container created
   Waiting for PostgreSQL to initialize...
   ✓ Ready
3️⃣  Building Flask application image (ai-poll-app:v1)...
   ✓ Image built
4️⃣  Starting Flask application container (flask-app)...
   ✓ Container created
   Waiting for Flask app to initialize...
   ✓ Ready

✅ Application is ready!

📍 Access the application:
   Web:     http://localhost:8000
   Results: http://localhost:8000/results
   Health:  http://localhost:8000/health
```

---

### Method 2: Manual Docker Commands (For Understanding)

Follow these steps to understand each Docker operation:

#### Step 1: Create Docker Network

A Docker network allows containers to communicate by hostname instead of IP addresses.

```bash
docker network create poll-network
```

**Explanation:**
- `docker network` — Docker networking command
- `create` — Create new network
- `poll-network` — Network name (referenced later in container startup)

**Verify network was created:**

```bash
docker network ls
```

**Output:**
```
NETWORK ID     NAME            DRIVER    SCOPE
abc123def456   poll-network    bridge    local
```

---

#### Step 2: Start PostgreSQL Container

Launch the database container:

```bash
docker run -d \
  --name postgres-db \
  --network poll-network \
  -e POSTGRES_USER=admin \
  -e POSTGRES_PASSWORD=admin123 \
  -e POSTGRES_DB=polls \
  -p 5432:5432 \
  postgres:15
```

**Detailed breakdown:**

| Option | Purpose | Value |
|--------|---------|-------|
| `docker run` | Start new container | — |
| `-d` | Detached mode (run in background) | — |
| `--name` | Container identifier | `postgres-db` |
| `--network` | Join this network | `poll-network` |
| `-e POSTGRES_USER` | Database username | `admin` |
| `-e POSTGRES_PASSWORD` | Database password | `admin123` |
| `-e POSTGRES_DB` | Default database name | `polls` |
| `-p 5432:5432` | Port mapping: host:container | `host_port:container_port` |
| `postgres:15` | Image to run | PostgreSQL 15 |

**What happens:**
1. Docker pulls `postgres:15` image (if not already cached)
2. Creates container named `postgres-db`
3. Connects container to `poll-network`
4. Sets PostgreSQL credentials via environment variables
5. Maps port 5432 on host to port 5432 in container
6. Container starts with PID 1 process as `postgres` server

**Verify container started:**

```bash
docker ps
```

**Expected output:**
```
CONTAINER ID   IMAGE         COMMAND                  CREATED        STATUS       PORTS
xyz789abc123   postgres:15   "docker-entrypoint.s…"   5 seconds ago  Up 4 seconds 0.0.0.0:5432->5432/tcp
```

**Wait for PostgreSQL to initialize:**

```bash
sleep 8
```

PostgreSQL needs time to:
- Initialize data directory
- Create system tables
- Start the server
- Accept connections

**Check PostgreSQL is ready:**

```bash
docker exec postgres-db pg_isready -U admin
```

**Output when ready:**
```
accepting connections
```

---

#### Step 3: Build Flask Application Image

Create a Docker image for the Flask app:

```bash
docker build -t ai-poll-app:v1 .
```

**Detailed breakdown:**

| Option | Purpose | Value |
|--------|---------|-------|
| `docker build` | Build image from Dockerfile | — |
| `-t` | Tag (name:version) | `ai-poll-app:v1` |
| `.` | Dockerfile location (current directory) | — |

**What happens:**
1. Docker reads `Dockerfile` from current directory
2. Executes each instruction sequentially
3. Creates intermediate layers for caching
4. Final layer becomes image `ai-poll-app:v1`
5. Image stored in local Docker image cache

**Verify image was created:**

```bash
docker images | grep ai-poll-app
```

**Output:**
```
REPOSITORY      TAG    IMAGE ID      CREATED        SIZE
ai-poll-app     v1     abcdef123456  2 minutes ago   187MB
```

---

#### Step 4: Start Flask Application Container

Launch the Flask app container:

```bash
docker run -d \
  --name flask-app \
  --network poll-network \
  -e DB_HOST=postgres-db \
  -e DB_PORT=5432 \
  -e DB_NAME=polls \
  -e DB_USER=admin \
  -e DB_PASSWORD=admin123 \
  -e FLASK_ENV=production \
  -e SECRET_KEY=your-secure-secret-key-here \
  -p 8000:5000 \
  ai-poll-app:v1
```

**Detailed breakdown:**

| Option | Purpose | Value | Notes |
|--------|---------|-------|-------|
| `-d` | Detached mode | — | Run in background |
| `--name` | Container name | `flask-app` | Used for container identification |
| `--network` | Join network | `poll-network` | Same network as PostgreSQL |
| `-e DB_HOST` | Database hostname | `postgres-db` | Container name (Docker DNS resolves this) |
| `-e DB_PORT` | Database port | `5432` | PostgreSQL default port |
| `-e DB_NAME` | Database name | `polls` | Matches `POSTGRES_DB` from Step 2 |
| `-e DB_USER` | Database user | `admin` | Matches `POSTGRES_USER` from Step 2 |
| `-e DB_PASSWORD` | Database password | `admin123` | Matches `POSTGRES_PASSWORD` from Step 2 |
| `-e FLASK_ENV` | Flask environment | `production` | Disables debug mode |
| `-e SECRET_KEY` | Session encryption key | `your-secure-secret-key-here` | Change in production! |
| `-p 8000:5000` | Port mapping | `host:container` | Browser → 8000, App runs on 5000 |
| `ai-poll-app:v1` | Image | — | Built in Step 3 |

**Container initialization:**
1. Docker creates container from `ai-poll-app:v1` image
2. Loads environment variables
3. Executes `python app.py` (from `CMD` in Dockerfile)
4. Flask starts on `0.0.0.0:5000`
5. App connects to `postgres-db` using provided credentials
6. Database tables are created automatically

**Wait for app to initialize:**

```bash
sleep 3
```

**Verify container is running:**

```bash
docker ps
```

**Expected output:**
```
CONTAINER ID   IMAGE            COMMAND             CREATED        STATUS                 PORTS
abc123def456   ai-poll-app:v1   "python app.py"     2 seconds ago  Up 1 second (health:.. 0.0.0.0:8000->5000/tcp
xyz789abc123   postgres:15      "docker-entrypoint" 1 minute ago   Up 1 minute            0.0.0.0:5432->5432/tcp
```

---

### Verify Application is Working

#### Test 1: Health Check Endpoint

```bash
curl http://localhost:8000/health
```

**Expected response:**
```json
{"database":"connected","status":"healthy"}
```

#### Test 2: Vote Submission

```bash
curl -X POST http://localhost:8000/vote \
  -H "Content-Type: application/json" \
  -d '{"option": "yes"}'
```

**Expected response:**
```json
{"success":true,"message":"Vote recorded successfully"}
```

#### Test 3: Get Results via API

```bash
curl http://localhost:8000/api/results
```

**Expected response:**
```json
{
  "yes_count": 1,
  "no_count": 0,
  "total_votes": 1,
  "yes_percentage": 100.0,
  "no_percentage": 0.0
}
```

#### Test 4: Web Interface

Open browser and navigate to:
- **Main page:** http://localhost:8000
- **Results page:** http://localhost:8000/results

You should see:
- Voting buttons for "Yes" and "No"
- Real-time vote counts
- Vote percentages

---

## Docker Concepts Explained

### Docker Images vs Containers

**Image:**
- Blueprint for containers (like a template)
- Read-only filesystem snapshot
- Contains: base OS, dependencies, application code
- Example: `python:3.11-slim`, `postgres:15`, `ai-poll-app:v1`
- Created by: `docker build` or pulled from registry
- Stored: Docker image cache on disk

**Container:**
- Running instance of an image (like an application process)
- Writable layer on top of read-only image
- Can be started, stopped, deleted
- Has: own filesystem, network, environment variables, processes
- Created by: `docker run`
- Isolated from other containers and host OS

**Analogy:**
```
Image      = Class (template)
Container  = Object (instance)
```

### Docker Networks

**Purpose:**
- Enable containers to communicate
- Provide DNS resolution between containers
- Isolate containers from external network

**Types:**

| Type | Use Case | DNS |
|------|----------|-----|
| `bridge` | Default, container-to-container communication | Built-in DNS (container names resolve) |
| `host` | Direct access to host network (Linux only) | No isolation |
| `none` | No network access | N/A |

**In this application:**
- Creating `poll-network` (bridge) allows:
  - `flask-app` to reach `postgres-db` via hostname
  - Container names resolve to container IP automatically
  - Containers isolated from host and other networks

### Environment Variables

**Purpose:**
- Configure applications without changing code
- Pass sensitive data (credentials, API keys)
- Specify deployment environment (dev, prod)

**In Flask app:**
- `DB_HOST=postgres-db` — database hostname
- `DB_USER=admin` — database credentials
- `FLASK_ENV=production` — disable debug mode

**Set via `docker run -e`:**
```bash
docker run -e DB_HOST=postgres-db -e DB_USER=admin ...
```

**Inside container:**
- Environment variables accessible to application
- Python: `os.getenv('DB_HOST')`
- Shell: `echo $DB_HOST`

### Port Mapping

**What it does:**
- Maps port on host machine to port in container
- Allows external access to containerized services

**Syntax:**
```
-p host_port:container_port
```

**Examples:**

| Flag | Meaning |
|------|---------|
| `-p 8000:5000` | Host port 8000 → Container port 5000 |
| `-p 5432:5432` | Host port 5432 → Container port 5432 |
| `-p 9000:8080` | Host port 9000 → Container port 8080 |

**In this app:**
- Flask container runs on port 5000 internally
- Mapped to port 8000 on host machine
- Browser accesses `http://localhost:8000`
- Request routed: `localhost:8000` → `container:5000`

### Health Checks

**Purpose:**
- Monitor container health
- Docker tracks container status
- Can be used for monitoring/alerting

**In Dockerfile:**
```dockerfile
HEALTHCHECK --interval=30s --timeout=10s --start-period=10s --retries=3 \
    CMD python -c "import requests; requests.get('http://localhost:5000/health', timeout=5)" || exit 1
```

**Parameters:**
- `--interval=30s` — Check every 30 seconds
- `--timeout=10s` — Fail if check takes >10 seconds
- `--start-period=10s` — Wait 10 seconds before first check
- `--retries=3` — Mark unhealthy after 3 failed checks

**Container status:**
- `Up ... (health: starting)` — Checks in progress
- `Up ... (healthy)` — All checks passing
- `Up ... (unhealthy)` — Failed checks

---

## API Endpoints

### 1. Home Page (Vote Interface)

**Endpoint:** `GET /`

**Description:** Returns HTML form for voting

**Response:**
```html
<!DOCTYPE html>
<html>
  <head><title>AI Poll Voting Application</title></head>
  <body>
    <h1>Cast Your Vote</h1>
    <button onclick="vote('yes')">Yes</button>
    <button onclick="vote('no')">No</button>
  </body>
</html>
```

**Example:**
```bash
curl http://localhost:8000/
```

---

### 2. Submit Vote

**Endpoint:** `POST /vote`

**Request Body:**
```json
{
  "option": "yes"  // or "no"
}
```

**Response (Success):**
```json
{
  "success": true,
  "message": "Vote recorded successfully"
}
```

**Response (Error - Invalid Option):**
```json
{
  "success": false,
  "message": "Invalid vote option"
}
```
**HTTP Status:** 400

**Example:**
```bash
curl -X POST http://localhost:8000/vote \
  -H "Content-Type: application/json" \
  -d '{"option": "yes"}'
```

---

### 3. Results Page (HTML)

**Endpoint:** `GET /results`

**Description:** Returns HTML results page with charts

**Response:**
```html
<!DOCTYPE html>
<html>
  <head><title>Voting Results</title></head>
  <body>
    <h1>Voting Results</h1>
    <p>Yes: 42 votes (70%)</p>
    <p>No: 18 votes (30%)</p>
    <p>Total: 60 votes</p>
  </body>
</html>
```

**Example:**
```bash
curl http://localhost:8000/results
```

---

### 4. API Results (JSON)

**Endpoint:** `GET /api/results`

**Description:** Returns voting statistics as JSON (used by frontend for live updates)

**Response:**
```json
{
  "yes_count": 42,
  "no_count": 18,
  "total_votes": 60,
  "yes_percentage": 70.0,
  "no_percentage": 30.0
}
```

**Example:**
```bash
curl http://localhost:8000/api/results
```

---

### 5. Health Check

**Endpoint:** `GET /health`

**Description:** Application and database health status (used by Docker healthcheck)

**Response (Healthy):**
```json
{
  "status": "healthy",
  "database": "connected"
}
```
**HTTP Status:** 200

**Response (Unhealthy - DB Down):**
```json
{
  "status": "unhealthy",
  "error": "Connection refused"
}
```
**HTTP Status:** 503

**Example:**
```bash
curl http://localhost:8000/health
```

---

## Container Management

### View Running Containers

```bash
docker ps
```

**Output:**
```
CONTAINER ID   IMAGE            STATUS              NAMES
abc123def456   ai-poll-app:v1   Up 5 minutes        flask-app
xyz789abc123   postgres:15      Up 6 minutes        postgres-db
```

**Detailed output:**
```bash
docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}"
```

**Output:**
```
NAMES         IMAGE            STATUS           PORTS
flask-app     ai-poll-app:v1   Up 5 minutes     0.0.0.0:8000->5000/tcp
postgres-db   postgres:15      Up 6 minutes     0.0.0.0:5432->5432/tcp
```

---

### View All Containers (Including Stopped)

```bash
docker ps -a
```

**Output includes:**
```
STATUS
Exited (0) 2 hours ago
Exited (137) 1 hour ago
Up 5 minutes
```

---

### View Container Logs

**Real-time logs (following):**
```bash
docker logs flask-app -f
```

**Output:**
```
✓ Database connection successful!
* Serving Flask app 'app'
* Debug mode: off
* Running on all addresses (0.0.0.0)
* Running on http://127.0.0.1:5000
```

**Press `Ctrl+C` to stop following**

**Last 50 lines:**
```bash
docker logs flask-app --tail 50
```

**PostgreSQL logs:**
```bash
docker logs postgres-db
```

---

### View Container Details

**Inspect container configuration:**
```bash
docker inspect flask-app
```

**Output includes configuration, network, environment variables, etc.**

**Get specific information:**
```bash
docker inspect flask-app | grep -A 10 "Env"    # See environment variables
docker inspect flask-app | grep -A 5 "Networks"  # See network info
```

---

### Stop Containers

**Stop running container (graceful shutdown):**
```bash
docker stop flask-app
```

**Stop multiple containers:**
```bash
docker stop flask-app postgres-db
```

**Stop all running containers:**
```bash
docker stop $(docker ps -q)
```

---

### Start Stopped Containers

**Start single container:**
```bash
docker start flask-app
```

**Start multiple containers:**
```bash
docker start flask-app postgres-db
```

---

### Restart Containers

**Restart (stop then start):**
```bash
docker restart flask-app
```

---

### Remove Containers

**Remove stopped container:**
```bash
docker rm flask-app
```

**Remove running container (stops first with -f):**
```bash
docker rm -f flask-app
```

---

### Execute Commands in Running Container

**Run interactive shell:**
```bash
docker exec -it flask-app bash
```

**Inside container:**
```bash
ls -la /app          # View app files
cat /app/app.py      # View Flask code
python -c "import os; print(os.getenv('DB_HOST'))"  # Check env vars
```

**Exit shell:**
```bash
exit
```

---

## Troubleshooting

### Problem 1: Port Already in Use

**Error:**
```
Error response from daemon: ports are not available: 
exposing port TCP 0.0.0.0:8000 -> 0.0.0.0:0: 
listen tcp 0.0.0.0:8000: bind: address already in use
```

**Solution A: Find what's using the port**

```bash
# macOS/Linux
lsof -i :8000

# Windows (PowerShell)
netstat -ano | findstr :8000
```

**Solution B: Use different port**

```bash
docker run -d \
  --name flask-app \
  --network poll-network \
  -e DB_HOST=postgres-db \
  -e DB_PORT=5432 \
  -e DB_NAME=polls \
  -e DB_USER=admin \
  -e DB_PASSWORD=admin123 \
  -p 9000:5000 \  # ← Changed from 8000 to 9000
  ai-poll-app:v1
```

Then access at `http://localhost:9000`

---

### Problem 2: Container Exits Immediately

**Symptom:**
```bash
docker ps
# Empty list

docker ps -a
# Shows container with "Exited" status
```

**Diagnosis:**
```bash
docker logs flask-app
```

**Possible causes & solutions:**

**Cause A: Database connection failed**
```
Error: psycopg2.OperationalError: could not connect to server
```

**Solution:**
- Ensure PostgreSQL container is running: `docker ps | grep postgres`
- Wait longer for PostgreSQL: `sleep 10` then restart Flask
- Check database credentials match exactly

**Cause B: Application error**
```
File not found: /app/app.py
ModuleNotFoundError: No module named 'flask'
```

**Solution:**
- Rebuild image: `docker build -t ai-poll-app:v1 .`
- Verify Dockerfile is correct

---

### Problem 3: Application Can't Connect to Database

**Error in Flask logs:**
```
psycopg2.OperationalError: could not connect to server: 
Name or service not known
```

**Cause:** Flask container can't reach PostgreSQL container

**Solutions:**

**Solution A: Verify containers are on same network**

```bash
docker inspect flask-app | grep -A 10 "Networks"
docker inspect postgres-db | grep -A 10 "Networks"
```

Both should show same network (e.g., `poll-network`)

**Solution B: Verify PostgreSQL is running**

```bash
docker ps | grep postgres
docker logs postgres-db | tail -20
```

**Solution C: Verify credentials match**

In docker run command for flask-app, ensure:
- `DB_USER=admin` matches `POSTGRES_USER=admin` in postgres-db
- `DB_PASSWORD=admin123` matches `POSTGRES_PASSWORD=admin123` in postgres-db
- `DB_NAME=polls` matches `POSTGRES_DB=polls` in postgres-db

---

### Problem 4: Network Already Exists Error

**Error:**
```
Error response from daemon: network with name poll-network already exists
```

**Solution:**

```bash
# Remove old network
docker network rm poll-network

# Try again
docker network create poll-network
```

**Or just ignore it** — start.sh script checks and skips if exists

---

### Quick Diagnostic Commands

**Check everything is running:**
```bash
docker ps
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
```

**Check this application's containers:**
```bash
docker ps -a | grep -E 'flask-app|postgres-db'
```

**Check all running containers (including other apps):**
```bash
docker ps -a
```

**Test database connectivity:**
```bash
docker exec postgres-db pg_isready -U admin
```

**Test Flask connectivity:**
```bash
curl http://localhost:8000/health
```

**View logs:**
```bash
docker logs flask-app -f
docker logs postgres-db
```

---

## Advanced Topics

### Rebuilding After Code Changes

When you modify Flask code (app.py, templates, etc.):

```bash
# Use start.sh (automatically handles this)
bash start.sh

# Or manually:
docker stop flask-app
docker rm flask-app
docker build -t ai-poll-app:v1 .
docker run -d --name flask-app --network poll-network ... ai-poll-app:v1
```

---

### Custom Port Usage

If port 8000 is already in use, you can specify a different port in start.sh:

Edit `start.sh` and change:
```bash
-p 8000:5000 \
```

To:
```bash
-p 9000:5000 \
```

Then access at `http://localhost:9000`

---

### Persistent Database Volume

By default, database data is lost when container stops. To persist data:

```bash
# Create named volume
docker volume create poll-db-data

# Use volume when starting PostgreSQL
docker run -d \
  --name postgres-db \
  --network poll-network \
  -e POSTGRES_USER=admin \
  -e POSTGRES_PASSWORD=admin123 \
  -e POSTGRES_DB=polls \
  -v poll-db-data:/var/lib/postgresql/data \
  -p 5432:5432 \
  postgres:15
```

---

### Debugging with Interactive Shell

```bash
# Enter container shell
docker exec -it flask-app bash

# Inside container:
ls -la /app
cat /app/app.py
python3 -c "import flask; print(flask.__version__)"
ps aux  # See running processes

# Exit
exit
```

---

## Script Reference

### start.sh Script

**Location:** `start.sh` in project root

**Purpose:** Start application with automatic cleanup

**What it does:**
1. Cleans up old containers from THIS application only
2. Creates Docker network `poll-network`
3. Starts PostgreSQL container `postgres-db`
4. Builds Flask image `ai-poll-app:v1`
5. Starts Flask container `flask-app`
6. Shows access information

**Usage:**
```bash
bash start.sh
```

**Safe to run multiple times** — Each run creates fresh environment

**Container names it manages:**
- `flask-app` — Flask application
- `postgres-db` — PostgreSQL database
- `poll-network` — Docker network
- `ai-poll-app:v1` — Docker image

---

### stop.sh Script

**Location:** `stop.sh` in project root

**Purpose:** Stop and cleanup application resources

**What it does:**
1. Stops Flask container
2. Stops PostgreSQL container
3. Removes Flask container
4. Removes PostgreSQL container
5. Removes Docker network
6. Removes Docker image

**Usage:**
```bash
bash stop.sh
```

**Safe to run multiple times** — Skips items already removed

**Important:** Only removes this application's resources. Other Docker containers are NOT affected.

**Container names it targets:**
- `flask-app` — Only this container
- `postgres-db` — Only this container
- `poll-network` — Only this network
- `ai-poll-app:v1` — Only this image

---

## Quick Reference

### Container Lifecycle

```bash
# Create and start
docker run -d --name flask-app -p 8000:5000 ai-poll-app:v1

# View running
docker ps

# View all
docker ps -a

# View logs
docker logs flask-app

# Stop (graceful)
docker stop flask-app

# Start
docker start flask-app

# Restart
docker restart flask-app

# Delete
docker rm flask-app
```

### Image Management

```bash
# Build
docker build -t ai-poll-app:v1 .

# View images
docker images

# Remove image
docker rmi ai-poll-app:v1
```

### Network Management

```bash
# Create
docker network create poll-network

# View networks
docker network ls

# Inspect
docker network inspect poll-network

# Remove
docker network rm poll-network
```

### Useful Flags Reference

| Flag | Purpose |
|------|---------|
| `-d` | Run in background (detached) |
| `-it` | Interactive terminal |
| `-p HOST:CONTAINER` | Port mapping |
| `-e VAR=VALUE` | Environment variable |
| `--name` | Container name |
| `--network` | Join network |
| `-v HOST:CONTAINER` | Volume mount |
| `-f` | Force operation |
| `--tail N` | Show last N lines |
| `-f` (logs) | Follow logs in real-time |

### Common Workflows

**Start from scratch:**
```bash
bash start.sh
```

**Stop everything:**
```bash
bash stop.sh
```

**Check status:**
```bash
docker ps
```

**View logs:**
```bash
docker logs flask-app -f
```

**Access application:**
```
http://localhost:8000
```

---

## Summary

You now have:

1. **Two automation scripts:**
   - `start.sh` — Start application (automatic cleanup)
   - `stop.sh` — Stop application (safe cleanup, doesn't affect other apps)

2. **Complete documentation** covering:
   - Architecture and concepts
   - Step-by-step setup
   - API reference
   - Container management
   - Troubleshooting
   - Advanced topics

3. **Understanding of:**
   - How Docker works
   - Container networking
   - Environment variables
   - Port mapping
   - Health checks

4. **Safety guarantees:**
   - Scripts only target this application's containers
   - Other Docker applications unaffected
   - Safe to run multiple times

For questions, check the Troubleshooting section or use `docker inspect`, `docker logs`, and `docker exec`.

