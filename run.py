#!/usr/bin/env python3
"""
AI Poll Voting Application - Docker Setup Script (Python)

Cross-platform Python alternative to shell scripts.
Works on Linux, macOS, and Windows without WSL.

Usage:
    python run.py [command]

Commands:
    start       Start all containers (default)
    stop        Stop all containers
    restart     Restart all containers
    logs        Show container logs
    status      Show container status
    clean       Stop and remove all containers/images
    help        Show help message

Examples:
    python run.py start          # Start the application
    python run.py logs           # View logs
    python run.py stop           # Stop containers
    python run.py clean          # Complete cleanup
"""

import os
import sys
import subprocess
import time
import platform
from typing import Optional, Tuple

# ============================================================================
# CONFIGURATION
# ============================================================================

NETWORK_NAME = "ai-poll-network"
DB_CONTAINER = "postgres-db"
DB_IMAGE = "postgres:15"
APP_CONTAINER = "ai-poll-container"
APP_IMAGE = "ai-poll-app:v1"
APP_PORT = "5000"
DB_PORT = "5432"

DB_USER = "admin"
DB_PASSWORD = "admin123"
DB_NAME = "polls"

# ============================================================================
# COLOR CODES (compatible with Windows 10+)
# ============================================================================

class Colors:
    """ANSI color codes for terminal output"""
    BLUE = '\033[94m'
    GREEN = '\033[92m'
    YELLOW = '\033[93m'
    RED = '\033[91m'
    BOLD = '\033[1m'
    END = '\033[0m'

    @staticmethod
    def disable():
        """Disable colors for Windows Console (if needed)"""
        for attr in dir(Colors):
            if not attr.startswith('_'):
                setattr(Colors, attr, '')

# Detect if running on Windows and disable colors if needed
if platform.system() == 'Windows':
    # Windows 10+ supports ANSI colors in console if enabled
    # But we'll try and fall back to no colors if needed
    pass

# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================

def print_info(msg: str) -> None:
    """Print info message"""
    print(f"{Colors.BLUE}ℹ️  {msg}{Colors.END}")

def print_success(msg: str) -> None:
    """Print success message"""
    print(f"{Colors.GREEN}✓ {msg}{Colors.END}")

def print_error(msg: str) -> None:
    """Print error message"""
    print(f"{Colors.RED}✗ {msg}{Colors.END}")

def print_warning(msg: str) -> None:
    """Print warning message"""
    print(f"{Colors.YELLOW}⚠ {msg}{Colors.END}")

def print_section(title: str) -> None:
    """Print section header"""
    print()
    print(f"{Colors.BLUE}{'='*50}{Colors.END}")
    print(f"{Colors.BLUE}  {title}{Colors.END}")
    print(f"{Colors.BLUE}{'='*50}{Colors.END}")

def run_command(cmd: list, capture: bool = False) -> Tuple[int, Optional[str]]:
    """
    Execute shell command and return exit code and output.
    
    Args:
        cmd: Command as list of strings
        capture: If True, capture and return output
    
    Returns:
        Tuple of (exit_code, output)
    """
    try:
        if capture:
            result = subprocess.run(cmd, capture_output=True, text=True, timeout=30)
            return result.returncode, result.stdout + result.stderr
        else:
            result = subprocess.run(cmd, timeout=30)
            return result.returncode, None
    except subprocess.TimeoutExpired:
        print_error(f"Command timed out: {' '.join(cmd)}")
        return 1, None
    except FileNotFoundError:
        print_error(f"Command not found: {cmd[0]}")
        return 1, None
    except Exception as e:
        print_error(f"Error running command: {e}")
        return 1, None

def check_docker() -> bool:
    """Check if Docker is installed and running"""
    print_info("Checking Docker installation...")
    
    # Check if docker command exists
    exit_code, output = run_command(["docker", "--version"], capture=True)
    if exit_code != 0:
        print_error("Docker is not installed. Please install Docker first.")
        print("Visit: https://www.docker.com/products/docker-desktop")
        return False
    
    # Check if Docker daemon is running
    exit_code, _ = run_command(["docker", "ps"], capture=True)
    if exit_code != 0:
        print_error("Docker daemon is not running. Please start Docker.")
        return False
    
    version = output.strip().split('\n')[0] if output else "Unknown"
    print_success(f"Docker is running ({version})")
    return True

