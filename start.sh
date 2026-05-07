#!/bin/bash

# AI Poll Application - Pure Docker Launcher
# Automated script to start database and Flask app with plain Docker commands
# Cleans up ONLY this application's old containers/network before starting fresh
# Does NOT affect other Docker containers/applications

set -e

NETWORK_NAME="poll-network"
DB_CONTAINER="postgres-db"
DB_IMAGE="postgres:15"
APP_CONTAINER="flask-app"
APP_IMAGE="ai-poll-app:v1"

echo "🐳 AI Poll Application - Docker Launcher"
echo ""

# Helper functions
container_exists() {
    docker ps -a --format '{{.Names}}' | grep -q "^${1}$"
}

network_exists() {
    docker network ls --format '{{.Name}}' | grep -q "^${1}$"
}

# Cleanup: Stop and remove ONLY this application's containers (not other apps)
echo "🧹 Cleaning up old containers from this application..."
cleanup_done=false

if container_exists "$APP_CONTAINER"; then
    echo "   → Removing old Flask container ($APP_CONTAINER)"
    docker stop "$APP_CONTAINER" > /dev/null 2>&1 || true
    docker rm "$APP_CONTAINER" > /dev/null 2>&1 || true
    cleanup_done=true
fi

if container_exists "$DB_CONTAINER"; then
    echo "   → Removing old PostgreSQL container ($DB_CONTAINER)"
    docker stop "$DB_CONTAINER" > /dev/null 2>&1 || true
    docker rm "$DB_CONTAINER" > /dev/null 2>&1 || true
    cleanup_done=true
fi

if network_exists "$NETWORK_NAME"; then
    echo "   → Removing old network ($NETWORK_NAME)"
    docker network rm "$NETWORK_NAME" > /dev/null 2>&1 || true
    cleanup_done=true
fi

if [ "$cleanup_done" = true ]; then
    echo "   ✓ Cleanup done"
else
    echo "   (Nothing to clean)"
fi

echo ""

# Step 1: Create network
echo "1️⃣  Creating Docker network ($NETWORK_NAME)..."
docker network create $NETWORK_NAME > /dev/null 2>&1
echo "   ✓ Network created"

# Step 2: Start PostgreSQL
echo "2️⃣  Starting PostgreSQL container ($DB_CONTAINER)..."
docker run -d \
  --name $DB_CONTAINER \
  --network $NETWORK_NAME \
  -e POSTGRES_USER=admin \
  -e POSTGRES_PASSWORD=admin123 \
  -e POSTGRES_DB=polls \
  -p 5432:5432 \
  $DB_IMAGE > /dev/null 2>&1

echo "   ✓ Container created"
echo "   Waiting for PostgreSQL to initialize..."
sleep 8
echo "   ✓ Ready"

# Step 3: Build app image
echo "3️⃣  Building Flask application image ($APP_IMAGE)..."
docker build -t $APP_IMAGE . > /dev/null 2>&1
echo "   ✓ Image built"

# Step 4: Start Flask app
echo "4️⃣  Starting Flask application container ($APP_CONTAINER)..."
docker run -d \
  --name $APP_CONTAINER \
  --network $NETWORK_NAME \
  -e DB_HOST=$DB_CONTAINER \
  -e DB_PORT=5432 \
  -e DB_NAME=polls \
  -e DB_USER=admin \
  -e DB_PASSWORD=admin123 \
  -e FLASK_ENV=production \
  -e SECRET_KEY=your-secure-secret-key-here \
  -p 8000:5000 \
  $APP_IMAGE > /dev/null 2>&1

echo "   ✓ Container created"
echo "   Waiting for Flask app to initialize..."
sleep 3
echo "   ✓ Ready"

# Step 5: Verify
echo ""
echo "✅ Application is ready!"
echo ""
echo "📍 Access the application:"
echo "   Web:     http://localhost:8000"
echo "   Results: http://localhost:8000/results"
echo "   Health:  http://localhost:8000/health"
echo ""
echo "📋 Container names (this application only):"
echo "   App:      $APP_CONTAINER"
echo "   Database: $DB_CONTAINER"
echo "   Network:  $NETWORK_NAME"
echo ""
echo "📋 Useful commands:"
echo "   Logs:     docker logs $APP_CONTAINER -f"
echo "   Stop:     bash stop.sh"
echo "   Status:   docker ps"
echo "   All apps: docker ps -a"
echo ""
