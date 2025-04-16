#!/bin/bash
set -e

# Build Docker image
cd /home/ubuntu/quizspark
docker build -t quizspark-backend . 