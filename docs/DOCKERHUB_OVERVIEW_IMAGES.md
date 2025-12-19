# Kubespray Offline Image Registry

[![Docker Pulls](https://img.shields.io/docker/pulls/sgfoot/kubespray-images)](https://hub.docker.com/r/sgfoot/kubespray-images)
[![Docker Image Size](https://img.shields.io/docker/image-size/sgfoot/kubespray-images)](https://hub.docker.com/r/sgfoot/kubespray-images)
[![GitHub](https://img.shields.io/badge/GitHub-kubespray--offline-blue)](https://github.com/sgfoot/kubespray-offline)

Pre-loaded Docker Registry v3 with all container images required for Kubespray v2.25.0 deployment. Supports multi-architecture (AMD64 and ARM64) for air-gapped Kubernetes installations.

## 🚀 Quick Start

```bash
# Pull the image
docker pull sgfoot/kubespray-images:v0.1.0-2.25.0

# Run the registry (HTTP)
docker run -d -p 5000:5000 --name kubespray-registry \
  sgfoot/kubespray-images:v0.1.0-2.25.0

# List available images
curl http://localhost:5000/v2/_catalog

# Check specific image tags
curl http://localhost:5000/v2/k8s/pause/tags/list
```

## 📦 What's Included

This registry contains **100+ pre-loaded container images** for both AMD64 and ARM64 architectures:

### Core Kubernetes
- kube-apiserver, kube-controller-manager, kube-scheduler (v1.29.10)
- kube-proxy (v1.29.10)
- pause (v3.9)
- coredns (v1.11.1)
- etcd (v3.5.16)

### Network Plugins
- **Calico** (v3.27.4): calico-node, calico-cni, calico-kube-controllers
- **Cilium** (v1.15.0): cilium, cilium-operator
- **Flannel** (v0.24.0): flannel, flannel-cni-plugin

### Ingress Controllers
- nginx-ingress-controller (v1.9.5)
- haproxy-ingress (v0.14.6)

### Storage
- csi-node-driver-registrar (v2.10.0)
- csi-provisioner (v4.0.0)
- csi-attacher (v4.5.0)
- csi-resizer (v1.10.0)
- local-path-provisioner (v0.0.26)

### Monitoring & Logging
- metrics-server (v0.7.0)
- node-exporter (v1.7.0)

### DNS & Service Mesh
- coredns (v1.11.1)
- nodelocaldns (v1.22.28)

## 🏗️ Multi-Architecture Support

**Supported Platforms:**
- ✅ linux/amd64 (x86_64)
- ✅ linux/arm64 (aarch64)
- ✅ Apple Silicon (M1/M2/M3)
- ✅ AWS Graviton
- ✅ Raspberry Pi 4/5

Docker automatically pulls the correct architecture for your platform.

## 🔧 Usage with Kubespray

### 1. Deploy Registry (HTTP)

```bash
# Simple HTTP deployment
docker run -d -p 5000:5000 --restart always \
  --name kubespray-registry \
  sgfoot/kubespray-images:v0.1.0-2.25.0
```

### 2. Deploy Registry (HTTPS - Recommended)

```bash
# Generate self-signed certificate
mkdir -p /opt/registry/certs
openssl req -newkey rsa:4096 -nodes -sha256 \
  -keyout /opt/registry/certs/hub.kubespray.local.key \
  -x509 -days 365 \
  -out /opt/registry/certs/hub.kubespray.local.crt \
  -subj "/CN=hub.kubespray.local"

# Run with TLS
docker run -d -p 5000:5000 --restart always \
  --name kubespray-registry \
  -v /opt/registry/certs:/certs \
  -e REGISTRY_HTTP_TLS_CERTIFICATE=/certs/hub.kubespray.local.crt \
  -e REGISTRY_HTTP_TLS_KEY=/certs/hub.kubespray.local.key \
  sgfoot/kubespray-images:v0.1.0-2.25.0

# Configure hosts
echo "192.168.1.100 hub.kubespray.local" >> /etc/hosts
```

### 3. Configure Kubespray

Edit `inventory/mycluster/group_vars/all/offline.yml`:

```yaml
# Registry configuration
registry_host: "hub.kubespray.local:5000"
registry_insecure: true  # Set to false if using HTTPS with valid cert

# All images will be pulled from your registry
# Docker automatically selects the correct architecture
```

### 4. Deploy Kubernetes

```bash
ansible-playbook -i inventory/mycluster/hosts.yaml cluster.yml
```

## 🌐 Mixed Architecture Clusters

Perfect for heterogeneous clusters:

```yaml
# Single registry serves all architectures
registry_host: "hub.kubespray.local:5000"

# Docker automatically pulls the right image:
# - AMD64 nodes → AMD64 images
# - ARM64 nodes → ARM64 images
```

## 📋 Available Tags

- `v0.1.0-2.25.0` - Kubespray v2.25.0, Kubernetes v1.29.10
- `v0.1.0-2.25.0-amd64` - AMD64 only
- `v0.1.0-2.25.0-arm64` - ARM64 only
- `latest` - Latest stable release

## 🔍 Verify Images

```bash
# Start the registry
docker run -d -p 5000:5000 --name test-registry \
  sgfoot/kubespray-images:v0.1.0-2.25.0

# List all images
curl http://localhost:5000/v2/_catalog | jq

# Check Kubernetes images
curl http://localhost:5000/v2/k8s/kube-apiserver/tags/list | jq

# Check Calico images
curl http://localhost:5000/v2/calico/node/tags/list | jq

# Verify multi-arch support
docker manifest inspect localhost:5000/k8s/pause:3.9
```

## 🐳 Docker Compose

```yaml
version: '3.8'

services:
  kubespray-registry:
    image: sgfoot/kubespray-images:v0.1.0-2.25.0
    container_name: kubespray-registry
    ports:
      - "5000:5000"
    restart: unless-stopped
    volumes:
      - registry-data:/var/lib/registry
      - ./certs:/certs:ro
    environment:
      - REGISTRY_HTTP_TLS_CERTIFICATE=/certs/hub.kubespray.local.crt
      - REGISTRY_HTTP_TLS_KEY=/certs/hub.kubespray.local.key
      - REGISTRY_LOG_LEVEL=info
    healthcheck:
      test: ["CMD", "wget", "--quiet", "--tries=1", "--spider", "http://localhost:5000/v2/"]
      interval: 30s
      timeout: 10s
      retries: 3

volumes:
  registry-data:
    driver: local
```

## 🛠️ Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `REGISTRY_HTTP_TLS_CERTIFICATE` | Path to TLS certificate | - |
| `REGISTRY_HTTP_TLS_KEY` | Path to TLS key | - |
| `REGISTRY_LOG_LEVEL` | Log level (error, warn, info, debug) | `info` |
| `REGISTRY_STORAGE_DELETE_ENABLED` | Enable image deletion | `true` |

## 📊 Image Size

- **Compressed**: ~3-4 GB
- **Uncompressed**: ~8-12 GB (contains 100+ images for both architectures)

## 🔗 Related Images

Use with the companion file server:

```bash
# Pull file server
docker pull sgfoot/kubespray-files:v0.1.0-2.25.0

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

### Registry not accessible

```bash
# Check container logs
docker logs kubespray-registry

# Verify registry is running
curl http://localhost:5000/v2/
```

### TLS certificate issues

```bash
# Copy certificate to Docker
sudo mkdir -p /etc/docker/certs.d/hub.kubespray.local:5000
sudo cp /opt/registry/certs/hub.kubespray.local.crt \
  /etc/docker/certs.d/hub.kubespray.local:5000/ca.crt

# Restart Docker
sudo systemctl restart docker
```

### Image pull failures

```bash
# Test image pull
docker pull localhost:5000/k8s/pause:3.9

# Check if image exists
curl http://localhost:5000/v2/k8s/pause/tags/list
```

### Architecture mismatch

```bash
# Check image architecture
docker manifest inspect localhost:5000/k8s/pause:3.9

# Force specific architecture
docker pull --platform linux/arm64 localhost:5000/k8s/pause:3.9
```

## 💡 Tips

1. **Persistent Storage**: Mount a volume to preserve registry data
   ```bash
   docker run -d -p 5000:5000 \
     -v registry-data:/var/lib/registry \
     sgfoot/kubespray-images:v0.1.0-2.25.0
   ```

2. **Custom Port**: Change the registry port
   ```bash
   docker run -d -p 5001:5000 sgfoot/kubespray-images:v0.1.0-2.25.0
   ```

3. **Enable Deletion**: Allow image deletion via API
   ```bash
   docker run -d -p 5000:5000 \
     -e REGISTRY_STORAGE_DELETE_ENABLED=true \
     sgfoot/kubespray-images:v0.1.0-2.25.0
   ```

4. **Debug Mode**: Enable debug logging
   ```bash
   docker run -d -p 5000:5000 \
     -e REGISTRY_LOG_LEVEL=debug \
     sgfoot/kubespray-images:v0.1.0-2.25.0
   ```

## 🔒 Security Considerations

### Production Deployment

1. **Use HTTPS**: Always use TLS in production
2. **Authentication**: Consider adding basic auth or token auth
3. **Network Security**: Use firewall rules to restrict access
4. **Certificate Management**: Use valid certificates from a CA

### Basic Authentication

```bash
# Create htpasswd file
docker run --rm --entrypoint htpasswd httpd:2 -Bbn admin password > auth/htpasswd

# Run with authentication
docker run -d -p 5000:5000 \
  -v $(pwd)/auth:/auth \
  -e REGISTRY_AUTH=htpasswd \
  -e REGISTRY_AUTH_HTPASSWD_REALM="Registry Realm" \
  -e REGISTRY_AUTH_HTPASSWD_PATH=/auth/htpasswd \
  sgfoot/kubespray-images:v0.1.0-2.25.0
```

## 📈 Performance Tuning

```bash
# Increase cache size
docker run -d -p 5000:5000 \
  -e REGISTRY_STORAGE_CACHE_BLOBDESCRIPTOR=inmemory \
  sgfoot/kubespray-images:v0.1.0-2.25.0

# Use faster storage
docker run -d -p 5000:5000 \
  -v /fast-ssd/registry:/var/lib/registry \
  sgfoot/kubespray-images:v0.1.0-2.25.0
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
**Registry Version**: v3  
**Last Updated**: 2024-12
