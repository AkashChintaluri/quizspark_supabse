#!/bin/bash
set -e

# Build Docker image
cd /home/ubuntu/quizspark
docker build -t quizspark-backend .

# Load the Docker image
docker load < /home/ubuntu/quizspark-backend.tar.gz 