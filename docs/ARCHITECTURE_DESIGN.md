# 多架构支持架构设计

本文档说明 kubespray-offline 项目的多架构支持设计。

## 设计概述

项目提供两个 Docker 镜像，采用不同的多架构策略：

### 1. 文件服务器 (kubespray-files)

**双层多架构支持**

#### 层 1: 镜像平台支持（Docker Multi-Platform）
```
sgfoot/kubespray-files:v0.1.0-2.25.0
├── Manifest (multi-platform)
│   ├── linux/amd64 → 镜像可在 x86_64 服务器上运行
│   └── linux/arm64 → 镜像可在 ARM64 服务器上运行
```

#### 层 2: 文件内容支持（包含所有架构）
```
镜像内容（无论运行在哪个平台）
└── /opt/k8s/k8s/
    ├── dl.k8s.io/.../linux/amd64/  ← AMD64 二进制文件
    ├── dl.k8s.io/.../linux/arm64/  ← ARM64 二进制文件
    ├── github.com/.../amd64.tar.gz
    └── github.com/.../arm64.tar.gz
```

**优势：**
- ✅ 在任何架构的服务器上部署
- ✅ 为所有架构的节点提供文件
- ✅ 一个实例支持混合架构集群

### 2. 镜像仓库 (kubespray-images)

**单层多架构支持（Docker Multi-Platform Manifest）**

```
sgfoot/kubespray-images:v0.1.0-2.25.0
├── Manifest (multi-platform)
│   ├── linux/amd64 → 包含 AMD64 容器镜像
│   └── linux/arm64 → 包含 ARM64 容器镜像
```

**优势：**
- ✅ Docker 原生多架构支持
- ✅ 自动选择匹配的镜像
- ✅ 标准的容器镜像分发方式

## 为什么采用不同策略？

### 文件服务器：为什么需要双层支持？

#### 问题场景
假设只有镜像平台支持（单层），没有文件内容支持：

```
场景 1: 在 AMD64 服务器上部署
├── 拉取 linux/amd64 镜像
└── 镜像只包含 AMD64 文件
    └── ❌ ARM64 节点无法获取文件

场景 2: 在 ARM64 服务器上部署
├── 拉取 linux/arm64 镜像
└── 镜像只包含 ARM64 文件
    └── ❌ AMD64 节点无法获取文件
```

#### 解决方案：双层支持

```
在任何架构的服务器上部署
├── Docker 自动拉取匹配的镜像平台
└── 镜像包含所有架构的文件
    ├── ✅ AMD64 节点获取 AMD64 文件
    └── ✅ ARM64 节点获取 ARM64 文件
```

### 镜像仓库：为什么单层就够？

容器镜像本身就是架构特定的：

```
Docker Registry 工作流程：
1. 节点请求镜像: docker pull hub.kubespray.local:5000/k8s/pause:3.9
2. Docker 检查节点架构: amd64 或 arm64
3. Registry 返回对应架构的镜像
4. ✅ 自动匹配，无需额外处理
```

## 实现细节

### 文件服务器构建流程

#### GitHub Actions 工作流

```yaml
# 单次构建，生成多平台镜像
- name: Build and push multi-arch files image
  uses: docker/build-push-action@v5
  with:
    platforms: linux/amd64,linux/arm64  # 镜像平台支持
    # Dockerfile 内部下载所有架构的文件
```

#### Dockerfile 逻辑

```dockerfile
FROM nginx:1.25.2-alpine

# 复制两个架构的文件列表
COPY temp/files-amd64.list /tmp/files-amd64.list
COPY temp/files-arm64.list /tmp/files-arm64.list

# 下载所有架构的文件（无论镜像运行在哪个平台）
RUN cd /opt/k8s && \
    wget -x -P k8s -i /tmp/files-amd64.list && \
    wget -x -P k8s -i /tmp/files-arm64.list
```

**关键点：**
- 构建时下载所有架构的文件
- 无论镜像运行在哪个平台，内容都相同
- 使用 Docker Buildx 的 multi-platform 功能

### 镜像仓库构建流程

#### GitHub Actions 工作流

```yaml
# Matrix 策略，分别构建
strategy:
  matrix:
    arch: [amd64, arm64]

# 每个架构单独构建
- name: Pull and save images for architecture
  run: |
    # 只拉取当前架构的镜像
    skopeo copy --override-arch ${{ matrix.arch }} ...

# 最后合并为 multi-platform manifest
- name: Create and push multi-arch manifest
  run: |
    docker buildx imagetools create -t image:latest \
      image:latest-amd64 \
      image:latest-arm64
```

## 使用场景对比

### 场景 1: 纯 AMD64 集群

```bash
# 部署文件服务器（在 AMD64 服务器上）
docker run -d -p 8080:80 sgfoot/kubespray-files:v0.1.0-2.25.0
# → 自动拉取 linux/amd64 镜像
# → 镜像包含 AMD64 和 ARM64 文件（虽然只需要 AMD64）

# 部署镜像仓库（在 AMD64 服务器上）
docker run -d -p 5000:5000 sgfoot/kubespray-images:v0.1.0-2.25.0
# → 自动拉取 linux/amd64 镜像
# → 镜像只包含 AMD64 容器镜像
```

### 场景 2: 纯 ARM64 集群

