#!/bin/bash
cd /home/ec2-user/OpsFlow
echo "Installing Node.js and dependencies..."

# Install Node.js (always ensure)
curl -fsSL https://rpm.nodesource.com/setup_18.x | sudo bash -
sudo yum install -y nodejs

# Install project dependencies
if [ -f package.json ]; then
    npm install
else
    echo "No package.json found!"
fi
