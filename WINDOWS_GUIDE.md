# Windows 使用指南

本指南专门针对 Windows 用户，说明如何在 Windows 环境下使用本项目。

## 前置要求

1. **Docker Desktop for Windows**
   - 下载: https://www.docker.com/products/docker-desktop
   - 确保 Docker 正在运行

2. **PowerShell 5.1+** (Windows 10/11 自带)
   - 或者 PowerShell Core 7+

3. **OpenSSL** (可选，用于生成证书)
   - 下载: https://slproweb.com/products/Win32OpenSSL.html
   - 或使用 WSL (Windows Subsystem for Linux)

## 快速开始

### 方式 1: 使用 PowerShell 脚本

#### 1. 部署文件服务器

```powershell
# 以管理员身份运行 PowerShell
cd kubespray-offline

# 执行部署脚本
.\scripts\deploy-offline-files.ps1

# 或指定端口
.\scripts\deploy-offline-files.ps1 -FilesPort 8080
```

#### 2. 部署镜像仓库

```powershell
# 以管理员身份运行 PowerShell
.\scripts\deploy-offline-registry.ps1

# 或指定参数
.\scripts\deploy-offline-registry.ps1 -RegistryHost "hub.kubespray.local" -RegistryPort 5000
```

### 方式 2: 使用 Docker Compose

```powershell
# 1. 复制环境变量文件
Copy-Item .env.example .env

# 2. 编辑 .env 文件
notepad .env

# 3. 启动服务
docker-compose up -d

# 4. 查看状态
docker-compose ps

# 5. 查看日志
docker-compose logs -f
```

### 方式 3: 手动部署

#### 部署文件服务器

```powershell
# 拉取镜像
docker pull your-username/kubespray-files:v0.1.0-2.25.0

# 启动容器
docker run -d `
  -p 8080:80 `
  --restart always `
  --name kubespray-files `
  your-username/kubespray-files:v0.1.0-2.25.0

# 验证
curl http://localhost:8080/k8s/
```

#### 部署镜像仓库

```powershell
# 1. 创建证书目录
New-Item -ItemType Directory -Path C:\registry\certs -Force

# 2. 生成证书 (使用 OpenSSL)
# 如果安装了 OpenSSL:
openssl req -newkey rsa:4096 -nodes -sha256 `
  -keyout C:\registry\certs\hub.kubespray.local.key `
  -x509 -days 365 `
  -out C:\registry\certs\hub.kubespray.local.crt `
  -subj "/CN=hub.kubespray.local"

# 或使用 WSL:
wsl openssl req -newkey rsa:4096 -nodes -sha256 `
  -keyout /mnt/c/registry/certs/hub.kubespray.local.key `
  -x509 -days 365 `
  -out /mnt/c/registry/certs/hub.kubespray.local.crt `
  -subj "/CN=hub.kubespray.local"

# 3. 配置 hosts (需要管理员权限)
Add-Content -Path C:\Windows\System32\drivers\etc\hosts -Value "`n127.0.0.1 hub.kubespray.local"

# 4. 启动容器
docker run -d `
  -p 5000:5000 `
  --restart always `
  --name kubespray-registry `
  -v C:\registry\certs:/certs `
  -e REGISTRY_HTTP_TLS_CERTIFICATE=/certs/hub.kubespray.local.crt `
  -e REGISTRY_HTTP_TLS_KEY=/certs/hub.kubespray.local.key `
  your-username/kubespray-images:v0.1.0-2.25.0

# 5. 验证
curl -k https://hub.kubespray.local:5000/v2/_catalog
```

## 配置 Docker Desktop

### 信任自签名证书

1. 打开 Docker Desktop
2. 点击设置图标 (齿轮)
3. 选择 "Docker Engine"
4. 添加以下配置:

```json
{
  "insecure-registries": [
    "hub.kubespray.local:5000"
  ]
}
```

5. 点击 "Apply & Restart"

### 或者导入证书到 Windows

```powershell
# 导入证书到受信任的根证书颁发机构
Import-Certificate -FilePath C:\registry\certs\hub.kubespray.local.crt `
  -CertStoreLocation Cert:\LocalMachine\Root
```

## 常用 PowerShell 命令

### 查看容器状态

```powershell
# 查看所有容器
docker ps -a

# 查看 kubespray 相关容器
docker ps --filter "name=kubespray"

# 查看容器详细信息
docker inspect kubespray-files
docker inspect kubespray-registry
```

### 查看日志

```powershell
# 查看文件服务器日志
docker logs kubespray-files

# 实时查看日志
docker logs -f kubespray-files

# 查看最后 100 行日志
docker logs --tail 100 kubespray-files
```

### 管理容器

```powershell
# 停止容器
docker stop kubespray-files
docker stop kubespray-registry

# 启动容器
docker start kubespray-files
docker start kubespray-registry

# 重启容器
docker restart kubespray-files
docker restart kubespray-registry

# 删除容器
docker rm -f kubespray-files
docker rm -f kubespray-registry
```

### 测试服务

```powershell
# 测试文件服务器
Invoke-WebRequest -Uri http://localhost:8080/k8s/ -UseBasicParsing

# 测试镜像仓库 (忽略 SSL 验证)
[System.Net.ServicePointManager]::ServerCertificateValidationCallback = {$true}
Invoke-WebRequest -Uri https://hub.kubespray.local:5000/v2/_catalog -UseBasicParsing

