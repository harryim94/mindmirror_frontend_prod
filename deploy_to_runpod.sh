#!/bin/bash

# Build Flutter web app
flutter build web

# Build the Docker image
docker build -t mindmirror-frontend .

# Tag the image for RunPod
docker tag mindmirror-frontend:latest runpod/mindmirror-frontend:latest

# Push to RunPod registry
docker push runpod/mindmirror-frontend:latest

# Install cloudflared if not already installed
if ! command -v cloudflared &> /dev/null; then
    curl -L --output cloudflared.deb https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb
    sudo dpkg -i cloudflared.deb
fi

# Start cloudflared tunnel
cloudflared tunnel --url http://localhost:80 