# Kubespray 离线部署镜像

本项目使用 GitHub Actions 自动构建 Kubespray v2.25.0 的离线部署所需的文件和镜像。

> 🚀 **快速开始**: 查看 [GET_STARTED.md](GET_STARTED.md) 在 5 分钟内完成设置！
>
> 🏗️ **多架构支持**: 查看 [MULTI_ARCH_GUIDE.md](MULTI_ARCH_GUIDE.md) 了解 ARM64 支持！
>
> 📚 **文档导航**: 查看 [DOCUMENTATION_INDEX.md](DOCUMENTATION_INDEX.md) 快速找到你需要的文档！

## 特性

- ✅ 自动化构建和推送到 Docker Hub
- ✅ **多架构支持**: linux/amd64 和 linux/arm64
- ✅ 包含所有 Kubernetes v1.29.10 组件
- ✅ 支持多种网络插件（Calico, Cilium, Flannel 等）
- ✅ 一键部署脚本
- ✅ Docker Compose 支持
- ✅ 完整的文档和示例

## 镜像说明

### 1. kubespray-files (离线文件服务)

包含 Kubernetes 及相关组件的二进制文件，通过 nginx 提供 HTTP 文件服务。

**镜像地址**: `docker.io/sgfoot/kubespray-files:v0.1.0-2.25.0`

**支持架构**:

- linux/amd64 (x86_64)
- linux/arm64 (aarch64)

**使用方法**:

```bash
# 启动文件服务器
docker run -d -p 8080:80 --name kubespray-files \
  sgfoot/kubespray-files:v0.1.0-2.25.0

# 访问文件列表
curl http://localhost:8080/k8s/

# 下载示例
curl -O http://localhost:8080/k8s/dl.k8s.io/release/v1.29.10/bin/linux/amd64/kubectl
```

**包含的文件**:

- Kubernetes 组件 (kubelet, kubectl, kubeadm)
- etcd
- CNI 插件
- Calico, Cilium 等网络组件
- containerd, cri-o 等容器运行时
- 其他工具 (helm, crictl, skopeo, yq 等)

### 2. kubespray-images (离线镜像仓库)

包含 Kubernetes 集群所需的所有容器镜像，基于 Docker Registry v3。

**镜像地址**: `docker.io/sgfoot/kubespray-images:v0.1.0-2.25.0`

**支持架构**:

- linux/amd64 (x86_64)
- linux/arm64 (aarch64)

**使用方法**:

```bash
# 启动镜像仓库 (HTTP)
docker run -d -p 5000:5000 --name kubespray-registry \
  sgfoot/kubespray-images:v0.1.0-2.25.0

# 查看镜像列表
curl http://localhost:5000/v2/_catalog

# 查看特定镜像的标签
curl http://localhost:5000/v2/k8s/pause/tags/list
```

**使用 HTTPS (推荐生产环境)**:

```bash
# 创建证书目录
mkdir -p /opt/registry/certs

# 生成自签名证书 (或使用你的证书)
openssl req -newkey rsa:4096 -nodes -sha256 \
  -keyout /opt/registry/certs/hub.kubespray.local.key \
  -x509 -days 365 \
  -out /opt/registry/certs/hub.kubespray.local.crt \
  -subj "/CN=hub.kubespray.local"

# 启动带 TLS 的仓库
docker run -d -p 5000:5000 --name kubespray-registry \
  -v /opt/registry/certs:/certs \
  -e REGISTRY_HTTP_TLS_CERTIFICATE=/certs/hub.kubespray.local.crt \
  -e REGISTRY_HTTP_TLS_KEY=/certs/hub.kubespray.local.key \
  sgfoot/kubespray-images:v0.1.0-2.25.0

# 配置 hosts
echo "127.0.0.1 hub.kubespray.local" >> /etc/hosts

# 验证
curl https://hub.kubespray.local:5000/v2/_catalog
```

**包含的镜像**:

- Kubernetes 核心组件 (kube-apiserver, kube-controller-manager, kube-scheduler, kube-proxy)
- 网络插件 (Calico, Cilium, Flannel, Weave)
- DNS (CoreDNS, NodeLocalDNS)
- 存储 (local-volume-provisioner, csi-provisioner 等)
- 监控 (metrics-server)
- Ingress (nginx-ingress)
- 其他组件 (cert-manager, metallb, dashboard 等)

## 配置 Kubespray 使用离线资源

### 1. 配置文件下载源

编辑 Kubespray 的 inventory 配置:

```yaml
# group_vars/all/offline.yml
download_localhost: false
download_run_once: true

# 文件服务器地址
files_repo: "http://<your-server-ip>:8080/k8s"

# 覆盖默认下载地址
dl_k8s_io_url: "{{ files_repo }}/dl.k8s.io"
github_url: "{{ files_repo }}/github.com"
storage_googleapis_url: "{{ files_repo }}/storage.googleapis.com"
get_helm_url: "{{ files_repo }}/get.helm.sh"
```

### 2. 配置镜像仓库

```yaml
# group_vars/all/offline.yml
registry_host: "hub.kubespray.local:5000"
kube_image_repo: "{{ registry_host }}/k8s/registry.k8s.io"
gcr_image_repo: "{{ registry_host }}/k8s"
docker_image_repo: "{{ registry_host }}/k8s/docker.io"
quay_image_repo: "{{ registry_host }}/k8s/quay.io"
```

## GitHub Actions 配置

需要在 GitHub 仓库中配置以下 Secrets:

1. `DOCKERHUB_USERNAME`: Docker Hub 用户名
2. `DOCKERHUB_TOKEN`: Docker Hub 访问令牌

配置方法:

1. 访问 <https://hub.docker.com/settings/security>
2. 创建新的 Access Token
3. 在 GitHub 仓库的 Settings > Secrets and variables > Actions 中添加

## 构建触发

- 推送到 `main` 分支时自动构建
- 创建 tag (如 `v0.1.0`) 时自动构建
- 手动触发: Actions > Build Kubespray Offline Images > Run workflow

## 版本说明

- 镜像版本格式: `v0.1.0-2.25.0`
  - `v0.1.0`: 构建版本
  - `2.25.0`: Kubespray 版本

## 注意事项

1. 镜像体积较大，构建和推送需要较长时间
2. 确保 GitHub Actions runner 有足够的磁盘空间
3. 生产环境建议使用 HTTPS 配置镜像仓库
4. 需要在目标主机配置 `/etc/hosts` 解析 `hub.kubespray.local`

## 许可证

本项目基于 Kubespray 项目，遵循相同的开源许可证。
