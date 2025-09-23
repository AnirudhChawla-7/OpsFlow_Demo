#!/bin/bash
set -e
cd /home/ec2-user/OpsFlow
echo "Installing Node.js and dependencies..."

# Install Node.js
if ! command -v node &> /dev/null
then
    curl -sL https://rpm.nodesource.com/setup_18.x | sudo bash -
    sudo yum install -y nodejs
fi

# npm check
if ! command -v npm &> /dev/null
then
    sudo yum install -y npm
fi

# Project dependencies install
npm install --legacy-peer-deps || { echo "npm install failed"; exit 1; }
