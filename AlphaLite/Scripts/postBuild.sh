#!/bin/bash

# Check if .env file exists
if [ ! -f ".env" ]; then
    echo "Error: .env file not found"
    exit 1
fi

# Read API key from .env file
API_KEY=$(grep OPENAI_API_KEY .env | cut -d '=' -f2)

if [ -z "$API_KEY" ]; then
    echo "Error: OPENAI_API_KEY not found in .env file"
    exit 1
fi

# Add API key to Keychain
security add-generic-password -a $USER -s AlphaLite -w "$API_KEY" -T /usr/bin/security

echo "API key successfully added to Keychain" 