def create_network() -> bool:
    """Create Docker network if it doesn't exist"""
    print_info("Checking Docker network...")
    
    # Check if network exists
    exit_code, output = run_command(
        ["docker", "network", "ls", "--format", "{{.Name}}"],
        capture=True
    )
    
    if exit_code == 0 and NETWORK_NAME in output:
        print_success(f"Network '{NETWORK_NAME}' already exists")
        return True
    
    print_info(f"Creating network '{NETWORK_NAME}'...")
    exit_code, _ = run_command(["docker", "network", "create", NETWORK_NAME])
    
    if exit_code != 0:
        print_error("Failed to create network")
        return False
    
    print_success("Network created")
    return True

def is_container_running(container_name: str) -> bool:
    """Check if container is running"""
    exit_code, output = run_command(
        ["docker", "ps", "--filter", f"name={container_name}",
         "--filter", "status=running", "--quiet"],
        capture=True
    )
    return exit_code == 0 and bool(output.strip())

def container_exists(container_name: str) -> bool:
    """Check if container exists (running or stopped)"""
    exit_code, output = run_command(
        ["docker", "ps", "-a", "--filter", f"name={container_name}", "--quiet"],
        capture=True
    )
    return exit_code == 0 and bool(output.strip())

def start_postgres() -> bool:
    """Start PostgreSQL container"""
    print_info("Checking PostgreSQL container...")
    
    if is_container_running(DB_CONTAINER):
        print_success("PostgreSQL container is already running")
        return True
    
    if container_exists(DB_CONTAINER):
        print_info("Starting stopped PostgreSQL container...")
        exit_code, _ = run_command(["docker", "start", DB_CONTAINER])
        if exit_code != 0:
            print_error("Failed to start PostgreSQL container")
            return False
        print_success("PostgreSQL container started")
    else:
        print_info("Creating and starting PostgreSQL container...")
        cmd = [
            "docker", "run", "-d",
            "--name", DB_CONTAINER,
            "--network", NETWORK_NAME,
            "-e", f"POSTGRES_USER={DB_USER}",
            "-e", f"POSTGRES_PASSWORD={DB_PASSWORD}",
            "-e", f"POSTGRES_DB={DB_NAME}",
            "-p", f"{DB_PORT}:5432",
            DB_IMAGE
        ]
        exit_code, _ = run_command(cmd)
        if exit_code != 0:
            print_error("Failed to create PostgreSQL container")
            return False
        print_success("PostgreSQL container created and started")
    
    # Wait for PostgreSQL to initialize
    print_info("Waiting for PostgreSQL to initialize (10 seconds)...")
    time.sleep(10)
    print_success("PostgreSQL is ready")
    return True

def build_app_image() -> bool:
    """Build Flask application Docker image"""
    print_info("Checking Flask application image...")
    
    # Check if app directory exists
    if not os.path.isdir("app"):
        print_error("app/ directory not found. Make sure you're in the project root directory.")
        return False
    
    # Check if image already exists
    exit_code, output = run_command(
        ["docker", "images", "--quiet", APP_IMAGE],
        capture=True
    )
    
    if exit_code == 0 and output.strip():
        print_warning(f"Image '{APP_IMAGE}' already exists. Rebuilding...")
    else:
        print_info("Building Flask application image...")
    
    print_info("Running docker build...")
    exit_code, _ = run_command(["docker", "build", "-t", APP_IMAGE, "."])
    
    if exit_code != 0:
        print_error("Failed to build Flask application image")
        return False
    
    print_success(f"Flask application image built: {APP_IMAGE}")
    return True

def start_app() -> bool:
    """Start Flask application container"""
    print_info("Checking Flask application container...")
    
    if is_container_running(APP_CONTAINER):
        print_success("Flask application container is already running")
        return True
    
    if container_exists(APP_CONTAINER):
        print_info("Starting stopped Flask application container...")
        exit_code, _ = run_command(["docker", "start", APP_CONTAINER])
        if exit_code != 0:
            print_error("Failed to start Flask application container")
            return False
        print_success("Flask application container started")
    else:
        print_info("Creating and starting Flask application container...")
        cmd = [
            "docker", "run", "-d",
            "--name", APP_CONTAINER,
            "--network", NETWORK_NAME,
            "-e", f"DB_HOST={DB_CONTAINER}",
            "-e", f"DB_PORT={DB_PORT}",
            "-e", f"DB_NAME={DB_NAME}",
            "-e", f"DB_USER={DB_USER}",
            "-e", f"DB_PASSWORD={DB_PASSWORD}",
            "-p", f"{APP_PORT}:5000",
            APP_IMAGE
        ]
        exit_code, _ = run_command(cmd)
        if exit_code != 0:
            print_error("Failed to create Flask application container")
            return False
        print_success("Flask application container created and started")
    
    print_info("Waiting for Flask application to initialize (5 seconds)...")
    time.sleep(5)
    return True

