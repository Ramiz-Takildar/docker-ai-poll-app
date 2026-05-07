#!/bin/bash

################################################################################
# AI Poll Voting Application - Complete Docker Setup Script
# 
# This script automates the entire setup process:
# - Creates Docker network
# - Starts PostgreSQL container
# - Builds Flask application image
# - Runs Flask application container
# - Displays access information
#
# Usage: ./run.sh [command]
# Commands:
#   start     - Start all containers (default)
#   stop      - Stop all containers
#   restart   - Restart all containers
#   logs      - Show container logs
#   clean     - Stop and remove all containers/images
#   status    - Show container status
#
# Example:
#   ./run.sh start          # Start the application
#   ./run.sh logs           # View logs
#   ./run.sh stop           # Stop the application
#   ./run.sh clean          # Complete cleanup
#
################################################################################

set -e  # Exit on any error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'  # No Color

# Configuration variables
NETWORK_NAME="ai-poll-network"
DB_CONTAINER="postgres-db"
DB_IMAGE="postgres:15"
APP_CONTAINER="ai-poll-container"
APP_IMAGE="ai-poll-app:v1"
APP_PORT="5000"
DB_PORT="5432"

# Database credentials
DB_USER="admin"
DB_PASSWORD="admin123"
DB_NAME="polls"

# Function to print colored output
print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

