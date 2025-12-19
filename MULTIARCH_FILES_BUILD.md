# 多架构文件镜像构建指南

本文档说明如何构建包含 AMD64 和 ARM64 两个架构文件的单一镜像。

## 概述

与镜像仓库使用 Docker multi-platform manifest 不同，文件服务器采用 **单一镜像包含所有架构文件** 的方式：

```
kubespray-files 镜像
└── /opt/k8s/k8s/
    ├── dl.k8s.io/release/v1.29.10/bin/linux/
    │   ├── amd64/          ← AMD64 架构文件
    │   │   ├── kubelet
    │   │   ├── kubectl
    │   │   └── kubeadm
    │   └── arm64/          ← ARM64 架构文件
    │       ├── kubelet
    │       ├── kubectl
    │       └── kubeadm
    └── ...
```

## 为什么这样设计？

### 文件服务器 vs 镜像仓库

| 特性 | 文件服务器 | 镜像仓库 |
|------|-----------|---------|
| 内容类型 | 二进制文件、压缩包 | 容器镜像 |
| 架构选择 | 通过 URL 路径 | Docker 自动选择 |
| 实现方式 | 单镜像包含所有架构 | Multi-platform manifest |
| 优势 | 简单、统一部署 | Docker 原生支持 |

### 双层架构支持的优势

#### 镜像平台层（Docker Multi-Platform）
- 镜像本身支持 **linux/amd64** 和 **linux/arm64**
- 可以在任何架构的服务器上运行
- Docker 自动选择匹配的镜像平台

#### 文件内容层（包含所有架构）
- 镜像内容包含所有目标架构的二进制文件
- 一个文件服务器为所有架构的节点提供服务
- Kubespray 根据节点架构自动选择正确的文件路径

**综合优势：**
1. **灵活部署**: 在任何架构的服务器上部署（AMD64 或 ARM64）
2. **统一服务**: 一个实例服务所有架构的节点
3. **混合集群友好**: 完美支持混合架构 Kubernetes 集群
4. **简化管理**: 无需为不同架构维护多个文件服务器

## 文件列表

项目维护两个架构的文件列表：

### temp/files-amd64.list
```
https://dl.k8s.io/release/v1.29.10/bin/linux/amd64/kubelet
https://dl.k8s.io/release/v1.29.10/bin/linux/amd64/kubectl
https://dl.k8s.io/release/v1.29.10/bin/linux/amd64/kubeadm
https://github.com/etcd-io/etcd/releases/download/v3.5.16/etcd-v3.5.16-linux-amd64.tar.gz
...
```

### temp/files-arm64.list
```
https://dl.k8s.io/release/v1.29.10/bin/linux/arm64/kubelet
https://dl.k8s.io/release/v1.29.10/bin/linux/arm64/kubectl
https://dl.k8s.io/release/v1.29.10/bin/linux/arm64/kubeadm
https://github.com/etcd-io/etcd/releases/download/v3.5.16/etcd-v3.5.16-linux-arm64.tar.gz
...
```

## 构建方法

### 方法 1: 使用构建脚本（推荐）

**Linux/macOS**:
```bash
chmod +x scripts/build-multiarch-files.sh
./scripts/build-multiarch-files.sh
```

**Windows PowerShell**:
```powershell
.\scripts\build-multiarch-files.ps1
```

### 方法 2: 使用 Makefile

```bash
make build-files
```

### 方法 3: 手动构建

```bash
# 1. 生成 Dockerfile
cat > Dockerfile.files << 'EOF'
FROM nginx:1.25.2-alpine

RUN apk add --no-cache wget
RUN mkdir -p /opt/k8s/k8s

COPY temp/files-amd64.list /tmp/files-amd64.list
COPY temp/files-arm64.list /tmp/files-arm64.list

RUN cd /opt/k8s && \
    echo "=== 下载 AMD64 架构文件 ===" && \
    wget -x -P k8s -i /tmp/files-amd64.list && \
    echo "=== 下载 ARM64 架构文件 ===" && \
    wget -x -P k8s -i /tmp/files-arm64.list && \
    rm /tmp/files-amd64.list /tmp/files-arm64.list

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
}
NGINX_EOF

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
EOF

# 2. 构建镜像
docker build -f Dockerfile.files -t kubespray-files:v0.1.0-2.25.0 .
```

## 构建过程

构建脚本会执行以下步骤：

1. **检查文件列表**: 确保 `temp/files-amd64.list` 和 `temp/files-arm64.list` 存在
2. **生成 Dockerfile**: 创建包含下载逻辑的 Dockerfile
3. **下载文件**: 
   - 从 `files-amd64.list` 下载 AMD64 文件
   - 从 `files-arm64.list` 下载 ARM64 文件
   - 保持原始 URL 路径结构
4. **配置 Nginx**: 启用目录浏览
5. **构建镜像**: 打包为 Docker 镜像

## 验证构建

### 1. 检查镜像

```bash
docker images | grep kubespray-files
```

### 2. 启动测试容器