def verify_containers() -> bool:
    """Verify containers are healthy"""
    print_info("Verifying container health...")
    
    if not is_container_running(DB_CONTAINER):
        print_error("PostgreSQL container is not running")
        return False
    print_success("PostgreSQL container is running")
    
    if not is_container_running(APP_CONTAINER):
        print_error("Flask application container is not running")
        return False
    print_success("Flask application container is running")
    
    return True

def show_access_info() -> None:
    """Display access information"""
    print_section("🚀 Application Ready!")
    
    print()
    print(f"{Colors.GREEN}Access your application:{Colors.END}")
    print(f"{Colors.BLUE}  Web Interface:{Colors.END} http://localhost:{APP_PORT}")
    print(f"{Colors.BLUE}  Results Page:{Colors.END} http://localhost:{APP_PORT}/results")
    print(f"{Colors.BLUE}  Health Check:{Colors.END} http://localhost:{APP_PORT}/health")
    print()
    print(f"{Colors.GREEN}Database Access:{Colors.END}")
    print(f"{Colors.BLUE}  Host:{Colors.END} localhost")
    print(f"{Colors.BLUE}  Port:{Colors.END} {DB_PORT}")
    print(f"{Colors.BLUE}  Database:{Colors.END} {DB_NAME}")
    print(f"{Colors.BLUE}  Username:{Colors.END} {DB_USER}")
    print(f"{Colors.BLUE}  Password:{Colors.END} {DB_PASSWORD}")
    print()
    print(f"{Colors.GREEN}Useful Commands:{Colors.END}")
    print(f"{Colors.BLUE}  View logs:{Colors.END}        python run.py logs")
    print(f"{Colors.BLUE}  Stop containers:{Colors.END}  python run.py stop")
    print(f"{Colors.BLUE}  Restart containers:{Colors.END} python run.py restart")
    print(f"{Colors.BLUE}  Show status:{Colors.END}      python run.py status")
    print(f"{Colors.BLUE}  Complete cleanup:{Colors.END} python run.py clean")
    print()

# ============================================================================
# COMMAND HANDLERS
# ============================================================================

def cmd_start() -> None:
    """Start all containers"""
    print_section("🐳 Starting AI Poll Application")
    
    if not check_docker():
        return
    
    if not create_network():
        return
    
    if not start_postgres():
        return
    
    if not build_app_image():
        return
    
    if not start_app():
        return
    
    if not verify_containers():
        return
    
    show_access_info()

def cmd_stop() -> None:
    """Stop all containers"""
    print_section("🛑 Stopping Containers")
    
    if is_container_running(APP_CONTAINER):
        print_info("Stopping Flask application container...")
        run_command(["docker", "stop", APP_CONTAINER])
        print_success("Flask application container stopped")
    else:
        print_warning("Flask application container is not running")
    
    if is_container_running(DB_CONTAINER):
        print_info("Stopping PostgreSQL container...")
        run_command(["docker", "stop", DB_CONTAINER])
        print_success("PostgreSQL container stopped")
    else:
        print_warning("PostgreSQL container is not running")
    
    print_success("All containers stopped")

def cmd_restart() -> None:
    """Restart all containers"""
    print_section("🔄 Restarting Containers")
    cmd_stop()
    print()
    cmd_start()

def cmd_logs() -> None:
    """Show container logs"""
    print_section("📋 Container Logs")
    
    print()
    print(f"{Colors.BLUE}PostgreSQL Logs:{Colors.END}")
    print("─" * 50)
    run_command(["docker", "logs", DB_CONTAINER])
    
    print()
    print()
    print(f"{Colors.BLUE}Flask Application Logs:{Colors.END}")
    print("─" * 50)
    run_command(["docker", "logs", APP_CONTAINER])

