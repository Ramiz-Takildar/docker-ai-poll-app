# 🚀 COMPLETE CLEANUP & START GUIDE

## Quick Reference

### Linux/macOS
```bash
bash cleanup-and-start.sh
```

### Windows
```cmd
cleanup-and-start.bat
```

### Python (Any OS)
```bash
python run.py clean
python run.py start
```

---

## What These Commands Do

### Cleanup Command - Removes Everything

Deletes ALL related Docker resources:

```
✓ Stops all running containers
✓ Removes postgres-db container
✓ Removes ai-poll-container container  
✓ Removes ai-poll-app:v1 image
✓ Removes ai-poll-network network
✓ Prunes all unused Docker volumes
✓ Cleans up dangling resources
```

### Start Command - Full Fresh Deployment

After cleanup, automatically:

```
✓ Verifies Docker is running
✓ Creates brand new Docker network
✓ Starts PostgreSQL container (fresh)
✓ Waits 15 seconds for PostgreSQL to initialize
✓ Verifies PostgreSQL connection
✓ Builds Flask application image
✓ Starts Flask container (fresh)
✓ Waits 10 seconds for Flask to initialize
✓ Verifies Flask health endpoint
✓ Shows deployment summary
✓ Displays access URLs
```

---

## Usage Examples

### Complete Fresh Start (Recommended)

```bash
# Linux/macOS
bash cleanup-and-start.sh

# Windows
cleanup-and-start.bat

# Python (Any OS)
python run.py clean && python run.py start
```

This:
1. ✅ Removes all old containers/images/networks
2. ✅ Starts everything fresh
3. ✅ Verifies each step
4. ✅ Shows you the result

### Just Cleanup

```bash
# Linux/macOS
docker stop $(docker ps -q)
docker rm postgres-db ai-poll-container
docker rmi ai-poll-app:v1
docker network rm ai-poll-network
docker system prune -f

# Or use the script
bash cleanup-and-start.sh  # First half only

# Windows
cleanup-and-start.bat  # First half only
```

### Just Start

```bash
# If you already cleaned up, use:
./run.sh start          # Linux/macOS
run.bat start           # Windows
python run.py start     # Any OS
```

---

## Typical Workflow

### First Time Setup
```bash
bash cleanup-and-start.sh
```

### Development Work
```bash
# Application is running, make changes and test
docker logs ai-poll-container  # Check logs
curl http://localhost:5000/    # Test app
```

### End of Day Cleanup
```bash
bash cleanup-and-start.sh  # Clean everything
```

### Next Day Fresh Start
```bash
bash cleanup-and-start.sh  # Run again
# Everything is fresh, nothing leftover
```

---

## What Gets Cleaned Up

### Containers Removed
- ✓ postgres-db (PostgreSQL database)
- ✓ ai-poll-container (Flask application)

### Images Removed
- ✓ ai-poll-app:v1 (Flask image)

### Networks Removed
- ✓ ai-poll-network (Bridge network)

### Volumes Cleaned
- ✓ All unused Docker volumes
- ✓ All dangling images
- ✓ All unused networks

### What's Preserved
- ✓ Other containers/images/networks untouched
- ✓ Your project files remain
- ✓ Source code unchanged

---

## Verification Steps Included

The start command automatically:

1. **Docker Check**
   ```bash
   docker ps  # Verifies Docker is running
   ```

2. **Network Creation**
   ```bash
   docker network create ai-poll-network
   ```

3. **PostgreSQL Health**
   ```bash
   docker exec postgres-db psql -U admin -d polls -c "SELECT 1;"
   ```

4. **Flask Health**
   ```bash
   curl http://localhost:5000/health
   ```

If any step fails, the script stops with clear error message.

---

## Access After Successful Start

Once the script completes:

### Web Interface
```
Home Page:    http://localhost:5000
Results:      http://localhost:5000/results
Health:       http://localhost:5000/health
```

### Database
```
Host:     localhost
Port:     5432
Database: polls
User:     admin
Password: admin123
```

### Containers Running
```bash
docker ps  # Shows postgres-db and ai-poll-container
```

---

## Troubleshooting

### "Docker not running"
**Solution:** Start Docker Desktop or Docker daemon

### "Address already in use"
**Solution:** Run cleanup first to remove old containers
```bash
bash cleanup-and-start.sh
```

### "PostgreSQL connection failed"
**Solution:** Script waits 15 seconds, may need more time
- Wait manually: `sleep 20`
- Check logs: `docker logs postgres-db`

