# 开始使用

欢迎使用 Kubespray 离线部署工具！本指南将帮助你在 5 分钟内完成设置。

## 🚀 快速开始（3 步）

### 步骤 1: 配置 GitHub Secrets

在你的 GitHub 仓库中配置 Docker Hub 凭证：

1. 访问 https://hub.docker.com/settings/security
2. 点击 "New Access Token"
3. 创建一个新的访问令牌
4. 在 GitHub 仓库中: Settings → Secrets and variables → Actions
5. 添加两个 secrets:
   - `DOCKERHUB_USERNAME`: 你的 Docker Hub 用户名
   - `DOCKERHUB_TOKEN`: 刚才创建的访问令牌

### 步骤 2: 触发构建

有三种方式触发构建：

**方式 1: 推送代码**
```bash
git add .
git commit -m "Initial commit"
git push origin main
```

**方式 2: 创建 tag**
```bash
git tag v0.1.0-2.25.0
git push origin v0.1.0-2.25.0
```

**方式 3: 手动触发**
1. 访问 GitHub 仓库的 Actions 页面
2. 选择 "Build Kubespray Offline Images"
3. 点击 "Run workflow"

### 步骤 3: 等待构建完成

构建过程大约需要 30-60 分钟。完成后，镜像将自动推送到 Docker Hub。

## 📦 使用构建好的镜像

> 💡 **多架构支持**: 镜像支持 linux/amd64 和 linux/arm64，Docker 会自动选择匹配你系统架构的镜像。

### 方式 1: 使用 Docker Compose（推荐）

```bash
# 1. 配置环境变量
cp .env.example .env
# 编辑 .env 文件，设置你的 Docker Hub 用户名
nano .env

# 2. 启动服务（自动选择架构）
docker-compose up -d

# 3. 验证
curl http://localhost:8080/k8s/
curl -k https://hub.kubespray.local:5000/v2/_catalog
```

**指定架构**（可选）:
```bash
# 强制使用 amd64
docker pull --platform linux/amd64 sgfoot/kubespray-files:v0.1.0-2.25.0

# 强制使用 arm64
docker pull --platform linux/arm64 sgfoot/kubespray-files:v0.1.0-2.25.0
```

### 方式 2: 使用部署脚本

```bash
# 部署文件服务器
chmod +x scripts/deploy-offline-files.sh
./scripts/deploy-offline-files.sh

# 部署镜像仓库
chmod +x scripts/deploy-offline-registry.sh
./scripts/deploy-offline-registry.sh
```

### 方式 3: 使用 Makefile

```bash
# 查看所有可用命令
make help

# 部署所有服务
make deploy

# 测试服务
make test

# 查看状态
make status
```

## 🎯 配置 Kubespray

### 1. 克隆 Kubespray

```bash
git clone https://github.com/kubernetes-sigs/kubespray.git
cd kubespray
git checkout v2.25.0
```

### 2. 创建 inventory

```bash
cp -rfp inventory/sample inventory/mycluster
```

### 3. 配置离线模式

创建 `inventory/mycluster/group_vars/all/offline.yml`:

```yaml
# 替换为你的服务器 IP
files_repo: "http://192.168.1.100:8080/k8s"
registry_host: "hub.kubespray.local:5000"

# 文件下载源
dl_k8s_io_url: "{{ files_repo }}/dl.k8s.io"
github_url: "{{ files_repo }}/github.com"
storage_googleapis_url: "{{ files_repo }}/storage.googleapis.com"
get_helm_url: "{{ files_repo }}/get.helm.sh"

# 镜像仓库
kube_image_repo: "{{ registry_host }}/k8s/registry.k8s.io"
docker_image_repo: "{{ registry_host }}/k8s/docker.io"
quay_image_repo: "{{ registry_host }}/k8s/quay.io"
```

完整配置参考: `examples/kubespray-offline-config.yml`

### 4. 配置目标节点

在所有 Kubernetes 节点上执行：

```bash
# 配置 hosts（替换为你的服务器 IP）
echo "192.168.1.100 hub.kubespray.local" | sudo tee -a /etc/hosts

# 复制证书（如果使用 HTTPS）
sudo mkdir -p /etc/containerd/certs.d/hub.kubespray.local:5000
sudo scp root@192.168.1.100:/opt/registry/certs/hub.kubespray.local.crt \
  /etc/containerd/certs.d/hub.kubespray.local:5000/ca.crt
```

### 5. 部署集群

```bash
# 安装依赖
pip install -r requirements.txt

# 配置节点
declare -a IPS=(192.168.1.101 192.168.1.102 192.168.1.103)
CONFIG_FILE=inventory/mycluster/hosts.yml \
  python3 contrib/inventory_builder/inventory.py ${IPS[@]}

# 部署
ansible-playbook -i inventory/mycluster/hosts.yml \
  --become --become-user=root \
  cluster.yml
```

## 📚 更多文档

- **README.md**: 完整的项目说明
- **QUICKSTART.md**: 详细的快速开始指南
- **PROJECT_STRUCTURE.md**: 项目结构说明
- **IMPLEMENTATION_SUMMARY.md**: 实现细节
- **CONTRIBUTING.md**: 如何贡献代码

## 🔧 常用命令

```bash
# 查看服务状态
docker ps --filter "name=kubespray"

# 查看日志
docker logs kubespray-files
docker logs kubespray-registry

# 重启服务
docker restart kubespray-files
docker restart kubespray-registry

# 停止服务
docker stop kubespray-files kubespray-registry

# 清理
docker rm -f kubespray-files kubespray-registry
```

## ❓ 常见问题

### Q: 构建失败怎么办？

A: 检查 GitHub Actions 日志，常见原因：
- Docker Hub 凭证配置错误
- 网络问题导致下载失败
- 磁盘空间不足

### Q: 镜像拉取失败？

A: 检查：
1. hosts 配置是否正确
2. 证书是否已复制到目标节点
3. 镜像仓库是否正常运行

### Q: 文件下载失败？

A: 检查：
1. 文件服务器是否正常运行
2. 网络连接是否正常
3. 文件路径是否正确

## 💡 提示

1. **首次构建时间较长**: 需要下载大量文件和镜像，请耐心等待
2. **磁盘空间**: 确保有足够的磁盘空间（建议 50GB+）
3. **网络连接**: 构建过程需要稳定的网络连接
4. **证书配置**: 生产环境建议使用正式 CA 签发的证书

## 🎉 完成！

现在你已经成功设置了 Kubespray 离线部署环境！

如有问题，请查看详细文档或创建 GitHub Issue。

---

**下一步**: 阅读 [QUICKSTART.md](QUICKSTART.md) 了解更多详细信息。
