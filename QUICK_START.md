# Quick Start Guide - AI Poll Application

## 🚀 One-Command Startup

Run the application with a single command:

### Linux/macOS

```bash
# Make script executable (first time only)
chmod +x run.sh

# Start the application
./run.sh
```

### Windows

```cmd
# Start the application
run.bat
```

**That's it! Your application will be running in seconds.**

---

## 📊 Script Commands

All scripts support multiple commands:

### Start (Default)
Starts all containers and displays access information.
```bash
./run.sh start      # Linux/macOS
run.bat start       # Windows
```

### Stop
Gracefully stops all running containers.
```bash
./run.sh stop       # Linux/macOS
run.bat stop        # Windows
```

### Restart
Stops and then starts all containers.
```bash
./run.sh restart    # Linux/macOS
run.bat restart     # Windows
```

### Logs
Display output from all containers in real-time.
```bash
./run.sh logs       # Linux/macOS
run.bat logs        # Windows
```

### Status
Show detailed status of containers, network, and images.
```bash
./run.sh status     # Linux/macOS
run.bat status      # Windows
```

### Clean
Complete cleanup - removes containers, images, and network (requires confirmation).
```bash
./run.sh clean      # Linux/macOS
run.bat clean       # Windows
```

### Help
Display help information and available commands.
```bash
./run.sh help       # Linux/macOS
run.bat help        # Windows
```

---

## 🎯 Typical Workflow

### First Time Setup
```bash
./run.sh start
# Output shows access URLs and credentials
```

### View Live Logs
```bash
./run.sh logs
# Shows real-time output from PostgreSQL and Flask
```

### Check Container Status
```bash
./run.sh status
# Shows which containers are running
```

### Stop Work for the Day
```bash
./run.sh stop
# Gracefully stops all containers (data is preserved)
```

### Resume Next Day
```bash
./run.sh start
# Containers start automatically with same data
```

### Complete Cleanup (Before Reinstalling)
```bash
./run.sh clean
# Removes everything - choose 'y' when prompted
```

---

## 📍 Access Your Application

After running `./run.sh start`:

- **Home Page:** http://localhost:5000
- **Results:** http://localhost:5000/results
- **Health Check:** http://localhost:5000/health

---

## 🐳 What the Script Does

The script automates:

1. ✅ Checks Docker is installed and running
2. ✅ Creates isolated Docker network
3. ✅ Starts PostgreSQL container with database
4. ✅ Builds Flask application Docker image
5. ✅ Starts Flask application container
6. ✅ Verifies both containers are healthy
7. ✅ Displays access information

**All without manual commands!**

---

## 🔍 Troubleshooting

### Script permission denied (Linux/macOS)
```bash
chmod +x run.sh
./run.sh
```

### Docker not installed
Install Docker Desktop from https://www.docker.com/products/docker-desktop

### Ports already in use
Edit `run.sh` (or `run.bat`):
```bash
# Change these lines:
APP_PORT="5001"    # Changed from 5000
DB_PORT="5433"     # Changed from 5432
```

### Application exits immediately
```bash
# Check logs
./run.sh logs

# Restart
./run.sh restart
```

---

## 📋 Script Features

- ✅ **Idempotent:** Safe to run multiple times
- ✅ **Error Handling:** Stops on errors with clear messages
- ✅ **Container Reuse:** Doesn't recreate if already exists
- ✅ **Colored Output:** Easy-to-read feedback
- ✅ **Cross-Platform:** Works on Linux, macOS, Windows
- ✅ **No Parameters:** Simple one-command startup

---

## 💡 Pro Tips

### Development Workflow
```bash
# Start at beginning of day
./run.sh start

# View logs while coding
./run.sh logs

# Stop when taking break
./run.sh stop

# Resume later
./run.sh start

# Clean up at end of day
./run.sh clean
```

### Team Collaboration
Share `run.sh` or `run.bat` with team:
```bash
# Team members just run:
./run.sh start
# Environment is identical for everyone!
```

### Learning Docker
While containers run, explore manually:
```bash
docker ps              # See running containers
docker logs <name>     # View specific container logs
docker exec <name> bash  # Access container shell
docker network inspect ai-poll-network  # See network details
```

---

## 🚀 Next Steps

Once application is running:

1. **Test Voting:** Click "Yes" or "No" buttons
2. **View Results:** See live voting statistics
3. **Check Database:** Run `./run.sh logs` to see SQL queries
4. **Read Docs:** See main README.md for deep Docker concepts
5. **Explore Code:** Examine Dockerfile, app.py, database.py

---

## 📞 Need Help?

Check these files for more information:

- **Main README.md** - Complete Docker concepts and setup guide
- **Dockerfile** - Application build configuration (commented)
- **app.py** - Flask routes and endpoints (commented)
- **database.py** - Database connection logic (commented)

---

**Happy containerizing! 🐳**
