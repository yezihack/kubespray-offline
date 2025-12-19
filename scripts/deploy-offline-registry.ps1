# PowerShell 脚本 - 部署离线镜像仓库

param(
    [string]$RegistryHost = "hub.kubespray.local",
    [string]$RegistryPort = "5000",
    [string]$CertDir = "C:\registry\certs",
    [string]$ImageName = "kubespray-images:v0.1.0-2.25.0"
)

Write-Host "=== Kubespray 离线镜像仓库部署 ===" -ForegroundColor Green
Write-Host "Registry Host: $RegistryHost"
Write-Host "Registry Port: $RegistryPort"
Write-Host "Image: $ImageName"
Write-Host ""

# 创建证书目录
Write-Host "1. 创建证书目录..." -ForegroundColor Yellow
if (-not (Test-Path $CertDir)) {
    New-Item -ItemType Directory -Path $CertDir -Force | Out-Null
}

# 生成自签名证书
$certPath = Join-Path $CertDir "${RegistryHost}.crt"
$keyPath = Join-Path $CertDir "${RegistryHost}.key"

if (-not (Test-Path $certPath)) {
    Write-Host "2. 生成自签名证书..." -ForegroundColor Yellow
    Write-Host "注意: Windows 下需要安装 OpenSSL 或使用 WSL" -ForegroundColor Yellow
    
    # 检查是否有 openssl
    $opensslPath = Get-Command openssl -ErrorAction SilentlyContinue
    if ($opensslPath) {
        openssl req -newkey rsa:4096 -nodes -sha256 `
            -keyout $keyPath `
            -x509 -days 365 `
            -out $certPath `
            -subj "/CN=$RegistryHost" `
            -addext "subjectAltName=DNS:$RegistryHost,DNS:localhost,IP:127.0.0.1"
        Write-Host "证书已生成: $certPath" -ForegroundColor Green
    } else {
        Write-Host "未找到 OpenSSL，请手动生成证书或使用 WSL" -ForegroundColor Red
        Write-Host "WSL 命令示例:" -ForegroundColor Yellow
        Write-Host "  wsl openssl req -newkey rsa:4096 -nodes -sha256 -keyout $keyPath -x509 -days 365 -out $certPath -subj '/CN=$RegistryHost'"
        exit 1
    }
} else {
    Write-Host "2. 证书已存在，跳过生成" -ForegroundColor Yellow
}

# 配置 hosts
Write-Host "3. 配置 hosts 文件..." -ForegroundColor Yellow
$hostsPath = "$env:SystemRoot\System32\drivers\etc\hosts"
$hostsContent = Get-Content $hostsPath -Raw
if ($hostsContent -notmatch $RegistryHost) {
    Write-Host "需要管理员权限添加 hosts 记录" -ForegroundColor Yellow
    $hostsEntry = "`n127.0.0.1 $RegistryHost"
    try {
        Add-Content -Path $hostsPath -Value $hostsEntry -Force
        Write-Host "已添加 hosts 记录" -ForegroundColor Green
    } catch {
        Write-Host "添加 hosts 失败，请手动添加:" -ForegroundColor Red
        Write-Host "  127.0.0.1 $RegistryHost"
    }
} else {
    Write-Host "hosts 记录已存在" -ForegroundColor Yellow
}

# 停止并删除旧容器
Write-Host "4. 检查旧容器..." -ForegroundColor Yellow
$oldContainer = docker ps -a --filter "name=kubespray-registry" --format "{{.Names}}"
if ($oldContainer) {
    Write-Host "停止旧容器..."
    docker stop kubespray-registry 2>$null
    docker rm kubespray-registry 2>$null
}

# 启动镜像仓库
Write-Host "5. 启动镜像仓库..." -ForegroundColor Yellow

# 转换 Windows 路径为 Docker 路径
$dockerCertPath = $CertDir -replace '\\', '/' -replace '^([A-Z]):', '/$1'

docker run -d `
    -p "${RegistryPort}:5000" `
    --restart always `
    --name kubespray-registry `
    -v "${CertDir}:/certs" `
    -e "REGISTRY_HTTP_TLS_CERTIFICATE=/certs/${RegistryHost}.crt" `
    -e "REGISTRY_HTTP_TLS_KEY=/certs/${RegistryHost}.key" `
    $ImageName

if ($LASTEXITCODE -ne 0) {
    Write-Host "✗ 启动失败！" -ForegroundColor Red
    exit 1
}

# 等待启动
Write-Host "6. 等待服务启动..." -ForegroundColor Yellow
Start-Sleep -Seconds 5

# 验证
Write-Host "7. 验证服务..." -ForegroundColor Yellow
try {
    # 忽略 SSL 证书验证
    [System.Net.ServicePointManager]::ServerCertificateValidationCallback = {$true}
    $response = Invoke-WebRequest -Uri "https://${RegistryHost}:${RegistryPort}/v2/_catalog" -UseBasicParsing -TimeoutSec 10
    
    if ($response.StatusCode -eq 200) {
        Write-Host "✓ 镜像仓库启动成功！" -ForegroundColor Green
        Write-Host ""
        Write-Host "=== 使用方法 ===" -ForegroundColor Cyan
        Write-Host "查看镜像列表:"
        Write-Host "  curl -k https://${RegistryHost}:${RegistryPort}/v2/_catalog"
        Write-Host ""
        Write-Host "查看特定镜像标签:"
        Write-Host "  curl -k https://${RegistryHost}:${RegistryPort}/v2/k8s/pause/tags/list"
        Write-Host ""
        Write-Host "配置 Docker 使用此仓库:"
        Write-Host "  1. 打开 Docker Desktop"
        Write-Host "  2. Settings -> Docker Engine"
        Write-Host "  3. 添加 insecure-registries: [`"${RegistryHost}:${RegistryPort}`"]"
    }
} catch {
    Write-Host "✗ 镜像仓库启动失败，请检查日志:" -ForegroundColor Red
    Write-Host "  docker logs kubespray-registry"
    Write-Host ""
    Write-Host "错误信息: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
