# PowerShell 脚本 - 构建包含多架构文件的镜像

param(
    [string]$Version = "v0.1.0-2.25.0",
    [string]$ImageName = "kubespray-files:$Version"
)

Write-Host "=== 构建多架构文件服务器镜像 ===" -ForegroundColor Green
Write-Host "Image: $ImageName"
Write-Host ""

# 检查文件列表是否存在
if (-not (Test-Path "temp/files-amd64.list") -or -not (Test-Path "temp/files-arm64.list")) {
    Write-Host "错误: 找不到架构文件列表" -ForegroundColor Red
    Write-Host "请确保以下文件存在:"
    Write-Host "  - temp/files-amd64.list"
    Write-Host "  - temp/files-arm64.list"
    exit 1
}

# 创建 Dockerfile
Write-Host "1. 生成 Dockerfile..." -ForegroundColor Yellow
$dockerfileContent = @'
FROM nginx:1.25.2-alpine

# 安装下载工具
RUN apk add --no-cache wget

# 创建目录结构
RUN mkdir -p /opt/k8s/k8s

# 复制文件列表
COPY temp/files-amd64.list /tmp/files-amd64.list
COPY temp/files-arm64.list /tmp/files-arm64.list

# 下载所有架构的文件
RUN cd /opt/k8s && \
    echo "=== 下载 AMD64 架构文件 ===" && \
    wget -x -P k8s -i /tmp/files-amd64.list && \
    echo "=== 下载 ARM64 架构文件 ===" && \
    wget -x -P k8s -i /tmp/files-arm64.list && \
    rm /tmp/files-amd64.list /tmp/files-arm64.list && \
    echo "=== 文件下载完成 ==="

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
'@

Set-Content -Path "Dockerfile.files" -Value $dockerfileContent

# 构建镜像
Write-Host "2. 构建 Docker 镜像..." -ForegroundColor Yellow
docker build -f Dockerfile.files -t $ImageName .

if ($LASTEXITCODE -ne 0) {
    Write-Host "✗ 镜像构建失败！" -ForegroundColor Red
    exit 1
}

# 验证
Write-Host ""
Write-Host "3. 验证镜像..." -ForegroundColor Yellow
docker images | Select-String "kubespray-files"

Write-Host ""
Write-Host "✓ 多架构文件服务器镜像构建完成！" -ForegroundColor Green
Write-Host ""
Write-Host "镜像包含以下架构的文件:" -ForegroundColor Cyan
Write-Host "  - AMD64 (x86_64)"
Write-Host "  - ARM64 (aarch64)"
Write-Host ""
Write-Host "下一步:" -ForegroundColor Cyan
Write-Host "  1. 测试镜像: docker run -d -p 8080:80 $ImageName"
Write-Host "  2. 推送镜像: docker push $ImageName"
Write-Host "  3. 部署服务: .\scripts\deploy-offline-files.ps1"
