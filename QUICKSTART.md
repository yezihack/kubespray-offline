# 快速开始指南

完整的 Kubespray 离线部署指南，从零开始 30 分钟内完成 Kubernetes 集群部署。

## 📋 前置要求

### 硬件要求

**离线服务器** (部署文件服务器和镜像仓库):
- CPU: 2 核+
- 内存: 4GB+
- 磁盘: 50GB+
- 网络: 可访问 Docker Hub (首次拉取镜像)

**Kubernetes 节点**:
- Master: 2 核 / 4GB / 50GB
- Worker: 2 核 / 4GB / 50GB
- 支持架构: AMD64 (x86_64) 或 ARM64 (aarch64)

### 软件要求

- Docker 20.10+
- (可选) Docker Compose
- (可选) OpenSSL (生成证书)

## 🚀 第一步: 部署离线服务

### 选项 A: 使用脚本（推荐）

#### Linux/macOS

```bash
# 1. 克隆项目
git clone https://github.com/sgfoot/kubespray-offline.git
cd kubespray-offline

# 2. 部署文件服务器
chmod +x scripts/deploy-offline-files.sh
./scripts/deploy-offline-files.sh

# 3. 部署镜像仓库
chmod +x scripts/deploy-offline-registry.sh
./scripts/deploy-offline-registry.sh
```

#### Windows PowerShell

```powershell
# 1. 克隆项目
git clone https://github.com/sgfoot/kubespray-offline.git
cd kubespray-offline

# 2. 部署文件服务器
.\scripts\deploy-offline-files.ps1

# 3. 部署镜像仓库
.\scripts\deploy-offline-registry.ps1
```

### 选项 B: 使用 Docker Compose

```bash
# 1. 生成证书
mkdir -p certs
openssl req -newkey rsa:4096 -nodes -sha256 \
  -keyout certs/hub.kubespray.local.key \
  -x509 -days 365 \
  -out certs/hub.kubespray.local.crt \
  -subj "/CN=hub.kubespray.local" \
  -addext "subjectAltName=DNS:hub.kubespray.local,DNS:localhost,IP:127.0.0.1"

# 2. 配置 hosts
echo "127.0.0.1 hub.kubespray.local" | sudo tee -a /etc/hosts

# 3. 启动服务
docker-compose up -d
```

### 选项 C: 手动部署

#### 1. 部署文件服务器

```bash
docker run -d \
  -p 8080:80 \
  --restart always \
  --name kubespray-files \
  sgfoot/kubespray-files:v0.1.0-2.25.0
```

#### 2. 部署镜像仓库

```bash
# 创建证书目录
mkdir -p /opt/registry/certs

# 生成自签名证书
openssl req -newkey rsa:4096 -nodes -sha256 \
  -keyout /opt/registry/certs/hub.kubespray.local.key \
  -x509 -days 365 \
  -out /opt/registry/certs/hub.kubespray.local.crt \
  -subj "/CN=hub.kubespray.local" \
  -addext "subjectAltName=DNS:hub.kubespray.local,DNS:localhost,IP:127.0.0.1"

# 配置 hosts
echo "127.0.0.1 hub.kubespray.local" | sudo tee -a /etc/hosts

# 启动镜像仓库
docker run -d \
  -p 5000:5000 \
  --restart always \
  --name kubespray-registry \
  -v /opt/registry/certs:/certs \
  -e REGISTRY_HTTP_TLS_CERTIFICATE=/certs/hub.kubespray.local.crt \
  -e REGISTRY_HTTP_TLS_KEY=/certs/hub.kubespray.local.key \
  sgfoot/kubespray-images:v0.1.0-2.25.0
```

## ✅ 第二步: 验证服务

```bash
# 1. 检查容器状态
docker ps | grep kubespray

# 2. 验证文件服务器
curl http://localhost:8080/k8s/
curl http://localhost:8080/k8s/dl.k8s.io/release/v1.29.10/bin/linux/amd64/

# 3. 验证镜像仓库
curl -k https://hub.kubespray.local:5000/v2/_catalog
curl -k https://hub.kubespray.local:5000/v2/k8s/pause/tags/list

# 4. 测试镜像拉取
docker pull hub.kubespray.local:5000/k8s/pause:3.9
```

