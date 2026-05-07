# Script Selection Guide

## 🚀 Choose Your Script

Three scripts are provided. Pick one based on your operating system:

### 1. **Linux / macOS** → Use `run.sh`
```bash
chmod +x run.sh    # First time only
./run.sh start
```

**Advantages:**
- Native shell script (zero dependencies)
- Fastest execution
- Full color support
- Recommended for Linux/macOS users

---

### 2. **Windows** → Use `run.bat`
```cmd
run.bat start
```

**Advantages:**
- Native Windows batch script
- No WSL required
- Works in Command Prompt or PowerShell
- Windows-optimized

---

### 3. **Any OS (Python)** → Use `run.py`
```bash
python run.py start      # Linux/macOS
python run.py start      # Windows
```

**Advantages:**
- Works on all platforms identically
- Requires Python 3.6+
- Same commands across all OS
- Good for team environments

---

## 📊 Comparison

| Feature | run.sh | run.bat | run.py |
|---------|--------|---------|--------|
| **OS Support** | Linux/macOS | Windows | All |
| **Dependencies** | None | None | Python 3.6+ |
| **Execution** | Fastest | Fast | Medium |
| **Colors** | Yes | Yes | Yes |
| **Complexity** | Simple | Moderate | Medium |
| **Recommended** | Linux/macOS | Windows | Teams |

---

## ✅ Quick Decision

**On Linux/macOS?**
→ Use `run.sh`

**On Windows?**
→ Use `run.bat`

**Using both?**
→ Use `run.py`

**Team with mixed OS?**
→ Use `run.py` for consistency

---

## 🎯 All Scripts Support Same Commands

Regardless of which script you choose, all commands work identically:

```bash
# Start application
./run.sh start          # Linux/macOS
run.bat start           # Windows
python run.py start     # Any OS

# View logs
./run.sh logs           # Linux/macOS
run.bat logs            # Windows
python run.py logs      # Any OS

# Stop containers
./run.sh stop           # Linux/macOS
run.bat stop            # Windows
python run.py stop      # Any OS

# See status
./run.sh status         # Linux/macOS
run.bat status          # Windows
python run.py status    # Any OS

# Complete cleanup
./run.sh clean          # Linux/macOS
run.bat clean           # Windows
python run.py clean     # Any OS

# Get help
./run.sh help           # Linux/macOS
run.bat help            # Windows
python run.py help      # Any OS
```

---

## 🚀 First Time Setup

### Linux/macOS
```bash
# Make executable
chmod +x run.sh

# Run
./run.sh
```

### Windows
```cmd
# Just run (no permissions needed)
run.bat
```

### Any OS with Python
```bash
# Just run
python run.py
```

---

## 📋 What Happens When You Run `start`

All scripts do the exact same thing:

1. ✅ Check Docker is installed and running
2. ✅ Create Docker network
3. ✅ Start PostgreSQL container
4. ✅ Build Flask application image
5. ✅ Start Flask application container
6. ✅ Verify containers are healthy
7. ✅ Display access information

**Result:** Application ready at http://localhost:5000

---

## 💾 File Sizes

```
run.sh   - 14 KB  (Bash script)
run.bat  - 12 KB  (Batch script)
run.py   - 18 KB  (Python script)
```

All lightweight and efficient.

---

## ⚡ Quick Start Cheat Sheet

**Linux/macOS:**
```bash
chmod +x run.sh
./run.sh
```

**Windows:**
```cmd
run.bat
```

**Any OS:**
```bash
python run.py
```

---

## 🔧 Troubleshooting

### "Permission denied" on Linux/macOS
```bash
chmod +x run.sh
./run.sh
```

### "run.bat not found" on Windows
Make sure you're in the project directory where `run.bat` is located.

### Python script won't run
```bash
# Use full python path
python3 run.py          # macOS/Linux
python run.py           # Windows
```

---

## 📝 Which One to Share?

**Sharing with team:**
- **Mixed OS team** → Share all 3 scripts
- **Linux-only team** → Share `run.sh`
- **Windows-only team** → Share `run.bat`
- **Python-centric team** → Share `run.py`

All scripts can coexist in the same directory without conflicts.

---

## 🎓 Learning Which Script

Each script is well-commented:
- **run.sh** - Learn bash scripting
- **run.bat** - Learn Windows batch
- **run.py** - Learn Python subprocess/Docker automation

Great for learning scripting on your OS!

---

**Pick one and start containerizing! 🐳**
