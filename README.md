# Kubespray 离线文件/镜像构建

[![Docker Pulls](https://img.shields.io/docker/pulls/sgfoot/kubespray-files)](https://hub.docker.com/r/sgfoot/kubespray-files)
[![GitHub](https://img.shields.io/github/license/sgfoot/kubespray-offline)](LICENSE)

为 Kubespray v2.25.0 (Kubernetes v1.29.10) 提供完整的离线部署解决方案。

## ✨ 特性

- 🚀 **一键部署** - 使用脚本快速部署离线服务
- 🏗️ **多架构支持** - 支持 AMD64 和 ARM64 (x86_64, ARM64, Apple Silicon, AWS Graviton)
- 📦 **完整离线** - 包含所有二进制文件和容器镜像
- 🔄 **自动构建** - GitHub Actions 自动构建和发布
- 🐳 **Docker 化** - 基于 Docker 容器，易于部署和管理
- 🌐 **混合集群** - 一套服务支持不同架构的节点

## 🚀 快速开始

### 1. 拉取镜像

```bash
docker pull sgfoot/kubespray-files:v0.1.0-2.25.0
docker pull sgfoot/kubespray-images:v0.1.0-2.25.0
```

### 2. 部署服务

**Linux/macOS:**

```bash
# 部署文件服务器
./scripts/deploy-offline-files.sh

# 部署镜像仓库
./scripts/deploy-offline-registry.sh
```

**Windows PowerShell:**

```powershell
# 部署文件服务器
.\scripts\deploy-offline-files.ps1

# 部署镜像仓库
.\scripts\deploy-offline-registry.ps1
```

### 3. 配置 Kubespray

```yaml
# inventory/mycluster/group_vars/all/offline.yml
files_repo: "http://192.168.1.100:8080/k8s"
registry_host: "hub.kubespray.local:5000"
```

详细配置参考 [QUICKSTART.md](QUICKSTART.md)

## 📦 镜像说明

### kubespray-files (文件服务器)

**镜像**: `sgfoot/kubespray-files:v0.1.0-2.25.0`

包含 Kubernetes 及相关组件的二进制文件：

- Kubernetes 组件 (kubelet, kubectl, kubeadm v1.29.10)
- 容器运行时 (containerd, cri-o, cri-dockerd)
- 网络插件 (Calico, Cilium, CNI plugins)
- 工具 (helm, crictl, etcd, skopeo, yq)

**多架构支持**:

- 镜像平台: linux/amd64, linux/arm64
- 文件内容: 包含 AMD64 和 ARM64 的所有二进制文件
- 可在任何架构上部署，为所有架构提供服务

### kubespray-images (镜像仓库)

**镜像**: `sgfoot/kubespray-images:v0.1.0-2.25.0`

包含 100+ 容器镜像：

- Kubernetes 核心组件
- 网络插件 (Calico, Cilium, Flannel)
- DNS (CoreDNS, NodeLocalDNS)
- 存储、监控、Ingress 等

**多架构支持**:

- 支持 linux/amd64 和 linux/arm64
- Docker 自动选择匹配的镜像

## 🏗️ 多架构支持

### 支持的平台

- ✅ **AMD64** (x86_64) - Intel/AMD 处理器
- ✅ **ARM64** (aarch64) - ARM 处理器
  - Apple Silicon (M1/M2/M3)
  - AWS Graviton
  - 树莓派 4/5
  - 华为鲲鹏、飞腾

### 混合架构集群

一套离线服务支持混合架构集群：

```bash
# 在任何架构的服务器上部署
docker run -d -p 8080:80 sgfoot/kubespray-files:v0.1.0-2.25.0
docker run -d -p 5000:5000 sgfoot/kubespray-images:v0.1.0-2.25.0

# 自动支持所有架构的节点
# - AMD64 节点 → 获取 AMD64 文件和镜像
# - ARM64 节点 → 获取 ARM64 文件和镜像
```

## 📋 使用场景

### 场景 1: 纯 AMD64 集群

```bash
# 在 x86_64 服务器上部署离线服务
docker run -d -p 8080:80 sgfoot/kubespray-files:v0.1.0-2.25.0
docker run -d -p 5000:5000 sgfoot/kubespray-images:v0.1.0-2.25.0
```

### 场景 2: 纯 ARM64 集群

```bash
# 在 ARM64 服务器上部署离线服务
docker run -d -p 8080:80 sgfoot/kubespray-files:v0.1.0-2.25.0
docker run -d -p 5000:5000 sgfoot/kubespray-images:v0.1.0-2.25.0
```

### 场景 3: 混合架构集群

```bash
# 在任意架构服务器上部署，支持所有节点
docker run -d -p 8080:80 sgfoot/kubespray-files:v0.1.0-2.25.0
docker run -d -p 5000:5000 sgfoot/kubespray-images:v0.1.0-2.25.0

# Kubespray 自动根据节点架构选择正确的文件和镜像
```

## 🛠️ 部署方式

### 方式 1: 使用脚本（推荐）

```bash
# Linux/macOS
./scripts/deploy-offline-files.sh
./scripts/deploy-offline-registry.sh

# Windows
.\scripts\deploy-offline-files.ps1
.\scripts\deploy-offline-registry.ps1
```

### 方式 2: Docker Compose

```bash
docker-compose up -d
```

### 方式 3: 手动部署

```bash
# 文件服务器
docker run -d -p 8080:80 --name kubespray-files \
  sgfoot/kubespray-files:v0.1.0-2.25.0

# 镜像仓库 (HTTPS)
docker run -d -p 5000:5000 --name kubespray-registry \
  -v /opt/registry/certs:/certs \
  -e REGISTRY_HTTP_TLS_CERTIFICATE=/certs/hub.kubespray.local.crt \
  -e REGISTRY_HTTP_TLS_KEY=/certs/hub.kubespray.local.key \
  sgfoot/kubespray-images:v0.1.0-2.25.0
```

## 📚 文档

- **[QUICKSTART.md](QUICKSTART.md)** - 完整的快速开始指南
- **[examples/kubespray-offline-config.yml](examples/kubespray-offline-config.yml)** - Kubespray 配置示例
- **[scripts/README.md](scripts/README.md)** - 部署脚本说明

### 详细文档 (docs/)

- **[GET_STARTED.md](docs/GET_STARTED.md)** - 5 分钟快速开始
- **[MULTI_ARCH_GUIDE.md](docs/MULTI_ARCH_GUIDE.md)** - 多架构支持指南
- **[ARCHITECTURE_DESIGN.md](docs/ARCHITECTURE_DESIGN.md)** - 架构设计说明
- **[CONTRIBUTING.md](docs/CONTRIBUTING.md)** - 贡献指南
- **[CHANGELOG.md](docs/CHANGELOG.md)** - 更新日志
- **[DOCUMENTATION_INDEX.md](docs/DOCUMENTATION_INDEX.md)** - 完整文档索引

## 🔧 配置 Kubespray

### 基本配置

编辑 `inventory/mycluster/group_vars/all/offline.yml`:

```yaml
# 文件服务器地址
files_repo: "http://192.168.1.100:8080/k8s"

# 覆盖下载地址
dl_k8s_io_url: "{{ files_repo }}/dl.k8s.io"
github_url: "{{ files_repo }}/github.com"
storage_googleapis_url: "{{ files_repo }}/storage.googleapis.com"
get_helm_url: "{{ files_repo }}/get.helm.sh"

# 镜像仓库配置
registry_host: "hub.kubespray.local:5000"
kube_image_repo: "{{ registry_host }}/k8s/registry.k8s.io"
gcr_image_repo: "{{ registry_host }}/k8s"
docker_image_repo: "{{ registry_host }}/k8s/docker.io"
quay_image_repo: "{{ registry_host }}/k8s/quay.io"
```

### 节点配置

在所有节点上配置 hosts 和证书：

```bash
# 配置 hosts
echo "192.168.1.100 hub.kubespray.local" | sudo tee -a /etc/hosts

# 信任证书 (containerd)
sudo mkdir -p /etc/containerd/certs.d/hub.kubespray.local:5000
sudo cp /opt/registry/certs/hub.kubespray.local.crt \
  /etc/containerd/certs.d/hub.kubespray.local:5000/ca.crt
```

## 🐛 故障排查

### 文件下载失败

```bash
# 检查服务状态
docker logs kubespray-files

# 测试文件访问
curl http://192.168.1.100:8080/k8s/dl.k8s.io/release/v1.29.10/bin/linux/amd64/kubectl
```

### 镜像拉取失败

```bash
# 检查服务状态
docker logs kubespray-registry

# 测试镜像拉取
docker pull hub.kubespray.local:5000/k8s/pause:3.9

# 检查证书
openssl s_client -connect hub.kubespray.local:5000 -showcerts
```

### 架构不匹配

```bash
# 查看镜像支持的架构
docker manifest inspect sgfoot/kubespray-files:v0.1.0-2.25.0

# 验证文件内容
docker run --rm sgfoot/kubespray-files:v0.1.0-2.25.0 \
  ls -la /opt/k8s/k8s/dl.k8s.io/release/v1.29.10/bin/linux/
```

## 🔨 构建镜像

### 本地构建

```bash
# Linux/macOS
./scripts/build-multiarch-files.sh

# Windows
.\scripts\build-multiarch-files.ps1

# 使用 Makefile
make build-files
```

### GitHub Actions

推送到 main 分支或创建 tag 时自动构建。

需要配置 GitHub Secrets:

- `DOCKERHUB_USERNAME` - Docker Hub 用户名
- `DOCKERHUB_TOKEN` - Docker Hub 访问令牌

## 📊 镜像大小

| 镜像 | 压缩大小 | 解压大小 | 说明 |
|------|---------|---------|------|
| kubespray-files | ~1.5-2 GB | ~4-6 GB | 包含所有架构的二进制文件 |
| kubespray-images | ~3-4 GB | ~8-12 GB | 包含 100+ 容器镜像 |

## 🌟 版本信息

- **项目版本**: v0.1.0
- **Kubespray 版本**: v2.25.0
- **Kubernetes 版本**: v1.29.10
- **支持架构**: linux/amd64, linux/arm64

## 🤝 贡献

欢迎贡献！请查看 [CONTRIBUTING.md](docs/CONTRIBUTING.md)

## 📄 许可证

MIT License - 查看 [LICENSE](LICENSE) 文件

## 🔗 相关链接

- **Docker Hub**:
  - [kubespray-files](https://hub.docker.com/r/sgfoot/kubespray-files)
  - [kubespray-images](https://hub.docker.com/r/sgfoot/kubespray-images)
- **GitHub**: [kubespray-offline](https://github.com/sgfoot/kubespray-offline)
- **Kubespray**: [kubernetes-sigs/kubespray](https://github.com/kubernetes-sigs/kubespray)

## ⭐ 支持项目

如果这个项目对你有帮助，请给个 Star ⭐️

---

**维护者**: [sgfoot](https://github.com/sgfoot)  
**最后更新**: 2024-12