## 🔧 第三步: 准备 Kubespray

### 1. 克隆 Kubespray

```bash
git clone https://github.com/kubernetes-sigs/kubespray.git
cd kubespray
git checkout v2.25.0
```

### 2. 安装依赖

```bash
# 创建虚拟环境（推荐）
python3 -m venv venv
source venv/bin/activate  # Linux/macOS
# 或 venv\Scripts\activate  # Windows

# 安装依赖
pip install -r requirements.txt
```

### 3. 创建 Inventory

```bash
# 复制示例配置
cp -rfp inventory/sample inventory/mycluster

# 生成 inventory（替换为你的节点 IP）
declare -a IPS=(192.168.1.101 192.168.1.102 192.168.1.103)
CONFIG_FILE=inventory/mycluster/hosts.yml \
  python3 contrib/inventory_builder/inventory.py ${IPS[@]}
```

### 4. 配置离线模式

创建 `inventory/mycluster/group_vars/all/offline.yml`:

```yaml
---
# 离线模式配置

# 文件服务器地址（替换为实际 IP）
files_repo: "http://192.168.1.100:8080/k8s"

# 覆盖默认下载地址
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

# 下载配置
download_localhost: false
download_run_once: true
download_force_cache: true
```

完整配置参考: [examples/kubespray-offline-config.yml](examples/kubespray-offline-config.yml)

## 🌐 第四步: 配置目标节点

在**所有 Kubernetes 节点**上执行以下操作：

### 1. 配置 Hosts

```bash
# 添加镜像仓库域名解析（替换为实际 IP）
echo "192.168.1.100 hub.kubespray.local" | sudo tee -a /etc/hosts
```

### 2. 配置证书（Containerd）

```bash
# 创建证书目录
sudo mkdir -p /etc/containerd/certs.d/hub.kubespray.local:5000

# 复制证书（从离线服务器）
sudo scp 192.168.1.100:/opt/registry/certs/hub.kubespray.local.crt \
  /etc/containerd/certs.d/hub.kubespray.local:5000/ca.crt

# 或手动复制证书内容
sudo vi /etc/containerd/certs.d/hub.kubespray.local:5000/ca.crt
```

### 3. 配置证书（Docker）

如果使用 Docker 作为容器运行时：

```bash
# 创建证书目录
sudo mkdir -p /etc/docker/certs.d/hub.kubespray.local:5000

# 复制证书
sudo scp 192.168.1.100:/opt/registry/certs/hub.kubespray.local.crt \
  /etc/docker/certs.d/hub.kubespray.local:5000/ca.crt

# 重启 Docker
sudo systemctl restart docker
```

### 4. 测试连接

```bash
# 测试文件下载
curl http://192.168.1.100:8080/k8s/

# 测试镜像拉取
docker pull hub.kubespray.local:5000/k8s/pause:3.9
```

## 🚀 第五步: 部署 Kubernetes

### 1. 检查连接

```bash
# 测试 SSH 连接
ansible -i inventory/mycluster/hosts.yml all -m ping
```

### 2. 部署集群

```bash
# 完整部署
ansible-playbook -i inventory/mycluster/hosts.yml \
  --become --become-user=root \
  cluster.yml

# 或分步部署
# 1. 准备节点
ansible-playbook -i inventory/mycluster/hosts.yml \
  --become --become-user=root \
  cluster.yml --tags=bootstrap-os

# 2. 部署 etcd
ansible-playbook -i inventory/mycluster/hosts.yml \
  --become --become-user=root \
  cluster.yml --tags=etcd

# 3. 部署 Kubernetes
ansible-playbook -i inventory/mycluster/hosts.yml \
  --become --become-user=root \
  cluster.yml --tags=k8s-cluster

# 4. 部署网络插件
ansible-playbook -i inventory/mycluster/hosts.yml \
  --become --become-user=root \
  cluster.yml --tags=network
```