```bash
docker run -d -p 8080:80 --name test-files kubespray-files:v0.1.0-2.25.0
```

### 3. 验证文件结构

```bash
# 浏览器访问
http://localhost:8080/k8s/

# 或使用 curl
curl http://localhost:8080/k8s/dl.k8s.io/release/v1.29.10/bin/linux/

# 检查 AMD64 文件
curl -I http://localhost:8080/k8s/dl.k8s.io/release/v1.29.10/bin/linux/amd64/kubectl

# 检查 ARM64 文件
curl -I http://localhost:8080/k8s/dl.k8s.io/release/v1.29.10/bin/linux/arm64/kubectl
```

### 4. 清理测试容器

```bash
docker stop test-files
docker rm test-files
```

## 使用镜像

### 部署文件服务器

```bash
# Linux/macOS
./scripts/deploy-offline-files.sh

# Windows PowerShell
.\scripts\deploy-offline-files.ps1
```

### 配置 Kubespray

```yaml
# inventory/mycluster/group_vars/all/offline.yml
files_repo: "http://192.168.1.100:8080/k8s"
```

Kubespray 会根据节点架构自动选择正确的文件：

- **AMD64 节点**: 下载 `/k8s/dl.k8s.io/release/v1.29.10/bin/linux/amd64/kubectl`
- **ARM64 节点**: 下载 `/k8s/dl.k8s.io/release/v1.29.10/bin/linux/arm64/kubectl`

## 镜像大小

由于包含两个架构的所有文件，镜像会比单架构版本大：

- **单架构镜像**: ~2-3 GB
- **多架构镜像**: ~4-6 GB

这是正常的，因为包含了两倍的文件。

## 更新文件列表

### 1. 编辑文件列表

```bash
# 编辑 AMD64 文件列表
vim temp/files-amd64.list

# 编辑 ARM64 文件列表
vim temp/files-arm64.list
```

### 2. 重新构建

```bash
./scripts/build-multiarch-files.sh
```

### 3. 推送到仓库

```bash
docker tag kubespray-files:v0.1.0-2.25.0 your-username/kubespray-files:v0.1.0-2.25.0
docker push your-username/kubespray-files:v0.1.0-2.25.0
```

## 故障排查

### 问题 1: 文件列表不存在

**错误**: "找不到架构文件列表"

**解决**:
```bash
# 检查文件是否存在
ls -l temp/files-*.list

# 如果不存在，从模板创建
cp temp/files.list.template temp/files-amd64.list
cp temp/files.list.template temp/files-arm64.list

# 编辑文件列表，替换架构标识
sed -i 's/amd64/amd64/g' temp/files-amd64.list
sed -i 's/amd64/arm64/g' temp/files-arm64.list
```

### 问题 2: 下载失败

**错误**: "wget: unable to resolve host address"

**解决**:
1. 检查网络连接
2. 验证 URL 是否正确
3. 检查文件是否存在于上游

```bash
# 测试单个 URL
wget --spider https://dl.k8s.io/release/v1.29.10/bin/linux/amd64/kubectl
```

### 问题 3: 构建时间过长

**原因**: 需要下载大量文件（4-6 GB）

**优化**:
1. 使用更快的网络
2. 使用代理或镜像站
3. 在 CI/CD 中构建（如 GitHub Actions）

### 问题 4: 磁盘空间不足

**错误**: "no space left on device"

**解决**:
```bash
# 检查磁盘空间
df -h

# 清理 Docker 缓存
docker system prune -a

# 删除旧镜像
docker rmi $(docker images -f "dangling=true" -q)
```

## 最佳实践

### 1. 使用 CI/CD 构建

在 GitHub Actions 或其他 CI/CD 平台构建，避免本地网络和磁盘限制。

### 2. 缓存文件

如果需要频繁构建，可以先下载文件到本地：

```bash
# 创建缓存目录
mkdir -p cache/k8s

# 下载文件
cd cache
wget -x -P k8s -i ../temp/files-amd64.list
wget -x -P k8s -i ../temp/files-arm64.list

# 修改 Dockerfile 使用本地文件
COPY cache/k8s /opt/k8s/k8s
```

### 3. 版本管理

为每个版本打标签：

```bash
docker tag kubespray-files:v0.1.0-2.25.0 kubespray-files:latest
docker tag kubespray-files:v0.1.0-2.25.0 kubespray-files:v0.1.0
```

### 4. 定期更新

定期更新文件列表，确保使用最新版本的组件。

## 相关文档

- [多架构支持指南](MULTI_ARCH_GUIDE.md) - 完整的多架构说明
- [脚本说明](scripts/README.md) - 所有脚本的详细说明
- [快速开始](QUICKSTART.md) - 快速部署指南

## 获取帮助

如遇问题，请：
1. 查看构建日志
2. 参考故障排查部分
3. 在 GitHub 创建 Issue

---

**提示**: 构建过程需要下载大量文件，首次构建可能需要 30-60 分钟，具体取决于网络速度。