### "Flask health check failed"
**Solution:** Check Flask logs
```bash
docker logs ai-poll-container
```

### "Database doesn't exist"
**Solution:** Use cleanup-and-start to get fresh deployment
```bash
bash cleanup-and-start.sh
```

---

## What About My Data?

### During Cleanup
```
❌ All votes are deleted (they were in containers)
❌ All database data is removed
❌ Fresh start = empty database
```

### If You Want to Keep Data
```bash
# DON'T use cleanup-and-start.sh
# Instead just stop containers:
docker stop postgres-db ai-poll-container

# Later, restart them:
docker start postgres-db ai-poll-container
```

---

## Comparison: Different Start Methods

| Method | What It Does | Use When |
|--------|------------|----------|
| `cleanup-and-start.sh` | Removes everything, starts fresh | You want complete reset |
| `run.sh start` | Reuses containers/images | Quick restart |
| `run.sh stop` | Stops without removing | Taking a break |
| `docker stop` | Manual stop | One container |

---

## Script Features

### Automatic Handling
- ✅ Creates network automatically
- ✅ Waits for PostgreSQL to initialize
- ✅ Verifies connections
- ✅ Shows colored output
- ✅ Clear progress messages
- ✅ Error detection and reporting

### Safety
- ✅ Asks for confirmation (Windows only)
- ✅ Stops on errors
- ✅ Clear error messages
- ✅ Doesn't affect other containers
- ✅ Checks Docker is running

### Convenience
- ✅ One command does everything
- ✅ No manual waiting needed
- ✅ Shows access URLs
- ✅ Shows running containers
- ✅ Shows database credentials
- ✅ Shows useful commands

---

## Complete Cleanup Example

```bash
$ bash cleanup-and-start.sh

╔════════════════════════════════════════════════════════════════╗
║         AI POLL APPLICATION - COMPLETE CLEANUP & START         ║
╚════════════════════════════════════════════════════════════════╝

[CLEANUP] Starting complete cleanup...

[CLEANUP] Stopping all containers...
[CLEANUP] Removing AI Poll containers...
[CLEANUP] Removing AI Poll image...
[CLEANUP] Removing AI Poll network...
[CLEANUP] Pruning unused Docker resources...
✓ Cleanup complete!

[START] Beginning fresh start...

[START] Verifying Docker...
✓ Docker is running

[START] Creating Docker network (ai-poll-network)...
✓ Network created

[START] Starting PostgreSQL container...
✓ PostgreSQL started

[START] Waiting for PostgreSQL to initialize (15 seconds)...
[START] Verifying PostgreSQL connection...
✓ PostgreSQL is ready

[START] Building Flask application image...
✓ Flask image built

[START] Starting Flask application container...
✓ Flask container started

[START] Waiting for Flask to initialize (10 seconds)...
[START] Verifying Flask application health...
✓ Flask is healthy and responding

╔════════════════════════════════════════════════════════════════╗
             ✓ DEPLOYMENT COMPLETE & VERIFIED
╚════════════════════════════════════════════════════════════════╝

RUNNING CONTAINERS:
postgres-db        postgres:15        Up 20 seconds        0.0.0.0:5432->5432/tcp
ai-poll-container  ai-poll-app:v1    Up 5 seconds         0.0.0.0:5000->5000/tcp

ACCESS YOUR APPLICATION:
  🏠 Home Page:    http://localhost:5000
  📊 Results:      http://localhost:5000/results
  💚 Health Check: http://localhost:5000/health

DATABASE ACCESS:
  Host:     localhost
  Port:     5432
  Database: polls
  User:     admin
  Password: admin123

USEFUL COMMANDS:
  View logs:    docker logs ai-poll-container
  Stop all:     docker stop $(docker ps -q)
  Clean all:    bash cleanup-and-start.sh

✓ Application is LIVE and ready to use!
```

---

## Final Recommendation

**Use this workflow:**

```bash
# First time
bash cleanup-and-start.sh

# During development
# Make changes, test, debug

# End of day
bash cleanup-and-start.sh

# Next day
bash cleanup-and-start.sh

# Result: Fresh, working application every time!
```

---

## No More Hassle!

✅ One command does everything  
✅ No manual steps needed  
✅ No leftover containers  
✅ No leftover images  
✅ Fresh start every time  
✅ Automated verification  
✅ Clear output  

**Just run: `bash cleanup-and-start.sh`**

Done! 🎉

