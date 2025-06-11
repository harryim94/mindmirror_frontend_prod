#!/bin/bash

# Build the Docker image
docker build -t mindmirror-frontend .

# Create a temporary container and copy the built web files
docker create --name temp-container mindmirror-frontend
docker cp temp-container:/usr/share/nginx/html ./build/web
docker rm temp-container

# Install Firebase CLI if not already installed
if ! command -v firebase &> /dev/null; then
    npm install -g firebase-tools
fi

# Login to Firebase (if not already logged in)
firebase login

# Deploy to Firebase
firebase deploy --only hosting

# Clean up
rm -rf ./build

# Build and push your Docker image
docker build -t runpod/mindmirror-backend:latest .
docker push runpod/mindmirror-backend:latest

# Deploy to RunPod using their dashboard or API
# After deployment, you'll get a URL like: https://abc-8000.proxy.runpod.net 

# Build your Flutter web app
flutter build web

# Deploy to Firebase
firebase deploy --only hosting 

curl https://api.mindmirror.it.com/health 