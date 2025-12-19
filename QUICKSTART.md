# 快速开始指南

本指南帮助你快速部署和使用 Kubespray 离线安装环境。

## 前置要求

- Docker 已安装
- 可以访问 Docker Hub
- 足够的磁盘空间（建议 50GB+）

## 步骤 1: 拉取镜像

```bash
# 拉取文件服务器镜像
docker pull <your-dockerhub-username>/kubespray-files:v0.1.0-2.25.0

# 拉取镜像仓库
docker pull <your-dockerhub-username>/kubespray-images:v0.1.0-2.25.0
```

## 步骤 2: 部署离线服务

### 方式 1: 使用脚本（推荐）

```bash
# 部署文件服务器
chmod +x scripts/deploy-offline-files.sh
./scripts/deploy-offline-files.sh

# 部署镜像仓库
chmod +x scripts/deploy-offline-registry.sh
./scripts/deploy-offline-registry.sh
```

### 方式 2: 手动部署

#### 部署文件服务器

```bash
docker run -d \
  -p 8080:80 \
  --restart always \
  --name kubespray-files \
  <your-dockerhub-username>/kubespray-files:v0.1.0-2.25.0
```

#### 部署镜像仓库

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
  <your-dockerhub-username>/kubespray-images:v0.1.0-2.25.0
```

## 步骤 3: 验证服务

```bash
# 验证文件服务器
curl http://localhost:8080/k8s/

# 验证镜像仓库
curl -k https://hub.kubespray.local:5000/v2/_catalog

# 查看可用镜像
curl -k https://hub.kubespray.local:5000/v2/_catalog | jq
```

## 步骤 4: 配置 Kubespray

### 4.1 克隆 Kubespray

```bash
git clone https://github.com/kubernetes-sigs/kubespray.git
cd kubespray
git checkout v2.25.0
```

### 4.2 创建 inventory

```bash
cp -rfp inventory/sample inventory/mycluster
```

### 4.3 配置离线模式

创建 `inventory/mycluster/group_vars/all/offline.yml`:

```yaml
# 文件服务器地址（替换为实际 IP）
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

完整配置参考 `examples/kubespray-offline-config.yml`。

### 4.4 配置目标节点

在所有 Kubernetes 节点上：

```bash
# 1. 配置 hosts
echo "192.168.1.100 hub.kubespray.local" | sudo tee -a /etc/hosts

# 2. 信任自签名证书（如果使用 containerd）
sudo mkdir -p /etc/containerd/certs.d/hub.kubespray.local:5000
sudo cp /opt/registry/certs/hub.kubespray.local.crt \
  /etc/containerd/certs.d/hub.kubespray.local:5000/ca.crt

# 3. 或者配置 Docker（如果使用 Docker）
sudo mkdir -p /etc/docker/certs.d/hub.kubespray.local:5000
sudo cp /opt/registry/certs/hub.kubespray.local.crt \
  /etc/docker/certs.d/hub.kubespray.local:5000/ca.crt
sudo systemctl restart docker
```

## 步骤 5: 部署 Kubernetes

```bash
# 安装依赖
pip install -r requirements.txt

# 配置 inventory
declare -a IPS=(192.168.1.101 192.168.1.102 192.168.1.103)
CONFIG_FILE=inventory/mycluster/hosts.yml python3 contrib/inventory_builder/inventory.py ${IPS[@]}

# 部署集群
ansible-playbook -i inventory/mycluster/hosts.yml \
  --become --become-user=root \
  cluster.yml
```

## 故障排查

### 文件下载失败

```bash
# 检查文件服务器日志
docker logs kubespray-files

# 测试文件下载
curl -I http://192.168.1.100:8080/k8s/dl.k8s.io/release/v1.29.10/bin/linux/amd64/kubectl
```

### 镜像拉取失败

```bash
# 检查镜像仓库日志
docker logs kubespray-registry

# 测试镜像拉取
docker pull hub.kubespray.local:5000/k8s/pause:3.9

# 检查证书配置
openssl s_client -connect hub.kubespray.local:5000 -showcerts
```

### 证书问题

```bash
# 重新生成证书
sudo rm -rf /opt/registry/certs/*
./scripts/deploy-offline-registry.sh

# 在所有节点更新证书
sudo cp /opt/registry/certs/hub.kubespray.local.crt \
  /etc/containerd/certs.d/hub.kubespray.local:5000/ca.crt
```

## 高级配置

### 使用外部存储

```bash
# 持久化文件服务器数据
docker run -d \
  -p 8080:80 \
  -v /data/kubespray-files:/opt/k8s \
  --name kubespray-files \
  <your-dockerhub-username>/kubespray-files:v0.1.0-2.25.0

# 持久化镜像仓库数据
docker run -d \
  -p 5000:5000 \
  -v /data/registry:/var/lib/registry \
  -v /opt/registry/certs:/certs \
  -e REGISTRY_HTTP_TLS_CERTIFICATE=/certs/hub.kubespray.local.crt \
  -e REGISTRY_HTTP_TLS_KEY=/certs/hub.kubespray.local.key \
  --name kubespray-registry \
  <your-dockerhub-username>/kubespray-images:v0.1.0-2.25.0
```

### 使用 Docker Compose

创建 `docker-compose.yml`:

```yaml
version: '3.8'

services:
  files:
    image: <your-dockerhub-username>/kubespray-files:v0.1.0-2.25.0
    ports:
      - "8080:80"
    restart: always
    volumes:
      - files-data:/opt/k8s

  registry:
    image: <your-dockerhub-username>/kubespray-images:v0.1.0-2.25.0
    ports:
      - "5000:5000"
    restart: always
    volumes:
      - registry-data:/var/lib/registry
      - ./certs:/certs
    environment:
      - REGISTRY_HTTP_TLS_CERTIFICATE=/certs/hub.kubespray.local.crt
      - REGISTRY_HTTP_TLS_KEY=/certs/hub.kubespray.local.key

volumes:
  files-data:
  registry-data:
```

启动：

```bash
docker-compose up -d
```

## 参考资源

- [Kubespray 官方文档](https://kubespray.io/)
- [Docker Registry 文档](https://docs.docker.com/registry/)
- [Kubernetes 文档](https://kubernetes.io/docs/)
