# 镜像仓库启动问题修复

## 问题描述

运行镜像仓库时出现错误：
```bash
docker run -d -p 5000:5000 --name kubespray-registry \
  sgfoot/kubespray-images:v0.1.0-2.25.0

# 错误日志
configuration error: open /etc/docker/registry/config.yml: no such file or directory
```

## 原因分析

Dockerfile 中的 CMD 指向了 `/etc/docker/registry/config.yml`，但该文件在镜像中不存在。

### 问题代码
```dockerfile
FROM registry:3
COPY registry-data-${TARGETARCH} /var/lib/registry
ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["/etc/docker/registry/config.yml"]  # ❌ 文件不存在
```

## 解决方案

### 方案 1: 使用默认配置（临时方案）

不指定配置文件，让 registry 使用默认配置：

```bash
docker run -d \
  -p 5000:5000 \
  --name kubespray-registry \
  --entrypoint /entrypoint.sh \
  sgfoot/kubespray-images:v0.1.0-2.25.0 \
  /etc/docker/registry/config.yml
```

或者使用环境变量配置：

```bash
docker run -d \
  -p 5000:5000 \
  --name kubespray-registry \
  -e REGISTRY_STORAGE_FILESYSTEM_ROOTDIRECTORY=/var/lib/registry \
  --entrypoint /entrypoint.sh \
  sgfoot/kubespray-images:v0.1.0-2.25.0 \
  /etc/docker/registry/config.yml
```

### 方案 2: 挂载配置文件（推荐）

创建本地配置文件并挂载：

```bash
# 1. 创建配置文件
mkdir -p /opt/registry/config
cat > /opt/registry/config/config.yml << 'EOF'
version: 0.1
log:
  fields:
    service: registry
storage:
  cache:
    blobdescriptor: inmemory
  filesystem:
    rootdirectory: /var/lib/registry
http:
  addr: :5000
  headers:
    X-Content-Type-Options: [nosniff]
health:
  storagedriver:
    enabled: true
    interval: 10s
    threshold: 3
EOF

# 2. 启动容器并挂载配置
docker run -d \
  -p 5000:5000 \
  --name kubespray-registry \
  -v /opt/registry/config/config.yml:/etc/docker/registry/config.yml:ro \
  sgfoot/kubespray-images:v0.1.0-2.25.0
```

### 方案 3: 使用 HTTPS（生产环境推荐）

```bash
# 1. 生成证书
mkdir -p /opt/registry/certs
openssl req -newkey rsa:4096 -nodes -sha256 \
  -keyout /opt/registry/certs/hub.kubespray.local.key \
  -x509 -days 365 \
  -out /opt/registry/certs/hub.kubespray.local.crt \
  -subj "/CN=hub.kubespray.local" \
  -addext "subjectAltName=DNS:hub.kubespray.local,DNS:localhost,IP:127.0.0.1"

# 2. 创建配置文件
mkdir -p /opt/registry/config
cat > /opt/registry/config/config.yml << 'EOF'
version: 0.1
log:
  fields:
    service: registry
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
  tls:
    certificate: /certs/hub.kubespray.local.crt
    key: /certs/hub.kubespray.local.key
health:
  storagedriver:
    enabled: true
    interval: 10s
    threshold: 3
EOF

# 3. 配置 hosts
echo "127.0.0.1 hub.kubespray.local" | sudo tee -a /etc/hosts

# 4. 启动容器
docker run -d \
  -p 5000:5000 \
  --name kubespray-registry \
  -v /opt/registry/certs:/certs:ro \
  -v /opt/registry/config/config.yml:/etc/docker/registry/config.yml:ro \
  sgfoot/kubespray-images:v0.1.0-2.25.0

# 5. 验证
curl -k https://hub.kubespray.local:5000/v2/_catalog
```

### 方案 4: 使用部署脚本（最简单）

使用项目提供的部署脚本，自动处理所有配置：

```bash
# Linux/macOS
./scripts/deploy-offline-registry.sh

# Windows PowerShell
.\scripts\deploy-offline-registry.ps1
```

## 已修复的 Dockerfile

新的 Dockerfile 已在镜像中包含配置文件：

