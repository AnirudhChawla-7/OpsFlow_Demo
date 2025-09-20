#!/bin/bash
cd /home/ec2-user/OpsFlow
echo "Starting OpsFlow app..."

# Kill existing node process if running
pkill -f "node src/server.js" || true

# Start app in background
nohup node src/server.js > server.log 2>&1 &
