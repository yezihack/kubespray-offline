#!/bin/bash
# 构建包含多架构文件的镜像

set -e

VERSION="${VERSION:-v0.1.0-2.25.0}"
IMAGE_NAME="${IMAGE_NAME:-kubespray-files:${VERSION}}"

echo "=== 构建多架构文件服务器镜像 ==="
echo "Image: ${IMAGE_NAME}"
echo ""

# 检查文件列表是否存在
if [ ! -f "temp/files-amd64.list" ] || [ ! -f "temp/files-arm64.list" ]; then
    echo "错误: 找不到架构文件列表"
    echo "请确保以下文件存在:"
    echo "  - temp/files-amd64.list"
    echo "  - temp/files-arm64.list"
    exit 1
fi

# 创建 Dockerfile
echo "1. 生成 Dockerfile..."
cat > Dockerfile.files << 'EOF'
FROM nginx:1.25.2-alpine

# 安装下载工具
RUN apk add --no-cache wget

# 创建目录结构
RUN mkdir -p /opt/k8s/k8s

# 复制文件列表
COPY temp/files-amd64.list /tmp/files-amd64.list
COPY temp/files-arm64.list /tmp/files-arm64.list

# Create download script with error handling
RUN cat > /tmp/download.sh << 'DOWNLOAD_EOF'
#!/bin/sh
set -e

download_file() {
    local url="$1"
    local max_retries=3
    local retry=0
    
    echo "Downloading: $url"
    
    while [ $retry -lt $max_retries ]; do
        if wget -x -P k8s --timeout=60 --tries=3 --waitretry=5 "$url"; then
            echo "✓ Success: $url"
            return 0
        else
            retry=$((retry + 1))
            echo "⚠ Retry $retry/$max_retries: $url"
            sleep 5
        fi
    done
    
    echo "✗ Failed after $max_retries attempts: $url"
    return 1
}

cd /opt/k8s

echo "=== Downloading AMD64 architecture files ==="
failed_files=""
total_files=0
success_files=0

while IFS= read -r url; do
    if [ -n "$url" ] && [ "${url#\#}" = "$url" ]; then
        total_files=$((total_files + 1))
        if download_file "$url"; then
            success_files=$((success_files + 1))
        else
            failed_files="$failed_files\n$url"
        fi
    fi
done < /tmp/files-amd64.list

echo "AMD64: $success_files/$total_files files downloaded"

echo "=== Downloading ARM64 architecture files ==="
total_files=0
success_files=0

while IFS= read -r url; do
    if [ -n "$url" ] && [ "${url#\#}" = "$url" ]; then
        total_files=$((total_files + 1))
        if download_file "$url"; then
            success_files=$((success_files + 1))
        else
            failed_files="$failed_files\n$url"
        fi
    fi
done < /tmp/files-arm64.list

echo "ARM64: $success_files/$total_files files downloaded"

if [ -n "$failed_files" ]; then
    echo "=== Failed downloads ==="
    echo "$failed_files"
    echo "⚠ Some files failed to download, but continuing..."
fi

echo "=== Download complete ==="
DOWNLOAD_EOF

# Make script executable and run it
RUN chmod +x /tmp/download.sh && \
    /tmp/download.sh && \
    rm /tmp/download.sh /tmp/files-amd64.list /tmp/files-arm64.list

# 配置 Nginx
RUN cat > /etc/nginx/conf.d/default.conf << 'NGINX_EOF'
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    
    location /k8s/ {
        root /opt/k8s;
        index index.html index.htm;
        autoindex on;
        autoindex_exact_size off;
        autoindex_localtime on;
    }
    
    location /health {
        access_log off;
        return 200 "healthy\n";
        add_header Content-Type text/plain;
    }
}
NGINX_EOF

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
EOF

# 构建镜像
echo "2. 构建 Docker 镜像..."
docker build -f Dockerfile.files -t "${IMAGE_NAME}" .

# 验证
echo ""
echo "3. 验证镜像..."
docker images | grep kubespray-files

echo ""
echo "✓ 多架构文件服务器镜像构建完成！"
echo ""
echo "镜像包含以下架构的文件:"
echo "  - AMD64 (x86_64)"
echo "  - ARM64 (aarch64)"
echo ""
echo "下一步:"
echo "  1. 测试镜像: docker run -d -p 8080:80 ${IMAGE_NAME}"
echo "  2. 推送镜像: docker push ${IMAGE_NAME}"
echo "  3. 部署服务: ./scripts/deploy-offline-files.sh"
