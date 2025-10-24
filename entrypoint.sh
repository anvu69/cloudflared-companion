#!/bin/bash

# Handle shutdown signals
trap 'kill ${CLOUDFLARED_PID}' SIGTERM SIGINT

# 1. Start cloudflared in background
# Token is passed via environment variable $TUNNEL_TOKEN
echo "Starting cloudflared..."
cloudflared tunnel --no-autoupdate --config /etc/cloudflared/config.yml run &
CLOUDFLARED_PID=$!

# 2. Start docker-gen in foreground
# It will generate config and send SIGHUP (reload) signal to cloudflared
echo "Starting docker-gen..."
docker-gen \
    -watch \
    -wait 5s:10s \
    -notify "kill -SIGHUP ${CLOUDFLARED_PID}" \
    /etc/docker-gen/config.tmpl \
    /etc/cloudflared/config.yml

# Wait for cloudflared (if docker-gen fails)
wait ${CLOUDFLARED_PID}