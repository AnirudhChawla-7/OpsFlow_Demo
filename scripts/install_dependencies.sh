#!/bin/bash
cd /home/ec2-user/OpsFlow
echo "Installing Node.js and dependencies..."

# Install Node.js if not installed
if ! command -v node &> /dev/null
then
    curl -sL https://rpm.nodesource.com/setup_18.x | sudo bash -
    sudo yum install -y nodejs
fi

# Install project dependencies
npm install
