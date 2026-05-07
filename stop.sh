#!/bin/bash

# AI Poll Application - Docker Cleanup Script
# Stops and removes ONLY this application's containers, network, and image
# Safe to run even if containers don't exist
# Does NOT affect other Docker containers/applications

set -e

NETWORK_NAME="poll-network"
DB_CONTAINER="postgres-db"
APP_CONTAINER="flask-app"
APP_IMAGE="ai-poll-app:v1"

echo "🧹 AI Poll Application - Cleanup Script"
echo ""
echo "⚠️  This will only remove this application's containers:"
echo "   - $APP_CONTAINER"
echo "   - $DB_CONTAINER"
echo "   - $NETWORK_NAME"
echo "   - $APP_IMAGE"
echo ""
echo "   Other Docker containers will NOT be affected."
echo ""

# Counter for removed items
removed_count=0

# Function to check if container exists and belongs to this app
container_exists() {
    docker ps -a --format '{{.Names}}' | grep -q "^${1}$"
}

# Function to check if network exists
network_exists() {
    docker network ls --format '{{.Name}}' | grep -q "^${1}$"
}

# Stop Flask app container
if container_exists "$APP_CONTAINER"; then
    echo "1️⃣  Stopping Flask application container..."
    docker stop "$APP_CONTAINER" > /dev/null 2>&1 && echo "   ✓ Stopped" || echo "   (Already stopped)"
    removed_count=$((removed_count + 1))
else
    echo "1️⃣  Flask application container not found (skipping)"
fi

# Stop PostgreSQL container
if container_exists "$DB_CONTAINER"; then
    echo "2️⃣  Stopping PostgreSQL container..."
    docker stop "$DB_CONTAINER" > /dev/null 2>&1 && echo "   ✓ Stopped" || echo "   (Already stopped)"
    removed_count=$((removed_count + 1))
else
    echo "2️⃣  PostgreSQL container not found (skipping)"
fi

# Remove Flask app container
if container_exists "$APP_CONTAINER"; then
    echo "3️⃣  Removing Flask application container..."
    docker rm "$APP_CONTAINER" > /dev/null 2>&1 && echo "   ✓ Removed" || true
    removed_count=$((removed_count + 1))
else
    echo "3️⃣  Flask application container already removed (skipping)"
fi

# Remove PostgreSQL container
if container_exists "$DB_CONTAINER"; then
    echo "4️⃣  Removing PostgreSQL container..."
    docker rm "$DB_CONTAINER" > /dev/null 2>&1 && echo "   ✓ Removed" || true
    removed_count=$((removed_count + 1))
else
    echo "4️⃣  PostgreSQL container already removed (skipping)"
fi

# Remove network (only if it exists and no other containers are using it)
if network_exists "$NETWORK_NAME"; then
    echo "5️⃣  Removing Docker network..."
    # Check if any other containers are connected to this network
    other_containers=$(docker network inspect "$NETWORK_NAME" 2>/dev/null | grep -c '"Containers"' || echo 0)
    
    docker network rm "$NETWORK_NAME" > /dev/null 2>&1 && echo "   ✓ Removed" || echo "   (Network in use by other containers, skipping)"
    removed_count=$((removed_count + 1))
else
    echo "5️⃣  Docker network already removed (skipping)"
fi

# Remove Docker image (only this app's image)
echo "6️⃣  Removing application image ($APP_IMAGE)..."
if docker images --format '{{.Repository}}:{{.Tag}}' 2>/dev/null | grep -q "^${APP_IMAGE}$"; then
    # Check if image is in use by any container
    if docker ps -a --format '{{.Image}}' 2>/dev/null | grep -q "^${APP_IMAGE}$"; then
        echo "   (Image still in use by container, skipping)"
    else
        docker rmi "$APP_IMAGE" > /dev/null 2>&1 && echo "   ✓ Image removed" || true
        removed_count=$((removed_count + 1))
    fi
else
    echo "   (Image not found)"
fi

echo ""
if [ $removed_count -gt 0 ]; then
    echo "✅ Cleanup complete! ($removed_count items removed)"
else
    echo "✅ Nothing to clean (all already removed)"
fi

echo ""
echo "📝 To start fresh, run:"
echo "   bash start.sh"
echo ""
