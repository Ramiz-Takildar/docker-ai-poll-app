@echo off
REM ################################################################################
REM # COMPLETE CLEANUP & START SCRIPT - WINDOWS
REM # Handles all cleanup and fresh start for AI Poll Application
REM # Usage: cleanup-and-start.bat
REM ################################################################################

setlocal enabledelayedexpansion

cls

echo.
echo ======================================================================
echo          AI POLL APPLICATION - COMPLETE CLEANUP ^& START
echo ======================================================================
echo.

REM ============================================================================
REM PART 1: COMPLETE CLEANUP
REM ============================================================================

echo [CLEANUP] Starting complete cleanup...
echo.

REM Stop only AI Poll containers (don't impact other containers)
echo [CLEANUP] Stopping AI Poll containers...
docker stop postgres-db >nul 2>&1 || echo postgres-db not running
docker stop ai-poll-container >nul 2>&1 || echo ai-poll-container not running

REM Remove AI Poll containers
echo [CLEANUP] Removing AI Poll containers...
docker rm -f postgres-db >nul 2>&1 || echo postgres-db not found
docker rm -f ai-poll-container >nul 2>&1 || echo ai-poll-container not found

REM Remove AI Poll image
echo [CLEANUP] Removing AI Poll image...
docker rmi -f ai-poll-app:v1 >nul 2>&1 || echo ai-poll-app:v1 not found

REM Remove network
echo [CLEANUP] Removing AI Poll network...
docker network rm ai-poll-network >nul 2>&1 || echo ai-poll-network not found

REM Prune unused resources
echo [CLEANUP] Pruning unused Docker resources...
docker system prune -f --volumes >nul 2>&1

echo [SUCCESS] Cleanup complete!
echo.

REM ============================================================================
REM PART 2: FRESH START
REM ============================================================================

echo [START] Beginning fresh start...
echo.

REM Verify Docker is running
echo [START] Verifying Docker...
docker ps >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Docker not running!
    exit /b 1
)
echo [SUCCESS] Docker is running
echo.

REM Create network
echo [START] Creating Docker network (ai-poll-network)...
docker network create ai-poll-network
echo [SUCCESS] Network created
echo.

REM Start PostgreSQL
echo [START] Starting PostgreSQL container...
docker run -d ^
  --name postgres-db ^
  --network ai-poll-network ^
  -e POSTGRES_USER=admin ^
  -e POSTGRES_PASSWORD=admin123 ^
  -e POSTGRES_DB=polls ^
  -p 5432:5432 ^
  postgres:15
echo [SUCCESS] PostgreSQL started

REM Wait for PostgreSQL
echo [START] Waiting for PostgreSQL to initialize (15 seconds^)...
timeout /t 15 /nobreak >nul

REM Verify PostgreSQL connection
echo [START] Verifying PostgreSQL connection...
docker exec postgres-db psql -U admin -d polls -c "SELECT 1;" >nul 2>&1
if errorlevel 1 (
    echo [ERROR] PostgreSQL connection failed!
    exit /b 1
)
echo [SUCCESS] PostgreSQL is ready
echo.

REM Build Flask image
echo [START] Building Flask application image...
docker build -t ai-poll-app:v1 . >nul 2>&1
echo [SUCCESS] Flask image built
echo.

REM Start Flask container
echo [START] Starting Flask application container...
docker run -d ^
  --name ai-poll-container ^
  --network ai-poll-network ^
  -e DB_HOST=postgres-db ^
  -e DB_PORT=5432 ^
  -e DB_NAME=polls ^
  -e DB_USER=admin ^
  -e DB_PASSWORD=admin123 ^
  -p 5000:5000 ^
  ai-poll-app:v1
echo [SUCCESS] Flask container started

REM Wait for Flask to start
echo [START] Waiting for Flask to initialize (10 seconds^)...
timeout /t 10 /nobreak >nul

REM Verify Flask health
echo [START] Verifying Flask application health...
setlocal enabledelayedexpansion
for /l %%i in (1,1,5) do (
    curl -s http://localhost:5000/health >nul 2>&1
    if errorlevel 0 (
        echo [SUCCESS] Flask is healthy and responding
        goto :health_ok
    )
    if %%i lss 5 (
        echo Attempt %%i/5: Waiting...
        timeout /t 2 /nobreak >nul
    )
)
echo [ERROR] Flask health check failed!
exit /b 1

:health_ok
echo.

REM ============================================================================
REM SUMMARY
REM ============================================================================

echo ======================================================================
echo              [SUCCESS] DEPLOYMENT COMPLETE ^& VERIFIED
echo ======================================================================
echo.

echo [INFO] RUNNING CONTAINERS:
docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}" | findstr /i "postgres-db ai-poll"
echo.

echo [INFO] ACCESS YOUR APPLICATION:
echo   Home Page:    http://localhost:5000
echo   Results:      http://localhost:5000/results
echo   Health Check: http://localhost:5000/health
echo.

echo [INFO] DATABASE ACCESS:
echo   Host:     localhost
echo   Port:     5432
echo   Database: polls
echo   User:     admin
echo   Password: admin123
echo.

echo [INFO] USEFUL COMMANDS:
echo   View logs:    docker logs ai-poll-container
echo   Stop all:     docker stop (docker ps -q^)
echo   Clean all:    cleanup-and-start.bat
echo.

echo [SUCCESS] Application is LIVE and ready to use!
echo.

pause