### 3. 验证集群

```bash
# 在 master 节点上
sudo kubectl get nodes
sudo kubectl get pods -A
sudo kubectl cluster-info
```

## 🎯 常见场景

### 场景 1: 纯 AMD64 集群

```yaml
# inventory/mycluster/group_vars/all/offline.yml
files_repo: "http://192.168.1.100:8080/k8s"
registry_host: "hub.kubespray.local:5000"

# Kubespray 自动使用 AMD64 文件和镜像
```

### 场景 2: 纯 ARM64 集群

```yaml
# inventory/mycluster/group_vars/all/offline.yml
files_repo: "http://192.168.1.100:8080/k8s"
registry_host: "hub.kubespray.local:5000"

# Kubespray 自动使用 ARM64 文件和镜像
```

### 场景 3: 混合架构集群

```yaml
# inventory/mycluster/group_vars/all/offline.yml
files_repo: "http://192.168.1.100:8080/k8s"
registry_host: "hub.kubespray.local:5000"

# Kubespray 根据节点架构自动选择
# - AMD64 节点 → AMD64 文件和镜像
# - ARM64 节点 → ARM64 文件和镜像
```

## 🐛 故障排查

### 问题 1: 文件下载失败

**症状**: Ansible 任务失败，提示无法下载文件

**排查**:
```bash
# 1. 检查文件服务器状态
docker logs kubespray-files

# 2. 测试文件访问
curl -I http://192.168.1.100:8080/k8s/dl.k8s.io/release/v1.29.10/bin/linux/amd64/kubectl

# 3. 检查防火墙
sudo firewall-cmd --list-ports  # CentOS/RHEL
sudo ufw status  # Ubuntu
```

**解决**:
```bash
# 开放端口
sudo firewall-cmd --add-port=8080/tcp --permanent
sudo firewall-cmd --reload
```

### 问题 2: 镜像拉取失败

**症状**: 无法拉取镜像，提示证书错误或连接失败

**排查**:
```bash
# 1. 检查镜像仓库状态
docker logs kubespray-registry

# 2. 测试连接
curl -k https://hub.kubespray.local:5000/v2/_catalog

# 3. 检查证书
openssl s_client -connect hub.kubespray.local:5000 -showcerts

# 4. 检查 hosts 配置
cat /etc/hosts | grep hub.kubespray.local
```

**解决**:
```bash
# 重新配置证书
sudo mkdir -p /etc/containerd/certs.d/hub.kubespray.local:5000
sudo cp /opt/registry/certs/hub.kubespray.local.crt \
  /etc/containerd/certs.d/hub.kubespray.local:5000/ca.crt

# 重启 containerd
sudo systemctl restart containerd
```

### 问题 3: 架构不匹配

**症状**: 二进制文件无法执行，提示 "exec format error"

**排查**:
```bash
# 检查节点架构
uname -m

# 检查文件架构
file /usr/local/bin/kubectl

# 验证文件服务器内容
curl http://192.168.1.100:8080/k8s/dl.k8s.io/release/v1.29.10/bin/linux/
```

**解决**:
- 确保文件服务器包含对应架构的文件
- 检查 Kubespray 配置是否正确

### 问题 4: DNS 解析失败

**症状**: 无法解析 hub.kubespray.local

**排查**:
```bash
# 测试 DNS 解析
nslookup hub.kubespray.local
ping hub.kubespray.local
```

**解决**:
```bash
# 确保 /etc/hosts 配置正确
echo "192.168.1.100 hub.kubespray.local" | sudo tee -a /etc/hosts
```

### 问题 5: 端口冲突

**症状**: 容器启动失败，提示端口已被占用

**排查**:
```bash
# 检查端口占用
sudo netstat -tuln | grep 8080
sudo netstat -tuln | grep 5000
```

**解决**:
```bash
# 停止占用端口的服务
sudo systemctl stop <service-name>

# 或使用不同端口
docker run -d -p 9090:80 sgfoot/kubespray-files:v0.1.0-2.25.0
```

