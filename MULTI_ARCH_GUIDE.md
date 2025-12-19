# 多架构支持指南

本项目支持 linux/amd64 和 linux/arm64 两种架构，可以在 x86_64 和 ARM64 (如树莓派、Apple Silicon Mac、AWS Graviton) 等平台上运行。

## 支持的架构

### linux/amd64 (x86_64)
- Intel/AMD 处理器
- 大多数云服务器
- 传统 PC 和服务器

### linux/arm64 (aarch64)
- ARM64 处理器
- 树莓派 4/5
- Apple Silicon (M1/M2/M3)
- AWS Graviton
- 华为鲲鹏
- 飞腾处理器

## 自动架构选择

Docker 会自动选择与你的系统架构匹配的镜像：

```bash
# Docker 自动选择架构
docker pull sgfoot/kubespray-files:v0.1.0-2.25.0
docker pull sgfoot/kubespray-images:v0.1.0-2.25.0

# 查看镜像架构
docker image inspect sgfoot/kubespray-files:v0.1.0-2.25.0 | grep Architecture
```

## 手动指定架构

如果需要手动指定架构（例如在 x86_64 机器上拉取 arm64 镜像）：

```bash
# 拉取 amd64 版本
docker pull --platform linux/amd64 sgfoot/kubespray-files:v0.1.0-2.25.0

# 拉取 arm64 版本
docker pull --platform linux/arm64 sgfoot/kubespray-files:v0.1.0-2.25.0
```

## 架构特定标签

除了多架构 manifest，我们还提供架构特定的标签：

```bash
# amd64 专用标签
sgfoot/kubespray-files:v0.1.0-2.25.0-amd64
sgfoot/kubespray-images:v0.1.0-2.25.0-amd64

# arm64 专用标签
sgfoot/kubespray-files:v0.1.0-2.25.0-arm64
sgfoot/kubespray-images:v0.1.0-2.25.0-arm64
```

## 在不同平台上使用

### x86_64 服务器

```bash
# 自动使用 amd64 镜像
docker run -d -p 8080:80 --name kubespray-files \
  sgfoot/kubespray-files:v0.1.0-2.25.0
```

### ARM64 服务器（树莓派、AWS Graviton）

```bash
# 自动使用 arm64 镜像
docker run -d -p 8080:80 --name kubespray-files \
  sgfoot/kubespray-files:v0.1.0-2.25.0
```

### Apple Silicon Mac (M1/M2/M3)

```bash
# 自动使用 arm64 镜像
docker run -d -p 8080:80 --name kubespray-files \
  sgfoot/kubespray-files:v0.1.0-2.25.0

# 或使用 Rosetta 运行 amd64 镜像（性能较低）
docker run -d -p 8080:80 --platform linux/amd64 --name kubespray-files \
  sgfoot/kubespray-files:v0.1.0-2.25.0
```

## 混合架构集群

如果你的 Kubernetes 集群包含不同架构的节点：

### 1. 部署离线服务

在一台服务器上部署文件服务器和镜像仓库（任意架构）：

```bash
# 文件服务器（包含所有架构的文件）
docker run -d -p 8080:80 --name kubespray-files \
  sgfoot/kubespray-files:v0.1.0-2.25.0

# 镜像仓库（包含所有架构的镜像）
docker run -d -p 5000:5000 --name kubespray-registry \
  sgfoot/kubespray-images:v0.1.0-2.25.0
```

### 2. 配置 Kubespray

Kubespray 会根据节点架构自动下载对应的文件：

```yaml
# inventory/mycluster/group_vars/all/offline.yml
files_repo: "http://192.168.1.100:8080/k8s"
registry_host: "hub.kubespray.local:5000"

# Kubespray 会自动根据 ansible_architecture 选择正确的文件
# amd64 节点: 下载 /k8s/dl.k8s.io/release/v1.29.10/bin/linux/amd64/kubectl
# arm64 节点: 下载 /k8s/dl.k8s.io/release/v1.29.10/bin/linux/arm64/kubectl
```

### 3. 镜像自动选择

容器镜像会根据节点架构自动拉取：

