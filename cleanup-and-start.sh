#!/bin/bash

################################################################################
# COMPLETE CLEANUP & START SCRIPT
# Handles all cleanup and fresh start for AI Poll Application
# Usage: bash cleanup-and-start.sh
################################################################################

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║         AI POLL APPLICATION - COMPLETE CLEANUP & START         ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════════╝${NC}"
echo ""

# ============================================================================
# PART 1: COMPLETE CLEANUP
# ============================================================================

echo -e "${YELLOW}[CLEANUP] Starting complete cleanup...${NC}"
echo ""

# Stop only AI Poll containers (don't impact other containers)
echo -e "${BLUE}[CLEANUP] Stopping AI Poll containers...${NC}"
docker stop postgres-db 2>/dev/null || echo "postgres-db not running"
docker stop ai-poll-container 2>/dev/null || echo "ai-poll-container not running"

# Remove AI Poll containers
echo -e "${BLUE}[CLEANUP] Removing AI Poll containers...${NC}"
docker rm -f postgres-db 2>/dev/null || echo "postgres-db not found"
docker rm -f ai-poll-container 2>/dev/null || echo "ai-poll-container not found"

# Remove AI Poll image
echo -e "${BLUE}[CLEANUP] Removing AI Poll image...${NC}"
docker rmi -f ai-poll-app:v1 2>/dev/null || echo "ai-poll-app:v1 not found"

# Remove network
echo -e "${BLUE}[CLEANUP] Removing AI Poll network...${NC}"
docker network rm ai-poll-network 2>/dev/null || echo "ai-poll-network not found"

# Prune unused resources
echo -e "${BLUE}[CLEANUP] Pruning unused Docker resources...${NC}"
docker system prune -f --volumes > /dev/null 2>&1 || true

echo -e "${GREEN}✓ Cleanup complete!${NC}"
echo ""

# ============================================================================
# PART 2: FRESH START
# ============================================================================

echo -e "${YELLOW}[START] Beginning fresh start...${NC}"
echo ""

# Verify Docker is running
echo -e "${BLUE}[START] Verifying Docker...${NC}"
docker ps > /dev/null || { echo "Docker not running!"; exit 1; }
echo -e "${GREEN}✓ Docker is running${NC}"
echo ""

# Create network
echo -e "${BLUE}[START] Creating Docker network (ai-poll-network)...${NC}"
docker network create ai-poll-network
echo -e "${GREEN}✓ Network created${NC}"
echo ""

# Start PostgreSQL
echo -e "${BLUE}[START] Starting PostgreSQL container...${NC}"
docker run -d \
  --name postgres-db \
  --network ai-poll-network \
  -e POSTGRES_USER=admin \
  -e POSTGRES_PASSWORD=admin123 \
  -e POSTGRES_DB=polls \
  -p 5432:5432 \
  postgres:15
echo -e "${GREEN}✓ PostgreSQL started${NC}"

# Wait for PostgreSQL
echo -e "${BLUE}[START] Waiting for PostgreSQL to initialize (15 seconds)...${NC}"
sleep 15

# Verify PostgreSQL connection
echo -e "${BLUE}[START] Verifying PostgreSQL connection...${NC}"
docker exec postgres-db psql -U admin -d polls -c "SELECT 1;" > /dev/null 2>&1
echo -e "${GREEN}✓ PostgreSQL is ready${NC}"
echo ""

# Build Flask image
echo -e "${BLUE}[START] Building Flask application image...${NC}"
docker build -t ai-poll-app:v1 . > /dev/null 2>&1
echo -e "${GREEN}✓ Flask image built${NC}"
echo ""

# Start Flask container
echo -e "${BLUE}[START] Starting Flask application container...${NC}"
docker run -d \
  --name ai-poll-container \
  --network ai-poll-network \
  -e DB_HOST=postgres-db \
  -e DB_PORT=5432 \
  -e DB_NAME=polls \
  -e DB_USER=admin \
  -e DB_PASSWORD=admin123 \
  -p 5000:5000 \
  ai-poll-app:v1
echo -e "${GREEN}✓ Flask container started${NC}"

# Wait for Flask to start
echo -e "${BLUE}[START] Waiting for Flask to initialize (10 seconds)...${NC}"
sleep 10

# Verify Flask health
echo -e "${BLUE}[START] Verifying Flask application health...${NC}"
for i in {1..5}; do
  if curl -s http://localhost:5000/health > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Flask is healthy and responding${NC}"
    break
  else
    if [ $i -lt 5 ]; then
      echo "Attempt $i/5: Waiting..."
      sleep 2
    else
      echo -e "${RED}✗ Flask health check failed${NC}"
      exit 1
    fi
  fi
done
echo ""

# ============================================================================
# SUMMARY
# ============================================================================

echo -e "${BLUE}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}             ✓ DEPLOYMENT COMPLETE & VERIFIED${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════════╝${NC}"
echo ""

echo -e "${GREEN}RUNNING CONTAINERS:${NC}"
docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}" | grep -E "postgres-db|ai-poll"
echo ""

echo -e "${GREEN}ACCESS YOUR APPLICATION:${NC}"
echo -e "  🏠 Home Page:    ${BLUE}http://localhost:5000${NC}"
echo -e "  📊 Results:      ${BLUE}http://localhost:5000/results${NC}"
echo -e "  💚 Health Check: ${BLUE}http://localhost:5000/health${NC}"
echo ""

echo -e "${GREEN}DATABASE ACCESS:${NC}"
echo -e "  Host:     ${BLUE}localhost${NC}"
echo -e "  Port:     ${BLUE}5432${NC}"
echo -e "  Database: ${BLUE}polls${NC}"
echo -e "  User:     ${BLUE}admin${NC}"
echo -e "  Password: ${BLUE}admin123${NC}"
echo ""

echo -e "${GREEN}USEFUL COMMANDS:${NC}"
echo -e "  View logs:    ${BLUE}docker logs ai-poll-container${NC}"
echo -e "  Stop all:     ${BLUE}docker stop \$(docker ps -q)${NC}"
echo -e "  Clean all:    ${BLUE}bash cleanup-and-start.sh${NC}"
echo ""

echo -e "${GREEN}✓ Application is LIVE and ready to use!${NC}"
echo ""