## 🔧 高级配置

### 使用持久化存储

```bash
# 文件服务器
docker run -d \
  -p 8080:80 \
  -v /data/kubespray-files:/opt/k8s \
  --name kubespray-files \
  sgfoot/kubespray-files:v0.1.0-2.25.0

# 镜像仓库
docker run -d \
  -p 5000:5000 \
  -v /data/registry:/var/lib/registry \
  -v /opt/registry/certs:/certs \
  -e REGISTRY_HTTP_TLS_CERTIFICATE=/certs/hub.kubespray.local.crt \
  -e REGISTRY_HTTP_TLS_KEY=/certs/hub.kubespray.local.key \
  --name kubespray-registry \
  sgfoot/kubespray-images:v0.1.0-2.25.0
```

### 配置镜像仓库认证

```bash
# 创建密码文件
mkdir -p /opt/registry/auth
docker run --rm --entrypoint htpasswd httpd:2 -Bbn admin password \
  > /opt/registry/auth/htpasswd

# 启动带认证的仓库
docker run -d \
  -p 5000:5000 \
  -v /opt/registry/auth:/auth \
  -v /opt/registry/certs:/certs \
  -e REGISTRY_AUTH=htpasswd \
  -e REGISTRY_AUTH_HTPASSWD_REALM="Registry Realm" \
  -e REGISTRY_AUTH_HTPASSWD_PATH=/auth/htpasswd \
  -e REGISTRY_HTTP_TLS_CERTIFICATE=/certs/hub.kubespray.local.crt \
  -e REGISTRY_HTTP_TLS_KEY=/certs/hub.kubespray.local.key \
  --name kubespray-registry \
  sgfoot/kubespray-images:v0.1.0-2.25.0

# 在节点上登录
docker login hub.kubespray.local:5000
```

### 自定义网络插件

```yaml
# inventory/mycluster/group_vars/k8s_cluster/k8s-cluster.yml

# 使用 Calico
kube_network_plugin: calico

# 使用 Cilium
kube_network_plugin: cilium

# 使用 Flannel
kube_network_plugin: flannel
```

### 配置 Ingress

```yaml
# inventory/mycluster/group_vars/k8s_cluster/addons.yml
ingress_nginx_enabled: true
ingress_nginx_host_network: true
```

## 📊 性能优化

### 并行下载

```yaml
# inventory/mycluster/group_vars/all/offline.yml
download_run_once: true
download_localhost: false
download_force_cache: true

# 增加并行度
ansible_forks: 10
```

### 缓存配置

```yaml
# 启用本地缓存
download_cache_dir: /tmp/kubespray_cache
download_keep_remote_cache: true
```

## 📚 参考资源

- **Kubespray 官方文档**: https://kubespray.io/
- **Kubernetes 文档**: https://kubernetes.io/docs/
- **Docker Registry 文档**: https://docs.docker.com/registry/
- **项目文档**: [docs/](docs/)

## 🆘 获取帮助

- **GitHub Issues**: https://github.com/sgfoot/kubespray-offline/issues
- **Kubespray Slack**: https://kubernetes.slack.com/messages/kubespray

## ✅ 检查清单

部署前检查：
- [ ] Docker 已安装并运行
- [ ] 网络连通性正常
- [ ] 磁盘空间充足 (50GB+)
- [ ] 防火墙规则配置正确

离线服务检查：
- [ ] 文件服务器运行正常
- [ ] 镜像仓库运行正常
- [ ] 可以访问文件列表
- [ ] 可以拉取测试镜像

节点配置检查：
- [ ] hosts 文件配置正确
- [ ] 证书已复制到所有节点
- [ ] SSH 连接正常
- [ ] 可以下载文件和拉取镜像

---

**提示**: 如果遇到问题，请先查看故障排查部分，或在 GitHub 创建 Issue。

**预计时间**: 
- 部署离线服务: 10 分钟
- 配置 Kubespray: 5 分钟
- 部署 Kubernetes: 15-30 分钟
