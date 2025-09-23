#!/bin/bash
set -e
cd /home/ec2-user/OpsFlow
echo "Installing Node.js and project dependencies..."

# Install Node.js if not present
if ! command -v node &> /dev/null; then
    curl -sL https://rpm.nodesource.com/setup_18.x | sudo bash -
    sudo yum install -y nodejs
fi

# Ensure ec2-user owns the files (fix permission issue)
sudo chown -R ec2-user:ec2-user /home/ec2-user/OpsFlow

# Install project dependencies as ec2-user
npm install --legacy-peer-deps
