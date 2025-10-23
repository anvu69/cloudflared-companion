#!/bin/bash

# Xử lý tín hiệu shutdown
trap 'kill ${CLOUDFLARED_PID}' SIGTERM SIGINT

# 1. Khởi chạy cloudflared ở chế độ nền
# Token được truyền qua biến môi trường $TUNNEL_TOKEN
echo "Starting cloudflared..."
cloudflared tunnel --no-autoupdate --config /etc/cloudflared/config.yml run &
CLOUDFLARED_PID=$!

# 2. Khởi chạy docker-gen ở chế độ chính (foreground)
# Nó sẽ tạo config và gửi SIGHUP (reload) cho cloudflared
echo "Starting docker-gen..."
docker-gen \
    -watch \
    -wait 5s:10s \
    -notify "kill -SIGHUP ${CLOUDFLARED_PID}" \
    /etc/docker-gen/config.tmpl \
    /etc/cloudflared/config.yml

# Chờ cloudflared (nếu docker-gen bị lỗi)
wait ${CLOUDFLARED_PID}