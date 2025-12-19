#!/bin/bash
# 部署离线文件服务器脚本

set -e

FILES_PORT="${FILES_PORT:-8080}"
IMAGE_NAME="${IMAGE_NAME:-kubespray-files:v0.1.0-2.25.0}"

echo "=== Kubespray 离线文件服务器部署 ==="
echo "Port: ${FILES_PORT}"
echo "Image: ${IMAGE_NAME}"
echo ""

# 停止并删除旧容器
if docker ps -a | grep -q kubespray-files; then
    echo "1. 停止旧容器..."
    docker stop kubespray-files || true
    docker rm kubespray-files || true
fi

# 启动文件服务器
echo "2. 启动文件服务器..."
docker run -d \
    -p ${FILES_PORT}:80 \
    --restart always \
    --name kubespray-files \
    "${IMAGE_NAME}"

# 等待启动
echo "3. 等待服务启动..."
sleep 3

# 验证
echo "4. 验证服务..."
if curl -s "http://localhost:${FILES_PORT}/k8s/" > /dev/null; then
    echo "✓ 文件服务器启动成功！"
    echo ""
    echo "=== 使用方法 ==="
    echo "浏览文件列表:"
    echo "  http://localhost:${FILES_PORT}/k8s/"
    echo ""
    echo "下载示例 (kubectl):"
    echo "  curl -O http://localhost:${FILES_PORT}/k8s/dl.k8s.io/release/v1.29.10/bin/linux/amd64/kubectl"
    echo ""
    echo "配置 Kubespray:"
    echo "  files_repo: \"http://$(hostname -I | awk '{print $1}'):${FILES_PORT}/k8s\""
else
    echo "✗ 文件服务器启动失败，请检查日志:"
    echo "  docker logs kubespray-files"
    exit 1
fi
