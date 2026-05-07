@echo off
REM ################################################################################
REM # AI Poll Voting Application - Complete Docker Setup Script (Windows)
REM # 
REM # This script automates the entire setup process:
REM # - Creates Docker network
REM # - Starts PostgreSQL container
REM # - Builds Flask application image
REM # - Runs Flask application container
REM # - Displays access information
REM #
REM # Usage: run.bat [command]
REM # Commands:
REM #   start     - Start all containers (default)
REM #   stop      - Stop all containers
REM #   restart   - Restart all containers
REM #   logs      - Show container logs
REM #   clean     - Stop and remove all containers/images
REM #   status    - Show container status
REM #
REM # Example:
REM #   run.bat start          :: Start the application
REM #   run.bat logs           :: View logs
REM #   run.bat stop           :: Stop the application
REM #   run.bat clean          :: Complete cleanup
REM #
REM ################################################################################

setlocal enabledelayedexpansion

REM Configuration variables
set NETWORK_NAME=ai-poll-network
set DB_CONTAINER=postgres-db
set DB_IMAGE=postgres:15
set APP_CONTAINER=ai-poll-container
set APP_IMAGE=ai-poll-app:v1
set APP_PORT=5000
set DB_PORT=5432

REM Database credentials
set DB_USER=admin
set DB_PASSWORD=admin123
set DB_NAME=polls

REM Color codes (Windows console has limited color support)
REM We'll use simple formatting instead

REM Function labels - called as :function_name
goto parse_command

:print_info
echo [INFO] %~1
goto :eof

:print_success
echo [SUCCESS] %~1
goto :eof

:print_error
echo [ERROR] %~1
goto :eof

:print_warning
echo [WARNING] %~1
goto :eof

:print_section
echo.
echo ===============================================
echo %~1
echo ===============================================
goto :eof

:check_docker
echo [INFO] Checking Docker installation...

docker --version >nul 2>&1
if !errorlevel! neq 0 (
    call :print_error Docker is not installed. Please install Docker Desktop.
    echo Visit: https://www.docker.com/products/docker-desktop
    exit /b 1
)

docker ps >nul 2>&1
if !errorlevel! neq 0 (
    call :print_error Docker daemon is not running. Please start Docker Desktop.
    exit /b 1
)

for /f "tokens=*" %%i in ('docker --version') do set DOCKER_VERSION=%%i
call :print_success Docker is running ^(!DOCKER_VERSION!^)
goto :eof

:create_network
echo [INFO] Checking Docker network...

docker network ls | find "%NETWORK_NAME%" >nul
if !errorlevel! equ 0 (
    call :print_success Network '%NETWORK_NAME%' already exists
    goto :eof
)

echo [INFO] Creating network '%NETWORK_NAME%'...
docker network create %NETWORK_NAME%
call :print_success Network created
goto :eof

:is_container_running
REM %~1 is container name
docker ps --filter "name=%~1" --filter "status=running" --quiet | find "." >nul
if !errorlevel! equ 0 (
    set CONTAINER_RUNNING=1
) else (
    set CONTAINER_RUNNING=0
)
goto :eof

:start_postgres
echo [INFO] Checking PostgreSQL container...

call :is_container_running %DB_CONTAINER%
if !CONTAINER_RUNNING! equ 1 (
    call :print_success PostgreSQL container is already running
    goto :eof
)

REM Check if container exists but is stopped
docker ps -a --filter "name=%DB_CONTAINER%" --quiet | find "." >nul
if !errorlevel! equ 0 (
    echo [INFO] Starting stopped PostgreSQL container...
    docker start %DB_CONTAINER%
    call :print_success PostgreSQL container started
) else (
    echo [INFO] Creating and starting PostgreSQL container...
    docker run -d ^
        --name %DB_CONTAINER% ^
        --network %NETWORK_NAME% ^
        -e POSTGRES_USER=%DB_USER% ^
        -e POSTGRES_PASSWORD=%DB_PASSWORD% ^
        -e POSTGRES_DB=%DB_NAME% ^
        -p %DB_PORT%:5432 ^
        %DB_IMAGE%
    call :print_success PostgreSQL container created and started
)

