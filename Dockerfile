# Sử dụng base image nhỏ gọn
FROM alpine:3.18

# Cài đặt các gói cần thiết
RUN apk add --no-cache curl bash

# 1. Cài đặt cloudflared
RUN curl -L --output cloudflared https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 \
    && chmod +x cloudflared \
    && mv cloudflared /usr/local/bin/

# 2. Cài đặt docker-gen
ENV DOCKER_GEN_VERSION 0.7.7
RUN curl -L https://github.com/jwilder/docker-gen/releases/download/$DOCKER_GEN_VERSION/docker-gen-linux-amd64-$DOCKER_GEN_VERSION.tar.gz \
    | tar -C /usr/local/bin -xz docker-gen

# Tạo thư mục config
RUN mkdir -p /etc/cloudflared/

# Sao chép template và entrypoint
COPY config.tmpl.j2 /etc/docker-gen/config.tmpl
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Entrypoint sẽ quản lý 2 tiến trình
ENTRYPOINT ["/entrypoint.sh"]