# 或使用 curl (如果安装了)
curl http://localhost:8080/k8s/
curl -k https://hub.kubespray.local:5000/v2/_catalog
```

## 使用 WSL 部署 Kubernetes

如果你使用 WSL 来部署 Kubernetes 集群:

### 1. 在 WSL 中配置 hosts

```bash
# 在 WSL 中
echo "$(ip route | grep default | awk '{print $3}') hub.kubespray.local" | sudo tee -a /etc/hosts
```

### 2. 复制证书到 WSL

```bash
# 在 WSL 中
sudo mkdir -p /etc/containerd/certs.d/hub.kubespray.local:5000
sudo cp /mnt/c/registry/certs/hub.kubespray.local.crt \
  /etc/containerd/certs.d/hub.kubespray.local:5000/ca.crt
```

### 3. 配置 Kubespray

```bash
# 获取 Windows 主机 IP
WINDOWS_IP=$(ip route | grep default | awk '{print $3}')

# 在 Kubespray 配置中使用
files_repo: "http://${WINDOWS_IP}:8080/k8s"
registry_host: "hub.kubespray.local:5000"
```

## 故障排查

### 问题 1: PowerShell 脚本执行策略

**错误**: "无法加载文件，因为在此系统上禁止运行脚本"

**解决**:
```powershell
# 以管理员身份运行
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### 问题 2: Docker 未运行

**错误**: "error during connect: This error may indicate that the docker daemon is not running"

**解决**:
1. 启动 Docker Desktop
2. 等待 Docker 完全启动
3. 重试命令

### 问题 3: 端口被占用

**错误**: "Bind for 0.0.0.0:8080 failed: port is already allocated"

**解决**:
```powershell
# 查找占用端口的进程
netstat -ano | findstr :8080

# 结束进程 (替换 PID)
taskkill /PID <PID> /F

# 或使用不同的端口
.\scripts\deploy-offline-files.ps1 -FilesPort 8081
```

### 问题 4: 证书问题

**错误**: "x509: certificate signed by unknown authority"

**解决**:
1. 确保证书已导入到 Windows 信任存储
2. 或在 Docker Desktop 中配置 insecure-registries
3. 或使用 `-k` 参数忽略证书验证

### 问题 5: hosts 文件修改失败

**错误**: "拒绝访问"

**解决**:
```powershell
# 以管理员身份运行 PowerShell
Start-Process powershell -Verb RunAs

# 然后执行
Add-Content -Path C:\Windows\System32\drivers\etc\hosts -Value "`n127.0.0.1 hub.kubespray.local"
```

## 性能优化

### 1. 配置 Docker Desktop 资源

1. 打开 Docker Desktop 设置
2. 选择 "Resources"
3. 调整:
   - CPUs: 4+
   - Memory: 8GB+
   - Disk image size: 100GB+

### 2. 使用 WSL 2 后端

1. 打开 Docker Desktop 设置
2. 选择 "General"
3. 启用 "Use the WSL 2 based engine"

### 3. 配置存储位置

如果 C 盘空间不足:

```powershell
# 移动 Docker 数据目录
# 1. 停止 Docker Desktop
# 2. 移动数据
wsl --export docker-desktop-data D:\docker\docker-desktop-data.tar
wsl --unregister docker-desktop-data
wsl --import docker-desktop-data D:\docker\data D:\docker\docker-desktop-data.tar --version 2
# 3. 启动 Docker Desktop
```

## 使用 Hyper-V 虚拟机

如果你在 Hyper-V 虚拟机中部署 Kubernetes:

### 1. 创建虚拟交换机

```powershell
# 以管理员身份运行
New-VMSwitch -Name "KubernetesSwitch" -SwitchType Internal
```

### 2. 配置网络

```powershell
# 获取虚拟交换机的网络适配器
Get-NetAdapter | Where-Object {$_.Name -like "*KubernetesSwitch*"}

# 配置 IP 地址
New-NetIPAddress -IPAddress 192.168.100.1 -PrefixLength 24 -InterfaceAlias "vEthernet (KubernetesSwitch)"
```

### 3. 配置 NAT

```powershell
New-NetNat -Name "KubernetesNAT" -InternalIPInterfaceAddressPrefix 192.168.100.0/24
```

## 备份和恢复

### 备份

```powershell
# 备份容器数据
docker export kubespray-files > kubespray-files-backup.tar
docker export kubespray-registry > kubespray-registry-backup.tar

# 备份卷数据
docker run --rm -v kubespray-offline_registry-data:/data -v C:\backup:/backup `
  alpine tar czf /backup/registry-data.tar.gz -C /data .
```

### 恢复

```powershell
# 恢复容器
docker import kubespray-files-backup.tar kubespray-files:backup
docker import kubespray-registry-backup.tar kubespray-registry:backup

# 恢复卷数据
docker run --rm -v kubespray-offline_registry-data:/data -v C:\backup:/backup `
  alpine tar xzf /backup/registry-data.tar.gz -C /data
```

## 卸载

```powershell
# 停止并删除容器
docker stop kubespray-files kubespray-registry
docker rm kubespray-files kubespray-registry

# 删除镜像
docker rmi your-username/kubespray-files:v0.1.0-2.25.0
docker rmi your-username/kubespray-images:v0.1.0-2.25.0

# 删除卷
docker volume rm kubespray-offline_files-data
docker volume rm kubespray-offline_registry-data

# 删除证书
Remove-Item -Recurse -Force C:\registry

# 清理 hosts 文件 (手动编辑)
notepad C:\Windows\System32\drivers\etc\hosts
```

## 参考资源

- [Docker Desktop for Windows 文档](https://docs.docker.com/desktop/windows/)
- [WSL 文档](https://docs.microsoft.com/en-us/windows/wsl/)
- [PowerShell 文档](https://docs.microsoft.com/en-us/powershell/)

## 获取帮助

如遇问题:
1. 查看 [故障排查](#故障排查) 部分
2. 查看 Docker Desktop 日志
3. 在 GitHub 创建 Issue

---

**提示**: Windows 环境下建议使用 WSL 2 + Docker Desktop 组合以获得最佳性能。
