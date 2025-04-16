#!/bin/bash
set -e

# Source environment variables
source /home/ubuntu/quizspark/.env

# Run Docker container with environment variables
docker run -d \
  --name quizspark-backend \
  -p 3000:3000 \
  -e SUPABASE_URL="$SUPABASE_URL" \
  -e SUPABASE_KEY="$SUPABASE_KEY" \
  quizspark-backend 