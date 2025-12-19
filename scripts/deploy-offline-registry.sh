#!/bin/bash
# 部署离线镜像仓库脚本

set -e

REGISTRY_HOST="${REGISTRY_HOST:-hub.kubespray.local}"
REGISTRY_PORT="${REGISTRY_PORT:-5000}"
CERT_DIR="${CERT_DIR:-/opt/registry/certs}"
IMAGE_NAME="${IMAGE_NAME:-kubespray-images:v0.1.0-2.25.0}"

echo "=== Kubespray 离线镜像仓库部署 ==="
echo "Registry Host: ${REGISTRY_HOST}"
echo "Registry Port: ${REGISTRY_PORT}"
echo "Image: ${IMAGE_NAME}"
echo ""

# 创建证书目录
echo "1. 创建证书目录..."
mkdir -p "${CERT_DIR}"

# 生成自签名证书
if [ ! -f "${CERT_DIR}/${REGISTRY_HOST}.crt" ]; then
    echo "2. 生成自签名证书..."
    openssl req -newkey rsa:4096 -nodes -sha256 \
        -keyout "${CERT_DIR}/${REGISTRY_HOST}.key" \
        -x509 -days 365 \
        -out "${CERT_DIR}/${REGISTRY_HOST}.crt" \
        -subj "/CN=${REGISTRY_HOST}" \
        -addext "subjectAltName=DNS:${REGISTRY_HOST},DNS:localhost,IP:127.0.0.1"
    echo "证书已生成: ${CERT_DIR}/${REGISTRY_HOST}.crt"
else
    echo "2. 证书已存在，跳过生成"
fi

# 配置 hosts
echo "3. 配置 /etc/hosts..."
if ! grep -q "${REGISTRY_HOST}" /etc/hosts; then
    echo "127.0.0.1 ${REGISTRY_HOST}" | sudo tee -a /etc/hosts
    echo "已添加 hosts 记录"
else
    echo "hosts 记录已存在"
fi

# 停止并删除旧容器
if docker ps -a | grep -q kubespray-registry; then
    echo "4. 停止旧容器..."
    docker stop kubespray-registry || true
    docker rm kubespray-registry || true
fi

# 启动镜像仓库
echo "5. 启动镜像仓库..."
docker run -d \
    -p ${REGISTRY_PORT}:5000 \
    --restart always \
    --name kubespray-registry \
    -v "${CERT_DIR}:/certs" \
    -e REGISTRY_HTTP_TLS_CERTIFICATE="/certs/${REGISTRY_HOST}.crt" \
    -e REGISTRY_HTTP_TLS_KEY="/certs/${REGISTRY_HOST}.key" \
    "${IMAGE_NAME}"

# 等待启动
echo "6. 等待服务启动..."
sleep 5

# 验证
echo "7. 验证服务..."
if curl -k "https://${REGISTRY_HOST}:${REGISTRY_PORT}/v2/_catalog" > /dev/null 2>&1; then
    echo "✓ 镜像仓库启动成功！"
    echo ""
    echo "=== 使用方法 ==="
    echo "查看镜像列表:"
    echo "  curl -k https://${REGISTRY_HOST}:${REGISTRY_PORT}/v2/_catalog"
    echo ""
    echo "查看特定镜像标签:"
    echo "  curl -k https://${REGISTRY_HOST}:${REGISTRY_PORT}/v2/k8s/pause/tags/list"
    echo ""
    echo "配置 Docker 使用此仓库:"
    echo "  sudo mkdir -p /etc/docker/certs.d/${REGISTRY_HOST}:${REGISTRY_PORT}"
    echo "  sudo cp ${CERT_DIR}/${REGISTRY_HOST}.crt /etc/docker/certs.d/${REGISTRY_HOST}:${REGISTRY_PORT}/ca.crt"
else
    echo "✗ 镜像仓库启动失败，请检查日志:"
    echo "  docker logs kubespray-registry"
    exit 1
fi