```bash
# 部署文件服务器（在 ARM64 服务器上）
docker run -d -p 8080:80 sgfoot/kubespray-files:v0.1.0-2.25.0
# → 自动拉取 linux/arm64 镜像
# → 镜像包含 AMD64 和 ARM64 文件（虽然只需要 ARM64）

# 部署镜像仓库（在 ARM64 服务器上）
docker run -d -p 5000:5000 sgfoot/kubespray-images:v0.1.0-2.25.0
# → 自动拉取 linux/arm64 镜像
# → 镜像只包含 ARM64 容器镜像
```

### 场景 3: 混合架构集群（重点场景）

```bash
# 在 AMD64 服务器上部署离线服务
docker run -d -p 8080:80 sgfoot/kubespray-files:v0.1.0-2.25.0
# → 拉取 linux/amd64 镜像
# → ✅ 包含所有架构文件，支持混合集群

docker run -d -p 5000:5000 sgfoot/kubespray-images:v0.1.0-2.25.0
# → 拉取 linux/amd64 镜像
# → ❌ 只包含 AMD64 容器镜像
# → ⚠️ 需要额外部署 ARM64 镜像仓库？

# 解决方案：镜像仓库的 multi-platform manifest
# Registry 会根据节点架构自动返回正确的镜像
# 虽然 Registry 本身运行在 AMD64，但可以服务 ARM64 节点
```

**关键理解：**
- **文件服务器**: 需要在内容层包含所有架构（双层支持）
- **镜像仓库**: Registry 协议自动处理架构选择（单层支持）

## 镜像大小对比

### 文件服务器

| 类型 | 大小 | 说明 |
|------|------|------|
| 单架构版本 | ~2-3 GB | 只包含一个架构的文件 |
| 双层多架构版本 | ~4-6 GB | 包含两个架构的文件 |
| 镜像平台差异 | 几乎相同 | linux/amd64 和 linux/arm64 镜像大小相同 |

**为什么镜像平台大小相同？**
- 因为内容层相同（都包含所有架构的文件）
- 只有基础镜像（nginx:alpine）的平台不同
- 基础镜像很小（~10 MB），差异可忽略

### 镜像仓库

| 类型 | 大小 | 说明 |
|------|------|------|
| AMD64 版本 | ~3-4 GB | 只包含 AMD64 容器镜像 |
| ARM64 版本 | ~3-4 GB | 只包含 ARM64 容器镜像 |
| Multi-platform manifest | ~6-8 GB | 包含两个架构的镜像 |

## 技术实现要点

### 文件服务器

1. **Dockerfile 设计**
   - 使用 `COPY` 复制两个文件列表
   - 使用 `RUN` 在构建时下载所有文件
   - 不使用 `ARG TARGETARCH`（因为内容与平台无关）

2. **构建命令**
   ```bash
   docker buildx build \
     --platform linux/amd64,linux/arm64 \
     -t sgfoot/kubespray-files:v0.1.0-2.25.0 \
     --push .
   ```

3. **关键点**
   - 使用 `--platform` 指定多平台
   - 构建过程会为每个平台生成镜像
   - 但内容层完全相同（都下载所有架构的文件）

### 镜像仓库

1. **Dockerfile 设计**
   - 使用 `ARG TARGETARCH` 区分架构
   - 复制架构特定的 registry 数据
   - 每个架构的内容不同

2. **构建命令**
   ```bash
   # 分别构建
   docker buildx build --platform linux/amd64 \
     -t sgfoot/kubespray-images:v0.1.0-2.25.0-amd64 --push .
   
   docker buildx build --platform linux/arm64 \
     -t sgfoot/kubespray-images:v0.1.0-2.25.0-arm64 --push .
   
   # 创建 manifest
   docker buildx imagetools create -t sgfoot/kubespray-images:v0.1.0-2.25.0 \
     sgfoot/kubespray-images:v0.1.0-2.25.0-amd64 \
     sgfoot/kubespray-images:v0.1.0-2.25.0-arm64
   ```

## 最佳实践

### 部署建议

1. **文件服务器**
   - 在任何架构的服务器上部署都可以
   - 推荐在网络较好的服务器上部署（因为镜像较大）
   - 一个实例即可支持所有节点

2. **镜像仓库**
   - 在任何架构的服务器上部署都可以
   - Registry 协议会自动处理架构选择
   - 一个实例即可支持所有节点

### 网络优化

```bash
# 如果带宽有限，可以只下载需要的架构
# 但这会失去混合集群支持

# 方案 1: 使用架构特定的文件列表（需要自己构建）
# 方案 2: 部署后删除不需要的架构文件（不推荐）
# 方案 3: 接受较大的镜像大小（推荐）
```

## 总结

| 特性 | 文件服务器 | 镜像仓库 |
|------|-----------|---------|
| 多架构策略 | 双层支持 | 单层支持 |
| 镜像平台 | linux/amd64, linux/arm64 | linux/amd64, linux/arm64 |
| 内容架构 | 包含所有架构 | 架构特定 |
| 镜像大小 | ~4-6 GB | ~3-4 GB (每个架构) |
| 混合集群支持 | ✅ 原生支持 | ✅ 通过 manifest 支持 |
| 部署复杂度 | 简单（一个实例） | 简单（一个实例） |

**核心理念：**
- 文件服务器需要在内容层包含所有架构（因为是静态文件）
- 镜像仓库依赖 Docker Registry 协议自动选择架构（因为是容器镜像）
- 两者都支持在任何架构的服务器上运行
- 两者都能为混合架构集群提供服务

---

**设计日期**: 2024-12  
**Kubespray 版本**: v2.25.0  
**Kubernetes 版本**: v1.29.10
