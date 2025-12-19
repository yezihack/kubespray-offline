#!/bin/bash
# 修复镜像仓库配置问题

set -e

echo "=== Kubespray 镜像仓库修复脚本 ==="
echo ""

# 停止并删除旧容器
if docker ps -a | grep -q kubespray-registry; then
    echo "1. 停止旧容器..."
    docker stop kubespray-registry 2>/dev/null || true
    docker rm kubespray-registry 2>/dev/null || true
fi

# 创建配置目录
echo "2. 创建配置文件..."
mkdir -p /opt/registry/config

# 创建配置文件
cat > /opt/registry/config/config.yml << 'EOF'
version: 0.1
log:
  fields:
    service: registry
  level: info
storage:
  cache:
    blobdescriptor: inmemory
  filesystem:
    rootdirectory: /var/lib/registry
  delete:
    enabled: true
http:
  addr: :5000
  headers:
    X-Content-Type-Options: [nosniff]
    Access-Control-Allow-Origin: ['*']
    Access-Control-Allow-Methods: ['HEAD', 'GET', 'OPTIONS', 'DELETE']
    Access-Control-Allow-Headers: ['Authorization', 'Accept']
    Access-Control-Max-Age: [1728000]
    Access-Control-Allow-Credentials: [true]
    Access-Control-Expose-Headers: ['Docker-Content-Digest']
health:
  storagedriver:
    enabled: true
    interval: 10s
    threshold: 3
EOF

echo "✓ 配置文件已创建: /opt/registry/config/config.yml"

# 启动容器
echo "3. 启动镜像仓库..."
docker run -d \
  -p 5000:5000 \
  --restart always \
  --name kubespray-registry \
  -v /opt/registry/config/config.yml:/etc/docker/registry/config.yml:ro \
  sgfoot/kubespray-images:v0.1.0-2.25.0

if [ $? -ne 0 ]; then
    echo "✗ 启动失败！"
    exit 1
fi

# 等待启动
echo "4. 等待服务启动..."
sleep 5

# 验证
echo "5. 验证服务..."
if curl -s http://localhost:5000/v2/_catalog > /dev/null; then
    echo "✓ 镜像仓库启动成功！"
    echo ""
    echo "=== 使用方法 ==="
    echo "查看镜像列表:"
    echo "  curl http://localhost:5000/v2/_catalog"
    echo ""
    echo "查看特定镜像标签:"
    echo "  curl http://localhost:5000/v2/k8s/pause/tags/list"
    echo ""
    echo "拉取镜像:"
    echo "  docker pull localhost:5000/k8s/pause:3.9"
else
    echo "✗ 服务验证失败，请检查日志:"
    echo "  docker logs kubespray-registry"
    exit 1
fi
