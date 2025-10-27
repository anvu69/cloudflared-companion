# Cloudflared Companion

[![Version](https://img.shields.io/badge/version-0.1.0-blue?style=flat-square)](VERSION)
[![Cloudflared](https://img.shields.io/badge/cloudflared-latest-green?style=flat-square&logo=cloudflare)](https://github.com/cloudflare/cloudflared)
[![Docker Gen](https://img.shields.io/badge/docker--gen-0.7.7-orange?style=flat-square&logo=docker)](https://github.com/jwilder/docker-gen)
[![GitHub License](https://img.shields.io/github/license/anvu69/cloudflared-companion?style=flat-square)](LICENSE)
[![Docker Image](https://img.shields.io/badge/docker-ghcr.io-blue?style=flat-square&logo=docker)](https://github.com/anvu69/cloudflared-companion/pkgs/container/cloudflared-companion)
[![GitHub Stars](https://img.shields.io/github/stars/anvu69/cloudflared-companion?style=flat-square&logo=github)](https://github.com/anvu69/cloudflared-companion)
[![GitHub Issues](https://img.shields.io/github/issues/anvu69/cloudflared-companion?style=flat-square&logo=github)](https://github.com/anvu69/cloudflared-companion/issues)
[![GitHub Forks](https://img.shields.io/github/forks/anvu69/cloudflared-companion?style=flat-square&logo=github)](https://github.com/anvu69/cloudflared-companion/network/members)

**English** | [Tiếng Việt](#tiếng-việt)

## Overview

Cloudflared Companion is an automated Docker-based solution that combines **Cloudflare Tunnel (cloudflared)** with **docker-gen** to dynamically configure Cloudflare services for your containerized applications. Inspired by [nginx-proxy](https://github.com/nginx-proxy/nginx-proxy), it automatically detects Docker containers and generates Cloudflare Tunnel configurations without manual intervention.

## Features

- 🚀 **Automatic Configuration**: Dynamically generates Cloudflare Tunnel configs based on Docker container labels
- 🔄 **Hot Reload**: Automatically reloads cloudflared when container labels change
- 🐳 **Docker Native**: Works seamlessly with Docker and Docker Compose
- 📦 **Lightweight**: Built on Alpine Linux with minimal dependencies
- 🔐 **Secure**: Uses Cloudflare Tunnel for secure, encrypted connections
- 🎯 **Simple Setup**: Just add labels to your containers and you're done

## How It Works

The project uses a two-process architecture:

1. **cloudflared** (background): Runs the Cloudflare Tunnel and exposes your services
2. **docker-gen** (foreground): Watches Docker events and generates configuration files

### Architecture Flow

```text
Docker Events
    ↓
docker-gen (watches containers)
    ↓
Generates config.yml from template
    ↓
Sends SIGHUP to cloudflared
    ↓
cloudflared reloads configuration
    ↓
Services exposed via Cloudflare Tunnel
```

## Prerequisites

- Docker and Docker Compose
- Cloudflare account with Tunnel configured
- Cloudflare Tunnel token (from `~/.cloudflared/cert.pem` or environment variable)

## Installation

### 1. Pull the Docker Image

```bash
docker pull ghcr.io/anvu69/cloudflared-companion:latest
```

### 2. Set Up Your Tunnel Token

Get your Cloudflare Tunnel token and make it available to the container:

```bash
# Option 1: Via environment variable
export TUNNEL_TOKEN="your-tunnel-token-here"

# Option 2: Via Docker secret (recommended for production)
echo "your-tunnel-token-here" | docker secret create tunnel_token -
```

### 3. Create docker-compose.yml

Copy the example file and customize it:

```bash
cp docker-compose.example.yml docker-compose.yml
cp .env.example .env
# Edit .env with your Cloudflare Tunnel token
```

Or create manually:

```yaml
version: '3.8'

services:
  cloudflared-companion:
    image: ghcr.io/anvu69/cloudflared-companion:latest
    environment:
      ACCOUNT_NAME: 'my-account'
      TUNNEL_TOKEN: '${TUNNEL_TOKEN}'
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
    restart: unless-stopped

  # Your application service
  my-app:
    image: nginx:latest
    labels:
      cloudflared_account: 'my-account'
      cloudflared_hostname: 'myapp.example.com'
      cloudflared_service: 'http://my-app:80'
```

## Configuration

### Environment Variables

| Variable       | Required | Description                                              |
| -------------- | -------- | -------------------------------------------------------- |
| `ACCOUNT_NAME` | Yes      | Your Cloudflare account name (used to filter containers) |
| `TUNNEL_TOKEN` | Yes      | Your Cloudflare Tunnel token                             |

### Container Labels

Add these labels to your Docker containers to expose them via Cloudflare Tunnel:

| Label                  | Required | Description                                        |
| ---------------------- | -------- | -------------------------------------------------- |
| `cloudflared_account`  | Yes      | Must match `ACCOUNT_NAME` environment variable     |
| `cloudflared_hostname` | Yes      | The hostname to expose (e.g., `myapp.example.com`) |
| `cloudflared_service`  | Yes      | The service URL (e.g., `http://my-app:80`)         |

### Example: Multiple Services

```yaml
version: '3.8'

services:
  cloudflared-companion:
    image: ghcr.io/anvu69/cloudflared-companion:latest
    environment:
      ACCOUNT_NAME: 'production'
      TUNNEL_TOKEN: '${TUNNEL_TOKEN}'
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
    restart: unless-stopped

  web:
    image: nginx:latest
    labels:
      cloudflared_account: 'production'
      cloudflared_hostname: 'web.example.com'
      cloudflared_service: 'http://web:80'

  api:
    image: myapi:latest
    labels:
      cloudflared_account: 'production'
      cloudflared_hostname: 'api.example.com'
      cloudflared_service: 'http://api:3000'

  admin:
    image: admin-panel:latest
    labels:
      cloudflared_account: 'production'
      cloudflared_hostname: 'admin.example.com'
      cloudflared_service: 'http://admin:8080'
```

## Usage

### Start the Service

```bash
docker-compose up -d
```

### View Logs

```bash
docker-compose logs -f cloudflared-companion
```

### Add a New Service

Simply add a new container with the appropriate labels:

```bash
docker run -d \
  --label cloudflared_account=production \
  --label cloudflared_hostname=newapp.example.com \
  --label cloudflared_service=http://newapp:80 \
  myimage:latest
```

The configuration will be automatically updated and reloaded.

### Remove a Service

Stop or remove the container, and the configuration will be automatically updated.

## Troubleshooting

### Configuration Not Updating

1. Check that the container labels match exactly
2. Verify `ACCOUNT_NAME` matches the `cloudflared_account` label
3. Check logs: `docker-compose logs cloudflared-companion`

### Connection Issues

1. Verify your Cloudflare Tunnel token is valid
2. Check that the service URL is accessible from the container
3. Ensure Docker socket is properly mounted: `/var/run/docker.sock:/var/run/docker.sock:ro`

### Cloudflared Not Starting

1. Verify the tunnel token is correct
2. Check Cloudflare dashboard for tunnel status
3. Review logs for error messages

## Project Structure

```text
.
├── Dockerfile                    # Multi-stage build for cloudflared and docker-gen
├── .dockerignore                 # Docker build ignore file
├── entrypoint.sh                # Main entry point managing both processes
├── config.tmpl.j2               # Jinja2 template for cloudflared config
├── VERSION                       # Current version (0.1.0)
├── CHANGELOG.md                 # Version history and changes
├── LICENSE                       # MIT License
├── README.md                     # This file
├── docker-compose.example.yml   # Example docker-compose configuration
├── .env.example                 # Example environment variables
├── .github/
│   ├── workflows/
│   │   └── publish.yml          # CI/CD pipeline for automated builds
│   └── ISSUE_TEMPLATE/
│       ├── bug_report.md        # Bug report template
│       ├── feature_request.md   # Feature request template
│       ├── documentation.md     # Documentation issue template
│       └── config.yml           # Issue template configuration
└── .gitignore                    # Git ignore file
```

## Building from Source

```bash
git clone https://github.com/anvu69/cloudflared-companion.git
cd cloudflared-companion
docker build -t cloudflared-companion:latest .
```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Inspiration

This project is inspired by [nginx-proxy](https://github.com/nginx-proxy/nginx-proxy), which provides similar automatic configuration for nginx. Cloudflared Companion brings the same convenience to Cloudflare Tunnel users.

## Related Projects

- [cloudflared](https://github.com/cloudflare/cloudflared) - Cloudflare Tunnel client
- [docker-gen](https://github.com/jwilder/docker-gen) - Generate files from Docker container metadata
- [nginx-proxy](https://github.com/nginx-proxy/nginx-proxy) - Automated nginx proxy for Docker

---

## Tiếng Việt

## Tổng Quan

Cloudflared Companion là một giải pháp tự động hóa dựa trên Docker kết hợp **Cloudflare Tunnel (cloudflared)** với **docker-gen** để động cấu hình các dịch vụ Cloudflare cho các ứng dụng được container hóa của bạn. Lấy cảm hứng từ [nginx-proxy](https://github.com/nginx-proxy/nginx-proxy), nó tự động phát hiện các container Docker và tạo cấu hình Cloudflare Tunnel mà không cần can thiệp thủ công.

## Tính Năng

- 🚀 **Cấu Hình Tự Động**: Động tạo cấu hình Cloudflare Tunnel dựa trên nhãn container Docker
- 🔄 **Tải Lại Nóng**: Tự động tải lại cloudflared khi nhãn container thay đổi
- 🐳 **Docker Native**: Hoạt động liền mạch với Docker và Docker Compose
- 📦 **Nhẹ Nhàng**: Xây dựng trên Alpine Linux với các phụ thuộc tối thiểu
- 🔐 **An Toàn**: Sử dụng Cloudflare Tunnel cho các kết nối được mã hóa an toàn
- 🎯 **Thiết Lập Đơn Giản**: Chỉ cần thêm nhãn vào container của bạn và bạn đã sẵn sàng

## Cách Hoạt Động

Dự án sử dụng kiến trúc hai tiến trình:

1. **cloudflared** (nền): Chạy Cloudflare Tunnel và expose các dịch vụ của bạn
2. **docker-gen** (foreground): Theo dõi các sự kiện Docker và tạo tệp cấu hình

### Luồng Kiến Trúc

```text
Sự Kiện Docker
    ↓
docker-gen (theo dõi container)
    ↓
Tạo config.yml từ template
    ↓
Gửi SIGHUP đến cloudflared
    ↓
cloudflared tải lại cấu hình
    ↓
Dịch vụ được expose qua Cloudflare Tunnel
```

## Yêu Cầu Trước

- Docker và Docker Compose
- Tài khoản Cloudflare với Tunnel được cấu hình
- Token Cloudflare Tunnel (từ `~/.cloudflared/cert.pem` hoặc biến môi trường)

## Cài Đặt

### 1. Kéo Docker Image

```bash
docker pull ghcr.io/anvu69/cloudflared-companion:latest
```

### 2. Thiết Lập Token Tunnel Của Bạn

Lấy token Cloudflare Tunnel của bạn và làm cho nó có sẵn cho container:

```bash
# Tùy chọn 1: Qua biến môi trường
export TUNNEL_TOKEN="your-tunnel-token-here"

# Tùy chọn 2: Qua Docker secret (được khuyến nghị cho production)
echo "your-tunnel-token-here" | docker secret create tunnel_token -
```

### 3. Tạo docker-compose.yml

Sao chép file ví dụ và tùy chỉnh:

```bash
cp docker-compose.example.yml docker-compose.yml
cp .env.example .env
# Chỉnh sửa .env với token Cloudflare Tunnel của bạn
```

Hoặc tạo thủ công:

```yaml
version: '3.8'

services:
  cloudflared-companion:
    image: ghcr.io/anvu69/cloudflared-companion:latest
    environment:
      ACCOUNT_NAME: 'my-account'
      TUNNEL_TOKEN: '${TUNNEL_TOKEN}'
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
    restart: unless-stopped

  # Dịch vụ ứng dụng của bạn
  my-app:
    image: nginx:latest
    labels:
      cloudflared_account: 'my-account'
      cloudflared_hostname: 'myapp.example.com'
      cloudflared_service: 'http://my-app:80'
```

## Cấu Hình

### Biến Môi Trường

| Biến           | Bắt Buộc | Mô Tả                                                            |
| -------------- | -------- | ---------------------------------------------------------------- |
| `ACCOUNT_NAME` | Có       | Tên tài khoản Cloudflare của bạn (được sử dụng để lọc container) |
| `TUNNEL_TOKEN` | Có       | Token Cloudflare Tunnel của bạn                                  |

### Nhãn Container

Thêm các nhãn này vào container Docker của bạn để expose chúng qua Cloudflare Tunnel:

| Nhãn                   | Bắt Buộc | Mô Tả                                              |
| ---------------------- | -------- | -------------------------------------------------- |
| `cloudflared_account`  | Có       | Phải khớp với biến môi trường `ACCOUNT_NAME`       |
| `cloudflared_hostname` | Có       | Tên máy chủ để expose (ví dụ: `myapp.example.com`) |
| `cloudflared_service`  | Có       | URL dịch vụ (ví dụ: `http://my-app:80`)            |

### Ví Dụ: Nhiều Dịch Vụ

```yaml
version: '3.8'

services:
  cloudflared-companion:
    image: ghcr.io/anvu69/cloudflared-companion:latest
    environment:
      ACCOUNT_NAME: 'production'
      TUNNEL_TOKEN: '${TUNNEL_TOKEN}'
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
    restart: unless-stopped

  web:
    image: nginx:latest
    labels:
      cloudflared_account: 'production'
      cloudflared_hostname: 'web.example.com'
      cloudflared_service: 'http://web:80'

  api:
    image: myapi:latest
    labels:
      cloudflared_account: 'production'
      cloudflared_hostname: 'api.example.com'
      cloudflared_service: 'http://api:3000'

  admin:
    image: admin-panel:latest
    labels:
      cloudflared_account: 'production'
      cloudflared_hostname: 'admin.example.com'
      cloudflared_service: 'http://admin:8080'
```

## Sử Dụng

### Khởi Động Dịch Vụ

```bash
docker-compose up -d
```

### Xem Nhật Ký

```bash
docker-compose logs -f cloudflared-companion
```

### Thêm Dịch Vụ Mới

Chỉ cần thêm một container mới với các nhãn thích hợp:

```bash
docker run -d \
  --label cloudflared_account=production \
  --label cloudflared_hostname=newapp.example.com \
  --label cloudflared_service=http://newapp:80 \
  myimage:latest
```

Cấu hình sẽ được tự động cập nhật và tải lại.

### Xóa Dịch Vụ

Dừng hoặc xóa container, cấu hình sẽ được tự động cập nhật.

## Khắc Phục Sự Cố

### Cấu Hình Không Cập Nhật

1. Kiểm tra xem nhãn container có khớp chính xác không
2. Xác minh `ACCOUNT_NAME` khớp với nhãn `cloudflared_account`
3. Kiểm tra nhật ký: `docker-compose logs cloudflared-companion`

### Vấn Đề Kết Nối

1. Xác minh token Cloudflare Tunnel của bạn có hợp lệ không
2. Kiểm tra xem URL dịch vụ có thể truy cập được từ container không
3. Đảm bảo Docker socket được gắn kết đúng: `/var/run/docker.sock:/var/run/docker.sock:ro`

### Cloudflared Không Khởi Động

1. Xác minh token tunnel là chính xác
2. Kiểm tra bảng điều khiển Cloudflare để xem trạng thái tunnel
3. Xem lại nhật ký để tìm thông báo lỗi

## Cấu Trúc Dự Án

```text
.
├── Dockerfile                    # Build đa giai đoạn cho cloudflared và docker-gen
├── .dockerignore                 # Tệp ignore cho Docker build
├── entrypoint.sh                # Điểm vào chính quản lý cả hai tiến trình
├── config.tmpl.j2               # Template Jinja2 cho cấu hình cloudflared
├── VERSION                       # Phiên bản hiện tại (0.1.0)
├── CHANGELOG.md                 # Lịch sử phiên bản và thay đổi
├── LICENSE                       # Giấy phép MIT
├── README.md                     # Tệp này
├── docker-compose.example.yml   # Ví dụ cấu hình docker-compose
├── .env.example                 # Ví dụ biến môi trường
├── .github/
│   ├── workflows/
│   │   └── publish.yml          # Pipeline CI/CD cho các build tự động
│   └── ISSUE_TEMPLATE/
│       ├── bug_report.md        # Mẫu báo cáo lỗi
│       ├── feature_request.md   # Mẫu yêu cầu tính năng
│       ├── documentation.md     # Mẫu vấn đề tài liệu
│       └── config.yml           # Cấu hình mẫu issue
└── .gitignore                    # Tệp ignore cho Git
```

## Xây Dựng Từ Nguồn

```bash
git clone https://github.com/anvu69/cloudflared-companion.git
cd cloudflared-companion
docker build -t cloudflared-companion:latest .
```

## Đóng Góp

Chúng tôi hoan nghênh các đóng góp! Vui lòng tự do gửi Pull Request.

## Giấy Phép

Dự án này được cấp phép theo Giấy phép MIT - xem tệp LICENSE để biết chi tiết.

## Cảm Hứng

Dự án này được lấy cảm hứng từ [nginx-proxy](https://github.com/nginx-proxy/nginx-proxy), cung cấp cấu hình tự động tương tự cho nginx. Cloudflared Companion mang lại sự tiện lợi tương tự cho người dùng Cloudflare Tunnel.

## Các Dự Án Liên Quan

- [cloudflared](https://github.com/cloudflare/cloudflared) - Client Cloudflare Tunnel
- [docker-gen](https://github.com/jwilder/docker-gen) - Tạo tệp từ siêu dữ liệu container Docker
- [nginx-proxy](https://github.com/nginx-proxy/nginx-proxy) - Proxy nginx tự động cho Docker
