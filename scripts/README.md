# 部署脚本说明

本目录包含用于部署 Kubespray 离线服务的脚本。

## 脚本列表

### 构建脚本

#### build-multiarch-files.sh / build-multiarch-files.ps1
构建包含多架构文件的镜像（AMD64 + ARM64）。

**使用方法**:
```bash
# Linux/macOS
chmod +x build-multiarch-files.sh
./build-multiarch-files.sh

# Windows PowerShell
.\build-multiarch-files.ps1
```

**环境变量/参数**:
- `VERSION`: 版本号（默认: v0.1.0-2.25.0）
- `IMAGE_NAME`: 镜像名称（默认: kubespray-files:$VERSION）

**功能**:
1. 检查 `temp/files-amd64.list` 和 `temp/files-arm64.list` 是否存在
2. 生成 Dockerfile，下载所有架构的文件
3. 构建包含 AMD64 和 ARM64 文件的单一镜像
4. 验证镜像构建成功

**示例**:
```bash
# Linux/macOS
VERSION=v0.2.0 ./build-multiarch-files.sh

# Windows PowerShell
.\build-multiarch-files.ps1 -Version "v0.2.0" -ImageName "my-kubespray-files:v0.2.0"
```

### Linux/macOS 脚本

#### deploy-offline-files.sh
部署离线文件服务器。

**使用方法**:
```bash
chmod +x deploy-offline-files.sh
./deploy-offline-files.sh
```

**环境变量**:
- `FILES_PORT`: 文件服务器端口（默认: 8080）
- `IMAGE_NAME`: 镜像名称（默认: kubespray-files:v0.1.0-2.25.0）

**示例**:
```bash
FILES_PORT=9090 ./deploy-offline-files.sh
```

#### deploy-offline-registry.sh
部署离线镜像仓库。

**使用方法**:
```bash
chmod +x deploy-offline-registry.sh
./deploy-offline-registry.sh
```

**环境变量**:
- `REGISTRY_HOST`: 仓库域名（默认: hub.kubespray.local）
- `REGISTRY_PORT`: 仓库端口（默认: 5000）
- `CERT_DIR`: 证书目录（默认: /opt/registry/certs）
- `IMAGE_NAME`: 镜像名称（默认: kubespray-images:v0.1.0-2.25.0）

**示例**:
```bash
REGISTRY_PORT=5001 ./deploy-offline-registry.sh
```

### Windows 脚本

#### deploy-offline-files.ps1
Windows 版本的文件服务器部署脚本。

**使用方法**:
```powershell
# 以管理员身份运行 PowerShell
.\deploy-offline-files.ps1

# 或指定参数
.\deploy-offline-files.ps1 -FilesPort 8080 -ImageName "kubespray-files:v0.1.0-2.25.0"
```

**参数**:
- `-FilesPort`: 文件服务器端口（默认: 8080）
- `-ImageName`: 镜像名称（默认: kubespray-files:v0.1.0-2.25.0）

#### deploy-offline-registry.ps1
Windows 版本的镜像仓库部署脚本。

**使用方法**:
```powershell
# 以管理员身份运行 PowerShell
.\deploy-offline-registry.ps1

# 或指定参数
.\deploy-offline-registry.ps1 -RegistryHost "hub.kubespray.local" -RegistryPort 5000
```

**参数**:
- `-RegistryHost`: 仓库域名（默认: hub.kubespray.local）
- `-RegistryPort`: 仓库端口（默认: 5000）
- `-CertDir`: 证书目录（默认: C:\registry\certs）
- `-ImageName`: 镜像名称（默认: kubespray-images:v0.1.0-2.25.0）

## 功能说明

### 文件服务器脚本功能

1. 检查并停止旧容器
2. 启动新的文件服务器容器
3. 等待服务启动
4. 验证服务可用性
5. 显示使用说明

### 镜像仓库脚本功能

1. 创建证书目录
2. 生成自签名证书（如果不存在）
3. 配置 /etc/hosts（Linux/macOS）或 hosts 文件（Windows）
4. 检查并停止旧容器
5. 启动新的镜像仓库容器
6. 等待服务启动
7. 验证服务可用性
8. 显示使用说明

## 注意事项

### Linux/macOS

1. **权限要求**
   - 脚本需要执行权限: `chmod +x script.sh`
   - 修改 /etc/hosts 需要 sudo 权限

2. **依赖要求**
   - Docker 已安装并运行
   - OpenSSL（用于生成证书）
   - curl（用于验证服务）

3. **网络要求**
   - 端口 8080 和 5000 未被占用
   - 可以访问 Docker Hub（首次拉取镜像）

### Windows

1. **权限要求**
   - 需要以管理员身份运行 PowerShell
   - 修改 hosts 文件需要管理员权限

2. **依赖要求**
   - Docker Desktop for Windows 已安装并运行
   - OpenSSL（可选，用于生成证书）
   - 或使用 WSL

3. **执行策略**
   ```powershell
   # 如果无法执行脚本，运行:
   Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
   ```

## 故障排查

### 脚本执行失败

**Linux/macOS**:
```bash
# 检查脚本权限
ls -l deploy-offline-files.sh

# 添加执行权限
chmod +x deploy-offline-files.sh

# 查看详细错误
bash -x deploy-offline-files.sh
```

**Windows**:
```powershell
# 检查执行策略
Get-ExecutionPolicy

# 设置执行策略
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### 容器启动失败

```bash
# 查看容器日志
docker logs kubespray-files
docker logs kubespray-registry

# 检查端口占用
# Linux/macOS
netstat -tuln | grep 8080
netstat -tuln | grep 5000

# Windows
netstat -ano | findstr :8080
netstat -ano | findstr :5000
```

### 证书问题

```bash
# 重新生成证书
rm -rf /opt/registry/certs/*  # Linux/macOS
Remove-Item -Recurse -Force C:\registry\certs\*  # Windows

# 重新运行脚本
./deploy-offline-registry.sh  # Linux/macOS
.\deploy-offline-registry.ps1  # Windows
```

### 服务验证失败

```bash
# 检查 Docker 是否运行
docker ps

# 检查容器状态
docker ps -a | grep kubespray

# 重启容器
docker restart kubespray-files
docker restart kubespray-registry
```

## 卸载

### 停止并删除容器

**Linux/macOS**:
```bash
docker stop kubespray-files kubespray-registry
docker rm kubespray-files kubespray-registry
```

**Windows**:
```powershell
docker stop kubespray-files, kubespray-registry
docker rm kubespray-files, kubespray-registry
```

### 清理证书

**Linux/macOS**:
```bash
sudo rm -rf /opt/registry/certs
```

**Windows**:
```powershell
Remove-Item -Recurse -Force C:\registry\certs
```

### 清理 hosts 配置

**Linux/macOS**:
```bash
sudo sed -i '/hub.kubespray.local/d' /etc/hosts
```

**Windows**:
手动编辑 `C:\Windows\System32\drivers\etc\hosts`

## 更多信息

- 完整文档: [../README.md](../README.md)
- 快速开始: [../GET_STARTED.md](../GET_STARTED.md)
- Windows 指南: [../WINDOWS_GUIDE.md](../WINDOWS_GUIDE.md)
- 故障排查: [../QUICKSTART.md](../QUICKSTART.md#故障排查)

## 获取帮助

如遇问题:
1. 查看脚本输出的错误信息
2. 查看 Docker 容器日志
3. 参考故障排查部分
4. 在 GitHub 创建 Issue
