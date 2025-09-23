#!/bin/bash
set -e
cd /home/ec2-user/OpsFlow
echo "Starting OpsFlow app..."

# Stop any existing Node.js process
pkill -f "node src/server.js" || true

# Start app
nohup node src/server.js > server.log 2>&1 &
