#!/bin/bash

echo "Checking Docker containers..."

if docker compose ps | grep -q "Up"; then
    echo "Application containers are running."
else
    echo "Application containers are NOT running."
    exit 1
fi

echo ""
echo "Container Status:"
docker compose ps

echo ""
echo "Health check completed."
