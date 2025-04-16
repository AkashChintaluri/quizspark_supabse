#!/bin/bash
set -e

# Stop and remove existing container if it exists
docker stop quizspark-backend || true
docker rm quizspark-backend || true

# Clean up old application files
rm -rf /home/ubuntu/quizspark/* 