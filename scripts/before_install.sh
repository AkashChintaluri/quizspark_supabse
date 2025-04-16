#!/bin/bash
set -e

# Stop and remove existing container
docker stop quizspark-backend || true
docker rm quizspark-backend || true

# Clean up old application files
rm -rf /home/ubuntu/quizspark/* 