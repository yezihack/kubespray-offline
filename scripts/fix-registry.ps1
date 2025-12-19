# PowerShell 脚本 - 修复镜像仓库配置问题

Write-Host "=== Kubespray 镜像仓库修复脚本 ===" -ForegroundColor Green
Write-Host ""

# 停止并删除旧容器
Write-Host "1. 停止旧容器..." -ForegroundColor Yellow
$oldContainer = docker ps -a --filter "name=kubespray-registry" --format "{{.Names}}"
if ($oldContainer) {
    docker stop kubespray-registry 2>$null
    docker rm kubespray-registry 2>$null
}

# 创建配置目录
Write-Host "2. 创建配置文件..." -ForegroundColor Yellow
$configDir = "C:\registry\config"
New-Item -ItemType Directory -Force -Path $configDir | Out-Null

# 创建配置文件
$configContent = @'
version: 0.1
log:
  fields:
    service: registry
  level: info
storage:
  cache:
    blobdescriptor: inmemory
  filesystem:
    rootdirectory: /var/lib/registry
  delete:
    enabled: true
http:
  addr: :5000
  headers:
    X-Content-Type-Options: [nosniff]
    Access-Control-Allow-Origin: ['*']
    Access-Control-Allow-Methods: ['HEAD', 'GET', 'OPTIONS', 'DELETE']
    Access-Control-Allow-Headers: ['Authorization', 'Accept']
    Access-Control-Max-Age: [1728000]
    Access-Control-Allow-Credentials: [true]
    Access-Control-Expose-Headers: ['Docker-Content-Digest']
health:
  storagedriver:
    enabled: true
    interval: 10s
    threshold: 3
'@

Set-Content -Path "$configDir\config.yml" -Value $configContent
Write-Host "✓ 配置文件已创建: $configDir\config.yml" -ForegroundColor Green

# 启动容器
Write-Host "3. 启动镜像仓库..." -ForegroundColor Yellow
docker run -d `
  -p 5000:5000 `
  --restart always `
  --name kubespray-registry `
  -v "${configDir}\config.yml:/etc/docker/registry/config.yml:ro" `
  sgfoot/kubespray-images:v0.1.0-2.25.0

if ($LASTEXITCODE -ne 0) {
    Write-Host "✗ 启动失败！" -ForegroundColor Red
    exit 1
}

# 等待启动
Write-Host "4. 等待服务启动..." -ForegroundColor Yellow
Start-Sleep -Seconds 5

# 验证
Write-Host "5. 验证服务..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "http://localhost:5000/v2/_catalog" -UseBasicParsing -TimeoutSec 5
    if ($response.StatusCode -eq 200) {
        Write-Host "✓ 镜像仓库启动成功！" -ForegroundColor Green
        Write-Host ""
        Write-Host "=== 使用方法 ===" -ForegroundColor Cyan
        Write-Host "查看镜像列表:"
        Write-Host "  curl http://localhost:5000/v2/_catalog"
        Write-Host ""
        Write-Host "查看特定镜像标签:"
        Write-Host "  curl http://localhost:5000/v2/k8s/pause/tags/list"
        Write-Host ""
        Write-Host "拉取镜像:"
        Write-Host "  docker pull localhost:5000/k8s/pause:3.9"
    }
} catch {
    Write-Host "✗ 服务验证失败，请检查日志:" -ForegroundColor Red
    Write-Host "  docker logs kubespray-registry"
    exit 1
}