```bash
# 在 amd64 节点上
docker pull hub.kubespray.local:5000/k8s/pause:3.9
# 自动拉取 amd64 版本

# 在 arm64 节点上
docker pull hub.kubespray.local:5000/k8s/pause:3.9
# 自动拉取 arm64 版本
```

## 文件服务器多架构支持

### 双层多架构支持

文件服务器镜像 (`kubespray-files`) 提供完整的双层多架构支持：

#### 1. 镜像平台支持（Docker Multi-Platform）
镜像本身是多架构的，可以在不同平台上运行：
- **linux/amd64** - 在 x86_64 服务器上运行
- **linux/arm64** - 在 ARM64 服务器、Apple Silicon、AWS Graviton 上运行

#### 2. 文件内容支持（包含所有架构文件）
镜像内容包含 **AMD64 和 ARM64 两个架构的所有文件**：

```
/opt/k8s/k8s/
├── dl.k8s.io/release/v1.29.10/bin/linux/
│   ├── amd64/
│   │   ├── kubelet
│   │   ├── kubectl
│   │   └── kubeadm
│   └── arm64/
│       ├── kubelet
│       ├── kubectl
│       └── kubeadm
├── github.com/etcd-io/etcd/releases/download/v3.5.16/
│   ├── etcd-v3.5.16-linux-amd64.tar.gz
│   └── etcd-v3.5.16-linux-arm64.tar.gz
└── ...
```

### 文件列表

项目维护两个架构的文件列表：

- **temp/files-amd64.list**: AMD64 架构文件
- **temp/files-arm64.list**: ARM64 架构文件

构建时，两个列表的文件都会被下载到同一个镜像中。

### 构建多架构文件镜像

```bash
# Linux/macOS
./scripts/build-multiarch-files.sh

# Windows PowerShell
.\scripts\build-multiarch-files.ps1

# 或使用 Makefile
make build-files
```

这会创建一个支持多平台运行且包含所有架构文件的镜像：
- **镜像平台**: linux/amd64 和 linux/arm64（可在任何架构上运行）
- **文件内容**: 包含 AMD64 和 ARM64 的所有二进制文件

Kubespray 会根据节点架构自动选择正确的文件路径。

## 构建过程

### 文件服务器 (kubespray-files)

文件服务器使用 **单一镜像包含所有架构文件** 的方式：

1. **下载所有架构文件**: 从 `files-amd64.list` 和 `files-arm64.list` 下载
2. **统一目录结构**: 所有文件保存在 `/opt/k8s/k8s/` 下
3. **路径自动匹配**: Kubespray 根据节点架构选择对应路径

```dockerfile
# Dockerfile.files
FROM nginx:1.25.2-alpine
RUN apk add --no-cache wget
RUN mkdir -p /opt/k8s/k8s

# 下载所有架构的文件
COPY temp/files-amd64.list /tmp/files-amd64.list
COPY temp/files-arm64.list /tmp/files-arm64.list
RUN cd /opt/k8s && \
    wget -x -P k8s -i /tmp/files-amd64.list && \
    wget -x -P k8s -i /tmp/files-arm64.list
```

### 镜像仓库 (kubespray-images)

镜像仓库使用 **Docker multi-platform manifest** 方式：

1. **并行构建**: amd64 和 arm64 同时构建
2. **架构特定标签**: 推送 `-amd64` 和 `-arm64` 标签
3. **创建 manifest**: 合并为多架构 manifest
4. **自动选择**: Docker 根据平台自动选择

```yaml
# GitHub Actions
strategy:
  matrix:
    arch: [amd64, arm64]
```

## 验证多架构支持

### 查看 manifest

```bash
# 查看镜像支持的架构
docker manifest inspect sgfoot/kubespray-files:v0.1.0-2.25.0

# 输出示例
{
  "manifests": [
    {
      "platform": {
        "architecture": "amd64",
        "os": "linux"
      }
    },
    {
      "platform": {
        "architecture": "arm64",
        "os": "linux"
      }
    }
  ]
}
```

### 测试不同架构