```dockerfile
FROM registry:3

# Copy pre-synced registry data
ARG TARGETARCH
COPY registry-data-${TARGETARCH} /var/lib/registry

# Create registry config
RUN mkdir -p /etc/docker/registry && \
    cat > /etc/docker/registry/config.yml << 'CONFIG_EOF'
version: 0.1
log:
  fields:
    service: registry
storage:
  cache:
    blobdescriptor: inmemory
  filesystem:
    rootdirectory: /var/lib/registry
http:
  addr: :5000
  headers:
    X-Content-Type-Options: [nosniff]
health:
  storagedriver:
    enabled: true
    interval: 10s
    threshold: 3
CONFIG_EOF

# Create startup script
RUN cat > /docker-entrypoint.sh << 'SCRIPT_EOF'
#!/bin/sh
set -e

echo "=========================================="
echo "Kubespray Offline Registry"
echo "=========================================="
echo "Architecture: $(uname -m)"
echo "Registry: hub.kubespray.local:5000"
echo ""
echo "Usage:"
echo "  List images: curl http://hub.kubespray.local:5000/v2/_catalog"
echo "  Pull image:  docker pull hub.kubespray.local:5000/k8s/pause:3.9"
echo "=========================================="

exec /entrypoint.sh "$@"
SCRIPT_EOF

RUN chmod +x /docker-entrypoint.sh

EXPOSE 5000

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["/etc/docker/registry/config.yml"]
```

## 验证修复

### 1. 检查容器日志

```bash
docker logs kubespray-registry
```

**成功的日志**:
```
==========================================
Kubespray Offline Registry
==========================================
Architecture: x86_64
Registry: hub.kubespray.local:5000

Usage:
  List images: curl http://hub.kubespray.local:5000/v2/_catalog
  Pull image:  docker pull hub.kubespray.local:5000/k8s/pause:3.9
==========================================
time="2024-12-19T..." level=info msg="listening on [::]:5000"
```

### 2. 测试 API

```bash
# 列出所有镜像
curl http://localhost:5000/v2/_catalog

# 查看特定镜像的标签
curl http://localhost:5000/v2/k8s/pause/tags/list

# 拉取测试镜像
docker pull localhost:5000/k8s/pause:3.9
```

### 3. 检查镜像内容

```bash
# 进入容器
docker exec -it kubespray-registry sh

# 检查配置文件
cat /etc/docker/registry/config.yml

# 检查镜像数据
ls -la /var/lib/registry/docker/registry/v2/repositories/

# 退出
exit
```

## 更新时间线

| 日期 | 版本 | 状态 |
|------|------|------|
| 2024-12-19 | v0.1.0-2.25.0 | ❌ 配置文件缺失 |
| 2024-12-19 | v0.1.1-2.25.0 | ✅ 已修复（待发布） |

## 临时解决方案（当前版本）

如果你已经拉取了有问题的镜像，使用以下命令启动：

```bash
# 停止并删除旧容器
docker stop kubespray-registry 2>/dev/null || true
docker rm kubespray-registry 2>/dev/null || true

# 创建配置文件
mkdir -p /opt/registry/config
cat > /opt/registry/config/config.yml << 'EOF'
version: 0.1
log:
  fields:
    service: registry
storage:
  cache:
    blobdescriptor: inmemory
  filesystem:
    rootdirectory: /var/lib/registry
http:
  addr: :5000
  headers:
    X-Content-Type-Options: [nosniff]
health:
  storagedriver:
    enabled: true
    interval: 10s
    threshold: 3
EOF

# 启动容器（挂载配置文件）
docker run -d \
  -p 5000:5000 \
  --restart always \
  --name kubespray-registry \
  -v /opt/registry/config/config.yml:/etc/docker/registry/config.yml:ro \
  sgfoot/kubespray-images:v0.1.0-2.25.0

# 验证
sleep 3
curl http://localhost:5000/v2/_catalog
```

## 使用脚本（推荐）

项目提供的部署脚本已经处理了这个问题：

```bash
# Linux/macOS
git clone https://github.com/sgfoot/kubespray-offline.git
cd kubespray-offline
./scripts/deploy-offline-registry.sh

# Windows PowerShell
git clone https://github.com/sgfoot/kubespray-offline.git
cd kubespray-offline
.\scripts\deploy-offline-registry.ps1
```

脚本会自动：
1. 创建配置文件
2. 生成证书
3. 配置 hosts
4. 启动容器
5. 验证服务

## 下一步

1. **等待新版本**: 下一次 GitHub Actions 构建会包含修复
2. **使用脚本**: 使用项目提供的部署脚本
3. **手动修复**: 按照上述临时解决方案操作

## 相关链接

- **GitHub Issue**: [待创建]
- **部署脚本**: [scripts/deploy-offline-registry.sh](../scripts/deploy-offline-registry.sh)
- **Docker Hub**: https://hub.docker.com/r/sgfoot/kubespray-images

---

**更新日期**: 2024-12-19  
**状态**: 已修复，等待新版本发布
