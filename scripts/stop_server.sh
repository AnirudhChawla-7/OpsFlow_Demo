#!/bin/bash
echo "Stopping OpsFlow app..."
pkill -f "node src/server.js" || true