REM Wait for PostgreSQL to be ready
echo [INFO] Waiting for PostgreSQL to initialize (10 seconds^)...
timeout /t 10 /nobreak >nul
call :print_success PostgreSQL is ready
goto :eof

:build_app_image
echo [INFO] Checking Flask application image...

docker images --quiet %APP_IMAGE% | find "." >nul
if !errorlevel! equ 0 (
    call :print_warning Image '%APP_IMAGE%' already exists. Rebuilding...
) else (
    echo [INFO] Building Flask application image...
)

if not exist "app" (
    call :print_error app/ directory not found. Make sure you're in the project root directory.
    exit /b 1
)

echo [INFO] Running docker build...
docker build -t %APP_IMAGE% . --progress=plain
call :print_success Flask application image built: %APP_IMAGE%
goto :eof

:start_app
echo [INFO] Checking Flask application container...

call :is_container_running %APP_CONTAINER%
if !CONTAINER_RUNNING! equ 1 (
    call :print_success Flask application container is already running
    goto :eof
)

REM Check if container exists but is stopped
docker ps -a --filter "name=%APP_CONTAINER%" --quiet | find "." >nul
if !errorlevel! equ 0 (
    echo [INFO] Starting stopped Flask application container...
    docker start %APP_CONTAINER%
    call :print_success Flask application container started
) else (
    echo [INFO] Creating and starting Flask application container...
    docker run -d ^
        --name %APP_CONTAINER% ^
        --network %NETWORK_NAME% ^
        -e DB_HOST=%DB_CONTAINER% ^
        -e DB_PORT=%DB_PORT% ^
        -e DB_NAME=%DB_NAME% ^
        -e DB_USER=%DB_USER% ^
        -e DB_PASSWORD=%DB_PASSWORD% ^
        -p %APP_PORT%:5000 ^
        %APP_IMAGE%
    call :print_success Flask application container created and started
)

echo [INFO] Waiting for Flask application to initialize (5 seconds^)...
timeout /t 5 /nobreak >nul
goto :eof

:verify_containers
echo [INFO] Verifying container health...

call :is_container_running %DB_CONTAINER%
if !CONTAINER_RUNNING! equ 0 (
    call :print_error PostgreSQL container is not running
    exit /b 1
)
call :print_success PostgreSQL container is running

call :is_container_running %APP_CONTAINER%
if !CONTAINER_RUNNING! equ 0 (
    call :print_error Flask application container is not running
    exit /b 1
)
call :print_success Flask application container is running

echo [INFO] Checking application health endpoint...
goto :eof

:show_access_info
call :print_section Access Information

echo.
echo [INFO] Access your application:
echo   Web Interface: http://localhost:%APP_PORT%
echo   Results Page: http://localhost:%APP_PORT%/results
echo   Health Check: http://localhost:%APP_PORT%/health
echo.
echo [INFO] Database Access:
echo   Host: localhost
echo   Port: %DB_PORT%
echo   Database: %DB_NAME%
echo   Username: %DB_USER%
echo   Password: %DB_PASSWORD%
echo.
echo [INFO] Useful Commands:
echo   View logs:        run.bat logs
echo   Stop containers:  run.bat stop
echo   Restart containers: run.bat restart
echo   Show status:      run.bat status
echo   Complete cleanup: run.bat clean
echo.
echo [INFO] Container Info:
echo   Flask Container: %APP_CONTAINER%
echo   PostgreSQL Container: %DB_CONTAINER%
echo   Network: %NETWORK_NAME%
echo.
goto :eof

:start_all
call :print_section Starting AI Poll Application

call :check_docker
if !errorlevel! neq 0 exit /b 1

call :create_network
call :start_postgres
if !errorlevel! neq 0 exit /b 1

call :build_app_image
if !errorlevel! neq 0 exit /b 1

call :start_app
call :verify_containers
call :show_access_info
goto :eof

:stop_all
call :print_section Stopping Containers

call :is_container_running %APP_CONTAINER%
if !CONTAINER_RUNNING! equ 1 (
    echo [INFO] Stopping Flask application container...
    docker stop %APP_CONTAINER%
    call :print_success Flask application container stopped
) else (
    call :print_warning Flask application container is not running
)

