#!/bin/bash
set -e
cd /home/ec2-user/OpsFlow
echo "Installing Node.js and project dependencies..."

# Install Node.js if not present
if ! command -v node &> /dev/null; then
    curl -sL https://rpm.nodesource.com/setup_18.x | sudo bash -
    sudo yum install -y nodejs
fi

# Install npm if missing
if ! command -v npm &> /dev/null; then
    sudo yum install -y npm
fi

# Install project dependencies
npm install --legacy-peer-deps
