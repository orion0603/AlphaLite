#!/bin/bash

# Check if .env file exists
if [ -f .env ]; then
    # Read API key from .env file
    API_KEY=$(grep OPENAI_API_KEY .env | cut -d '=' -f2)
    
    if [ ! -z "$API_KEY" ]; then
        # Save to Keychain using security command
        security add-generic-password \
            -a $USER \
            -s com.alphaLite.apiKey \
            -w "$API_KEY" \
            -T /usr/bin/security
        echo "API key has been added to Keychain"
    else
        echo "No API key found in .env file"
    fi
else
    echo ".env file not found"
fi 