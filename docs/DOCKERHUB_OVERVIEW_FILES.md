# Kubespray Offline Files Server

[![Docker Pulls](https://img.shields.io/docker/pulls/sgfoot/kubespray-files)](https://hub.docker.com/r/sgfoot/kubespray-files)
[![Docker Image Size](https://img.shields.io/docker/image-size/sgfoot/kubespray-files)](https://hub.docker.com/r/sgfoot/kubespray-files)
[![GitHub](https://img.shields.io/badge/GitHub-kubespray--offline-blue)](https://github.com/sgfoot/kubespray-offline)

Offline file server for Kubespray v2.25.0 deployment. Contains all required binary files for Kubernetes v1.29.10 and related components, served via Nginx with HTTP file browsing.

## 🚀 Quick Start

```bash
# Pull the image
docker pull sgfoot/kubespray-files:v0.1.0-2.25.0

# Run the file server
docker run -d -p 8080:80 --name kubespray-files \
  sgfoot/kubespray-files:v0.1.0-2.25.0

# Browse files
curl http://localhost:8080/k8s/

# Download example (kubectl)
curl -O http://localhost:8080/k8s/dl.k8s.io/release/v1.29.10/bin/linux/amd64/kubectl
```

## 📦 What's Included

This image contains binary files for **both AMD64 and ARM64 architectures**:

### Kubernetes Components
- kubelet, kubectl, kubeadm (v1.29.10)
- etcd (v3.5.16)
- CNI plugins (v1.3.0)

### Container Runtimes
- containerd (v1.7.22)
- cri-o (v1.29.1)
- cri-dockerd (v0.3.11)
- runc (v1.1.14)
- crun (v1.14.4)

### Network Plugins
- Calico (v3.27.4)
- Cilium CLI (v0.16.0)

### Tools
- Helm (v3.14.4)
- crictl (v1.29.0)
- nerdctl (v1.7.7)
- skopeo (v1.15.0)
- yq (v4.42.1)
- krew (v0.4.4)

### Advanced Runtimes
- Kata Containers (v3.1.3)
- gVisor (20240305)
- youki (v0.1.0)

## 🏗️ Multi-Architecture Support

### Dual-Layer Architecture Support

This image provides **complete multi-architecture support** at two levels:

#### 1. Image Platform Support (Docker Multi-Platform)
The Docker image itself runs on both architectures:
- ✅ **linux/amd64** - Run on x86_64 servers
- ✅ **linux/arm64** - Run on ARM64 servers, Apple Silicon, AWS Graviton, Raspberry Pi

Docker automatically pulls the correct image for your platform.

#### 2. File Content Support (All Architectures Included)
The image contains binary files for **both target architectures**:

```
/opt/k8s/k8s/
├── dl.k8s.io/release/v1.29.10/bin/linux/
│   ├── amd64/          # AMD64 (x86_64) binaries
│   │   ├── kubelet
│   │   ├── kubectl
│   │   └── kubeadm
│   └── arm64/          # ARM64 (aarch64) binaries
│       ├── kubelet
│       ├── kubectl
│       └── kubeadm
└── ...
```

**This means:**
- Deploy the file server on **any architecture** (AMD64 or ARM64)
- Serve files for **all architectures** (AMD64 and ARM64 nodes)
- Perfect for mixed-architecture Kubernetes clusters

**Example Scenarios:**
- ✅ Run on x86_64 server → Serve files for both x86_64 and ARM64 nodes
- ✅ Run on ARM64 server → Serve files for both x86_64 and ARM64 nodes
- ✅ Run on Apple Silicon Mac → Serve files for both architectures

Kubespray automatically selects the correct file path based on the target node architecture.

## 🔧 Usage with Kubespray

### 1. Deploy File Server

```bash
# On your deployment server
docker run -d -p 8080:80 --restart always \
  --name kubespray-files \
  sgfoot/kubespray-files:v0.1.0-2.25.0
```

### 2. Configure Kubespray

Edit `inventory/mycluster/group_vars/all/offline.yml`:

```yaml
# Point to your file server
files_repo: "http://192.168.1.100:8080/k8s"

# Kubespray will automatically download the correct architecture:
# - AMD64 nodes: .../linux/amd64/kubectl
# - ARM64 nodes: .../linux/arm64/kubectl
```

### 3. Deploy Kubernetes

```bash
ansible-playbook -i inventory/mycluster/hosts.yaml cluster.yml
```

## 🌐 Mixed Architecture Clusters

Perfect for heterogeneous clusters with different CPU architectures:

```yaml
# Single file server supports all node types
files_repo: "http://192.168.1.100:8080/k8s"

# Nodes automatically get the right files:
# - x86_64 control plane → AMD64 binaries
# - ARM64 workers → ARM64 binaries
```

## 📋 Available Tags

- `v0.1.0-2.25.0` - Kubespray v2.25.0, Kubernetes v1.29.10
- `latest` - Latest stable release

## 🔍 Verify Files

```bash
# Start the server
docker run -d -p 8080:80 --name test-files \
  sgfoot/kubespray-files:v0.1.0-2.25.0

# Check AMD64 files
curl http://localhost:8080/k8s/dl.k8s.io/release/v1.29.10/bin/linux/amd64/

# Check ARM64 files
curl http://localhost:8080/k8s/dl.k8s.io/release/v1.29.10/bin/linux/arm64/

# Health check
curl http://localhost:8080/health
```

## 🐳 Docker Compose

```yaml
version: '3.8'

services:
  kubespray-files:
    image: sgfoot/kubespray-files:v0.1.0-2.25.0
    container_name: kubespray-files
    ports:
      - "8080:80"
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "wget", "--quiet", "--tries=1", "--spider", "http://localhost/k8s/"]
      interval: 30s
      timeout: 10s
      retries: 3
```

## 🛠️ Environment Variables

No environment variables required. The image works out of the box.

## 📊 Image Size

- **Compressed**: ~1.5-2 GB
- **Uncompressed**: ~4-6 GB (contains both architectures)

## 🔗 Related Images

Use with the companion image registry:

```bash
# Pull image registry
docker pull sgfoot/kubespray-images:v0.1.0-2.25.0

# Deploy both services
docker run -d -p 8080:80 --name kubespray-files \
  sgfoot/kubespray-files:v0.1.0-2.25.0

docker run -d -p 5000:5000 --name kubespray-registry \
  sgfoot/kubespray-images:v0.1.0-2.25.0
```

## 📚 Documentation

- **GitHub Repository**: https://github.com/sgfoot/kubespray-offline
- **Quick Start Guide**: [GET_STARTED.md](https://github.com/sgfoot/kubespray-offline/blob/main/GET_STARTED.md)
- **Multi-Arch Guide**: [MULTI_ARCH_GUIDE.md](https://github.com/sgfoot/kubespray-offline/blob/main/MULTI_ARCH_GUIDE.md)
- **Windows Guide**: [WINDOWS_GUIDE.md](https://github.com/sgfoot/kubespray-offline/blob/main/WINDOWS_GUIDE.md)

## 🐛 Troubleshooting

### Files not accessible

```bash
# Check container logs
docker logs kubespray-files

# Verify nginx is running
docker exec kubespray-files ps aux | grep nginx
```

### Port already in use

```bash
# Use a different port
docker run -d -p 9090:80 --name kubespray-files \
  sgfoot/kubespray-files:v0.1.0-2.25.0
```

### Architecture-specific issues

```bash
# Verify both architectures are present
docker run --rm sgfoot/kubespray-files:v0.1.0-2.25.0 \
  ls -la /opt/k8s/k8s/dl.k8s.io/release/v1.29.10/bin/linux/
```

## 💡 Tips

1. **Persistent Storage**: Mount a volume to preserve downloaded files
   ```bash
   docker run -d -p 8080:80 -v files-data:/opt/k8s \
     sgfoot/kubespray-files:v0.1.0-2.25.0
   ```

2. **Custom Port**: Change the host port as needed
   ```bash
   docker run -d -p 9090:80 sgfoot/kubespray-files:v0.1.0-2.25.0
   ```

3. **Health Monitoring**: Use the `/health` endpoint
   ```bash
   curl http://localhost:8080/health
   ```

## 📄 License

MIT License - See [LICENSE](https://github.com/sgfoot/kubespray-offline/blob/main/LICENSE)

## 🤝 Contributing

Contributions welcome! Please visit the [GitHub repository](https://github.com/sgfoot/kubespray-offline).

## ⭐ Support

If this image helps you, please star the [GitHub repository](https://github.com/sgfoot/kubespray-offline)!

---

**Maintained by**: [sgfoot](https://github.com/sgfoot)  
**Kubespray Version**: v2.25.0  
**Kubernetes Version**: v1.29.10  
**Last Updated**: 2024-12