```bash
# 在 x86_64 机器上测试 arm64 镜像（需要 QEMU）
docker run --platform linux/arm64 --rm sgfoot/kubespray-files:v0.1.0-2.25.0 uname -m
# 输出: aarch64

# 在 ARM64 机器上测试 amd64 镜像（需要 QEMU）
docker run --platform linux/amd64 --rm sgfoot/kubespray-files:v0.1.0-2.25.0 uname -m
# 输出: x86_64
```

## 性能考虑

### 原生架构 vs 模拟

- **原生架构**: 最佳性能
- **QEMU 模拟**: 性能损失 50-90%

建议：
- 生产环境使用原生架构镜像
- 开发测试可以使用模拟

### Apple Silicon 特殊说明

Apple Silicon (M1/M2/M3) 可以通过 Rosetta 2 运行 amd64 镜像：

```bash
# 原生 arm64（推荐）
docker run sgfoot/kubespray-files:v0.1.0-2.25.0

# 通过 Rosetta 运行 amd64（兼容性更好，性能稍低）
docker run --platform linux/amd64 sgfoot/kubespray-files:v0.1.0-2.25.0
```

## 故障排查

### 问题 1: 架构不匹配

**错误**: "exec format error" 或 "no matching manifest"

**解决**:
```bash
# 检查系统架构
uname -m

# 检查镜像支持的架构
docker manifest inspect sgfoot/kubespray-files:v0.1.0-2.25.0

# 手动指定架构
docker pull --platform linux/arm64 sgfoot/kubespray-files:v0.1.0-2.25.0
```

### 问题 2: QEMU 未安装

**错误**: "exec user process caused: exec format error"

**解决**:
```bash
# 安装 QEMU
# Ubuntu/Debian
sudo apt-get install qemu-user-static

# macOS
brew install qemu

# 注册 QEMU
docker run --rm --privileged multiarch/qemu-user-static --reset -p yes
```

### 问题 3: 构建失败

**错误**: GitHub Actions 构建某个架构失败

**解决**:
1. 检查文件列表是否正确
2. 验证所有文件 URL 对该架构可用
3. 检查 GitHub Actions 日志

## 最佳实践

### 1. 使用多架构 manifest

```bash
# 推荐：让 Docker 自动选择
docker pull sgfoot/kubespray-files:v0.1.0-2.25.0

# 不推荐：手动指定架构（除非必要）
docker pull sgfoot/kubespray-files:v0.1.0-2.25.0-amd64
```

### 2. 混合集群配置

```yaml
# 使用统一的配置，Kubespray 会自动处理架构差异
files_repo: "http://192.168.1.100:8080/k8s"
registry_host: "hub.kubespray.local:5000"
```

### 3. 测试所有架构

```bash
# 在部署前测试两个架构
docker run --platform linux/amd64 --rm sgfoot/kubespray-files:v0.1.0-2.25.0 ls /opt/k8s/k8s
docker run --platform linux/arm64 --rm sgfoot/kubespray-files:v0.1.0-2.25.0 ls /opt/k8s/k8s
```

## 参考资源

- [Docker Multi-platform Images](https://docs.docker.com/build/building/multi-platform/)
- [Docker Buildx](https://docs.docker.com/buildx/working-with-buildx/)
- [QEMU User Emulation](https://www.qemu.org/docs/master/user/main.html)
- [Kubernetes Multi-arch](https://kubernetes.io/docs/concepts/cluster-administration/manage-deployment/#using-multiple-architectures)

## 支持的组件架构矩阵

| 组件 | amd64 | arm64 | 备注 |
|------|-------|-------|------|
| Kubernetes | ✅ | ✅ | 官方支持 |
| etcd | ✅ | ✅ | 官方支持 |
| containerd | ✅ | ✅ | 官方支持 |
| Calico | ✅ | ✅ | 官方支持 |
| Cilium | ✅ | ✅ | 官方支持 |
| Flannel | ✅ | ✅ | 官方支持 |
| CoreDNS | ✅ | ✅ | 官方支持 |
| nginx | ✅ | ✅ | 官方支持 |
| registry | ✅ | ✅ | 官方支持 |

---

**提示**: 如有其他架构需求，请创建 GitHub Issue。