call :is_container_running %DB_CONTAINER%
if !CONTAINER_RUNNING! equ 1 (
    echo [INFO] Stopping PostgreSQL container...
    docker stop %DB_CONTAINER%
    call :print_success PostgreSQL container stopped
) else (
    call :print_warning PostgreSQL container is not running
)

call :print_success All containers stopped
goto :eof

:restart_all
call :print_section Restarting Containers

call :stop_all
echo.
call :start_all
goto :eof

:show_logs
call :print_section Container Logs

echo.
echo PostgreSQL Logs:
echo ───────────────────────────────────────
docker logs %DB_CONTAINER% 2>nul
if !errorlevel! neq 0 call :print_warning PostgreSQL container not found

echo.
echo.
echo Flask Application Logs:
echo ───────────────────────────────────────
docker logs %APP_CONTAINER% 2>nul
if !errorlevel! neq 0 call :print_warning Flask application container not found
goto :eof

:show_status
call :print_section Container Status

echo.
echo Network Status:
docker network ls | find "%NETWORK_NAME%" >nul
if !errorlevel! equ 0 (
    call :print_success Network '%NETWORK_NAME%' exists
    docker network inspect %NETWORK_NAME%
) else (
    call :print_error Network '%NETWORK_NAME%' does not exist
)

echo.
echo Container Status:
docker ps -a --filter "name=%DB_CONTAINER%\|%APP_CONTAINER%" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

echo.
echo Image Status:
docker images --filter "reference=%APP_IMAGE%" --format "table {{.Repository}}:{{.Tag}}\t{{.Size}}"
goto :eof

:clean_all
call :print_section Cleaning Up

set /p CONFIRM="[WARNING] This will stop and remove all containers and images. Continue? (y/n): "

if /i not "!CONFIRM!"=="y" (
    call :print_warning Cleanup cancelled
    goto :eof
)

call :is_container_running %APP_CONTAINER%
if !CONTAINER_RUNNING! equ 1 (
    echo [INFO] Stopping Flask application container...
    docker stop %APP_CONTAINER%
)

call :is_container_running %DB_CONTAINER%
if !CONTAINER_RUNNING! equ 1 (
    echo [INFO] Stopping PostgreSQL container...
    docker stop %DB_CONTAINER%
)

docker ps -a --filter "name=%APP_CONTAINER%" --quiet | find "." >nul
if !errorlevel! equ 0 (
    echo [INFO] Removing Flask application container...
    docker rm %APP_CONTAINER%
    call :print_success Flask application container removed
)

docker ps -a --filter "name=%DB_CONTAINER%" --quiet | find "." >nul
if !errorlevel! equ 0 (
    echo [INFO] Removing PostgreSQL container...
    docker rm %DB_CONTAINER%
    call :print_success PostgreSQL container removed
)

docker images --quiet %APP_IMAGE% | find "." >nul
if !errorlevel! equ 0 (
    echo [INFO] Removing Flask application image...
    docker rmi %APP_IMAGE%
    call :print_success Flask application image removed
)

docker network ls | find "%NETWORK_NAME%" >nul
if !errorlevel! equ 0 (
    echo [INFO] Removing network...
    docker network rm %NETWORK_NAME%
    call :print_success Network removed
)

call :print_success Cleanup complete!
goto :eof

:show_help
echo.
echo AI Poll Voting Application - Docker Setup Script (Windows)
echo.
echo Usage: %0 [command]
echo.
echo Commands:
echo   start       Start all containers (default)
echo   stop        Stop all containers
echo   restart     Restart all containers
echo   logs        Show container logs
echo   status      Show container status
echo   clean       Stop and remove all containers/images/volumes
echo   help        Show this help message
echo.
echo Examples:
echo   %0 start       :: Start the application
echo   %0 logs        :: View application logs
echo   %0 stop        :: Stop containers
echo   %0 clean       :: Complete cleanup
echo.
goto :eof

:parse_command
if "%1"=="" goto :start_all
if "%1"=="start" goto :start_all
if "%1"=="stop" goto :stop_all
if "%1"=="restart" goto :restart_all
if "%1"=="logs" goto :show_logs
if "%1"=="status" goto :show_status
if "%1"=="clean" goto :clean_all
if "%1"=="help" goto :show_help

call :print_error Unknown command: %1
echo.
call :show_help
exit /b 1

:end
endlocal