def cmd_status() -> None:
    """Show container status"""
    print_section("📊 Container Status")
    
    print()
    print(f"{Colors.BLUE}Network Status:{Colors.END}")
    run_command(["docker", "network", "ls", "--filter", f"name={NETWORK_NAME}"])
    
    print()
    print(f"{Colors.BLUE}Container Status:{Colors.END}")
    run_command([
        "docker", "ps", "-a",
        "--filter", f"name={DB_CONTAINER}",
        "--filter", f"name={APP_CONTAINER}",
        "--format", "table {{.Names}}\\t{{.Status}}\\t{{.Ports}}"
    ])
    
    print()
    print(f"{Colors.BLUE}Image Status:{Colors.END}")
    run_command([
        "docker", "images",
        "--filter", f"reference={APP_IMAGE}",
        "--format", "table {{.Repository}}:{{.Tag}}\\t{{.Size}}"
    ])

def cmd_clean() -> None:
    """Clean up all containers and images"""
    print_section("🧹 Cleaning Up")
    
    response = input(
        f"{Colors.YELLOW}⚠ This will stop and remove all containers and images. "
        f"Continue? (y/n): {Colors.END}"
    )
    
    if response.lower() != 'y':
        print_warning("Cleanup cancelled")
        return
    
    if is_container_running(APP_CONTAINER):
        print_info("Stopping Flask application container...")
        run_command(["docker", "stop", APP_CONTAINER])
    
    if is_container_running(DB_CONTAINER):
        print_info("Stopping PostgreSQL container...")
        run_command(["docker", "stop", DB_CONTAINER])
    
    if container_exists(APP_CONTAINER):
        print_info("Removing Flask application container...")
        run_command(["docker", "rm", APP_CONTAINER])
        print_success("Flask application container removed")
    
    if container_exists(DB_CONTAINER):
        print_info("Removing PostgreSQL container...")
        run_command(["docker", "rm", DB_CONTAINER])
        print_success("PostgreSQL container removed")
    
    exit_code, output = run_command(
        ["docker", "images", "--quiet", APP_IMAGE],
        capture=True
    )
    if exit_code == 0 and output.strip():
        print_info("Removing Flask application image...")
        run_command(["docker", "rmi", APP_IMAGE])
        print_success("Flask application image removed")
    
    exit_code, output = run_command(
        ["docker", "network", "ls", "--quiet", "--filter", f"name={NETWORK_NAME}"],
        capture=True
    )
    if exit_code == 0 and output.strip():
        print_info("Removing network...")
        run_command(["docker", "network", "rm", NETWORK_NAME])
        print_success("Network removed")
    
    print_success("Cleanup complete!")

def show_help() -> None:
    """Show help message"""
    print()
    print(f"{Colors.BOLD}AI Poll Voting Application - Docker Setup Script{Colors.END}")
    print()
    print("Usage: python run.py [command]")
    print()
    print("Commands:")
    print(f"  {Colors.GREEN}start{Colors.END}       Start all containers (default)")
    print(f"  {Colors.GREEN}stop{Colors.END}        Stop all containers")
    print(f"  {Colors.GREEN}restart{Colors.END}     Restart all containers")
    print(f"  {Colors.GREEN}logs{Colors.END}        Show container logs")
    print(f"  {Colors.GREEN}status{Colors.END}      Show container status")
    print(f"  {Colors.GREEN}clean{Colors.END}       Stop and remove all containers/images")
    print(f"  {Colors.GREEN}help{Colors.END}        Show this help message")
    print()
    print("Examples:")
    print("  python run.py start          # Start the application")
    print("  python run.py logs           # View application logs")
    print("  python run.py stop           # Stop containers")
    print("  python run.py clean          # Complete cleanup")
    print()

# ============================================================================
# MAIN
# ============================================================================

def main() -> None:
    """Main entry point"""
    command = sys.argv[1].lower() if len(sys.argv) > 1 else "start"
    
    commands = {
        "start": cmd_start,
        "stop": cmd_stop,
        "restart": cmd_restart,
        "logs": cmd_logs,
        "status": cmd_status,
        "clean": cmd_clean,
        "help": show_help,
    }
    
    if command in commands:
        commands[command]()
    else:
        print_error(f"Unknown command: {command}")
        print()
        show_help()
        sys.exit(1)

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print()
        print_warning("Script interrupted by user")
        sys.exit(0)
    except Exception as e:
        print()
        print_error(f"Unexpected error: {e}")
        sys.exit(1)
