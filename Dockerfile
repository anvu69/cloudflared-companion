# Use lightweight base image
FROM alpine:3.18

# Set version arguments
ARG VERSION=0.1.0
ARG CLOUDFLARED_VERSION=latest
ARG DOCKER_GEN_VERSION=0.7.7

LABEL version="${VERSION}"
LABEL cloudflared_version="${CLOUDFLARED_VERSION}"
LABEL docker_gen_version="${DOCKER_GEN_VERSION}"
LABEL description="Cloudflared Companion - Automatic Cloudflare Tunnel configuration for Docker"
LABEL maintainer="anvu69"

# Install required packages
RUN apk add --no-cache curl bash

# 1. Install cloudflared
RUN curl -L --output cloudflared https://github.com/cloudflare/cloudflared/releases/${CLOUDFLARED_VERSION}/download/cloudflared-linux-amd64 \
    && chmod +x cloudflared \
    && mv cloudflared /usr/local/bin/

# 2. Install docker-gen
RUN curl -L https://github.com/jwilder/docker-gen/releases/download/${DOCKER_GEN_VERSION}/docker-gen-linux-amd64-${DOCKER_GEN_VERSION}.tar.gz \
    | tar -C /usr/local/bin -xz docker-gen

# Create config directory
RUN mkdir -p /etc/cloudflared/

# Copy template and entrypoint
COPY config.tmpl.j2 /etc/docker-gen/config.tmpl
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Entrypoint manages both processes
ENTRYPOINT ["/entrypoint.sh"]