# Function to print section headers
print_section() {
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# Function to check if Docker is running
check_docker() {
    print_info "Checking Docker installation..."
    
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed. Please install Docker first."
        echo "Visit: https://www.docker.com/products/docker-desktop"
        exit 1
    fi
    
    if ! docker ps &> /dev/null; then
        print_error "Docker daemon is not running. Please start Docker."
        exit 1
    fi
    
    print_success "Docker is running ($(docker --version))"
}

# Function to create Docker network
create_network() {
    print_info "Checking Docker network..."
    
    if docker network ls | grep -q "^${NETWORK_NAME}"; then
        print_success "Network '${NETWORK_NAME}' already exists"
    else
        print_info "Creating network '${NETWORK_NAME}'..."
        docker network create ${NETWORK_NAME}
        print_success "Network created"
    fi
}

# Function to check if container is running
is_container_running() {
    docker ps --filter "name=$1" --filter "status=running" --quiet
}

# Function to start PostgreSQL container
start_postgres() {
    print_info "Checking PostgreSQL container..."
    
    if is_container_running ${DB_CONTAINER}; then
        print_success "PostgreSQL container is already running"
        return 0
    fi
    
    # Check if container exists but is stopped
    if docker ps -a --filter "name=${DB_CONTAINER}" --quiet | grep -q .; then
        print_info "Starting stopped PostgreSQL container..."
        docker start ${DB_CONTAINER}
        print_success "PostgreSQL container started"
    else
        print_info "Creating and starting PostgreSQL container..."
        docker run -d \
            --name ${DB_CONTAINER} \
            --network ${NETWORK_NAME} \
            -e POSTGRES_USER=${DB_USER} \
            -e POSTGRES_PASSWORD=${DB_PASSWORD} \
            -e POSTGRES_DB=${DB_NAME} \
            -p ${DB_PORT}:5432 \
            ${DB_IMAGE}
        print_success "PostgreSQL container created and started"
    fi
    
    # Wait for PostgreSQL to be ready
    print_info "Waiting for PostgreSQL to initialize (10 seconds)..."
    sleep 10
    print_success "PostgreSQL is ready"
}

# Function to build Flask application image
build_app_image() {
    print_info "Checking Flask application image..."
    
    if docker images --quiet ${APP_IMAGE} | grep -q .; then
        print_warning "Image '${APP_IMAGE}' already exists. Rebuilding..."
    else
        print_info "Building Flask application image..."
    fi
    
    # Check if app directory exists
    if [ ! -d "app" ]; then
        print_error "app/ directory not found. Make sure you're in the project root directory."
        exit 1
    fi
    
    print_info "Running docker build..."
    docker build -t ${APP_IMAGE} . --progress=plain
    print_success "Flask application image built: ${APP_IMAGE}"
}

# Function to start Flask application container
start_app() {
    print_info "Checking Flask application container..."
    
    if is_container_running ${APP_CONTAINER}; then
        print_success "Flask application container is already running"
        return 0
    fi
    
    # Check if container exists but is stopped
    if docker ps -a --filter "name=${APP_CONTAINER}" --quiet | grep -q .; then
        print_info "Starting stopped Flask application container..."
        docker start ${APP_CONTAINER}
        print_success "Flask application container started"
    else
        print_info "Creating and starting Flask application container..."
        docker run -d \
            --name ${APP_CONTAINER} \
            --network ${NETWORK_NAME} \
            -e DB_HOST=${DB_CONTAINER} \
            -e DB_PORT=${DB_PORT} \
            -e DB_NAME=${DB_NAME} \
            -e DB_USER=${DB_USER} \
            -e DB_PASSWORD=${DB_PASSWORD} \
            -p ${APP_PORT}:5000 \
            ${APP_IMAGE}
        print_success "Flask application container created and started"
    fi
    
    # Wait for application to be ready
    print_info "Waiting for Flask application to initialize (5 seconds)..."
    sleep 5
}

# Function to verify containers are healthy
verify_containers() {
    print_info "Verifying container health..."
    
    # Check PostgreSQL
    if ! is_container_running ${DB_CONTAINER} &> /dev/null; then
        print_error "PostgreSQL container is not running"
        return 1
    fi
    print_success "PostgreSQL container is running"
    
    # Check Flask app
    if ! is_container_running ${APP_CONTAINER} &> /dev/null; then
        print_error "Flask application container is not running"
        return 1
    fi
    print_success "Flask application container is running"
    
    # Check application health endpoint
    print_info "Checking application health endpoint..."
    if curl -s http://localhost:${APP_PORT}/health | grep -q "healthy"; then
        print_success "Application is healthy"
    else
        print_warning "Application health check pending (may still be initializing)"
    fi
}

# Function to display access information
show_access_info() {
    print_section "🚀 Application Ready!"
    echo ""
    echo -e "${GREEN}Access your application:${NC}"
    echo -e "${BLUE}  Web Interface:${NC} http://localhost:${APP_PORT}"
    echo -e "${BLUE}  Results Page:${NC} http://localhost:${APP_PORT}/results"
    echo -e "${BLUE}  Health Check:${NC} http://localhost:${APP_PORT}/health"
    echo ""
    echo -e "${GREEN}Database Access:${NC}"
    echo -e "${BLUE}  Host:${NC} localhost"
    echo -e "${BLUE}  Port:${NC} ${DB_PORT}"
    echo -e "${BLUE}  Database:${NC} ${DB_NAME}"
    echo -e "${BLUE}  Username:${NC} ${DB_USER}"
    echo -e "${BLUE}  Password:${NC} ${DB_PASSWORD}"
    echo ""
    echo -e "${GREEN}Useful Commands:${NC}"
    echo -e "${BLUE}  View logs:${NC}        ./run.sh logs"
    echo -e "${BLUE}  Stop containers:${NC}  ./run.sh stop"
    echo -e "${BLUE}  Restart containers:${NC} ./run.sh restart"
    echo -e "${BLUE}  Show status:${NC}      ./run.sh status"
    echo -e "${BLUE}  Complete cleanup:${NC} ./run.sh clean"
    echo ""
    echo -e "${GREEN}Container Info:${NC}"
    echo -e "${BLUE}  Flask Container:${NC}      ${APP_CONTAINER}"
    echo -e "${BLUE}  PostgreSQL Container:${NC} ${DB_CONTAINER}"
    echo -e "${BLUE}  Network:${NC}             ${NETWORK_NAME}"
    echo ""
}

# Function to start all containers
start_all() {
    print_section "🐳 Starting AI Poll Application"
    
    check_docker
    create_network
    start_postgres
    build_app_image
    start_app
    verify_containers
    show_access_info
}

# Function to stop all containers
stop_all() {
    print_section "🛑 Stopping Containers"
    
    if is_container_running ${APP_CONTAINER}; then
        print_info "Stopping Flask application container..."
        docker stop ${APP_CONTAINER}
        print_success "Flask application container stopped"
    else
        print_warning "Flask application container is not running"
    fi
    
    if is_container_running ${DB_CONTAINER}; then
        print_info "Stopping PostgreSQL container..."
        docker stop ${DB_CONTAINER}
        print_success "PostgreSQL container stopped"
    else
        print_warning "PostgreSQL container is not running"
    fi
    
    print_success "All containers stopped"
}

# Function to restart containers
restart_all() {
    print_section "🔄 Restarting Containers"
    
    stop_all
    echo ""
    start_all
}

# Function to show container logs
show_logs() {
    print_section "📋 Container Logs"
    
    echo ""
    echo -e "${BLUE}PostgreSQL Logs:${NC}"
    echo "───────────────────────────────────────"
    docker logs ${DB_CONTAINER} 2>/dev/null || print_warning "PostgreSQL container not found"
    
    echo ""
    echo ""
    echo -e "${BLUE}Flask Application Logs:${NC}"
    echo "───────────────────────────────────────"
    docker logs ${APP_CONTAINER} 2>/dev/null || print_warning "Flask application container not found"
}

# Function to show container status
show_status() {
    print_section "📊 Container Status"
    
    echo ""
    echo -e "${BLUE}Network Status:${NC}"
    if docker network ls | grep -q "^${NETWORK_NAME}"; then
        print_success "Network '${NETWORK_NAME}' exists"
        docker network inspect ${NETWORK_NAME} | grep -A 50 "Containers"
    else
        print_error "Network '${NETWORK_NAME}' does not exist"
    fi
    
    echo ""
    echo -e "${BLUE}Container Status:${NC}"
    docker ps -a --filter "name=${DB_CONTAINER}\|${APP_CONTAINER}" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
    
    echo ""
    echo -e "${BLUE}Image Status:${NC}"
    docker images --filter "reference=${APP_IMAGE}" --format "table {{.Repository}}:{{.Tag}}\t{{.Size}}\t{{.CreatedAt}}"
}

# Function to clean up everything
clean_all() {
    print_section "🧹 Cleaning Up"
    
    read -p "⚠️  This will stop and remove all containers and images. Continue? (y/n) " -n 1 -r
    echo ""
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_warning "Cleanup cancelled"
        return 0
    fi
    
    # Stop containers
    if is_container_running ${APP_CONTAINER}; then
        print_info "Stopping Flask application container..."
        docker stop ${APP_CONTAINER}
    fi
    
    if is_container_running ${DB_CONTAINER}; then
        print_info "Stopping PostgreSQL container..."
        docker stop ${DB_CONTAINER}
    fi
    
    # Remove containers
    if docker ps -a --filter "name=${APP_CONTAINER}" --quiet | grep -q .; then
        print_info "Removing Flask application container..."
        docker rm ${APP_CONTAINER}
        print_success "Flask application container removed"
    fi
    
    if docker ps -a --filter "name=${DB_CONTAINER}" --quiet | grep -q .; then
        print_info "Removing PostgreSQL container..."
        docker rm ${DB_CONTAINER}
        print_success "PostgreSQL container removed"
    fi
    
    # Remove images
    if docker images --quiet ${APP_IMAGE} | grep -q .; then
        print_info "Removing Flask application image..."
        docker rmi ${APP_IMAGE}
        print_success "Flask application image removed"
    fi
    
    # Remove network
    if docker network ls | grep -q "^${NETWORK_NAME}"; then
        print_info "Removing network..."
        docker network rm ${NETWORK_NAME}
        print_success "Network removed"
    fi
    
    print_success "Cleanup complete!"
}

# Function to show help
show_help() {
    echo -e "${BLUE}AI Poll Voting Application - Docker Setup Script${NC}"
    echo ""
    echo "Usage: $0 [command]"
    echo ""
    echo "Commands:"
    echo -e "  ${GREEN}start${NC}       Start all containers (default)"
    echo -e "  ${GREEN}stop${NC}        Stop all containers"
    echo -e "  ${GREEN}restart${NC}     Restart all containers"
    echo -e "  ${GREEN}logs${NC}        Show container logs"
    echo -e "  ${GREEN}status${NC}      Show container status"
    echo -e "  ${GREEN}clean${NC}       Stop and remove all containers/images/volumes"
    echo -e "  ${GREEN}help${NC}        Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 start          # Start the application"
    echo "  $0 logs           # View application logs"
    echo "  $0 stop           # Stop containers"
    echo "  $0 clean          # Complete cleanup"
    echo ""
}

# Main script logic
main() {
    # Get command from argument (default to 'start')
    COMMAND="${1:-start}"
    
    case "${COMMAND}" in
        start)
            start_all
            ;;
        stop)
            stop_all
            ;;
        restart)
            restart_all
            ;;
        logs)
            show_logs
            ;;
        status)
            show_status
            ;;
        clean)
            clean_all
            ;;
        help)
            show_help
            ;;
        *)
            print_error "Unknown command: ${COMMAND}"
            echo ""
            show_help
            exit 1
            ;;
    esac
}

# Run main function
main "$@"
