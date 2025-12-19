# PowerShell 脚本 - 部署离线文件服务器

param(
    [string]$FilesPort = "8080",
    [string]$ImageName = "kubespray-files:v0.1.0-2.25.0"
)

Write-Host "=== Kubespray 离线文件服务器部署 ===" -ForegroundColor Green
Write-Host "Port: $FilesPort"
Write-Host "Image: $ImageName"
Write-Host ""

# 停止并删除旧容器
Write-Host "1. 检查旧容器..." -ForegroundColor Yellow
$oldContainer = docker ps -a --filter "name=kubespray-files" --format "{{.Names}}"
if ($oldContainer) {
    Write-Host "停止旧容器..."
    docker stop kubespray-files 2>$null
    docker rm kubespray-files 2>$null
}

# 启动文件服务器
Write-Host "2. 启动文件服务器..." -ForegroundColor Yellow
docker run -d `
    -p "${FilesPort}:80" `
    --restart always `
    --name kubespray-files `
    $ImageName

if ($LASTEXITCODE -ne 0) {
    Write-Host "✗ 启动失败！" -ForegroundColor Red
    exit 1
}

# 等待启动
Write-Host "3. 等待服务启动..." -ForegroundColor Yellow
Start-Sleep -Seconds 3

# 验证
Write-Host "4. 验证服务..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "http://localhost:${FilesPort}/k8s/" -UseBasicParsing -TimeoutSec 5
    if ($response.StatusCode -eq 200) {
        Write-Host "✓ 文件服务器启动成功！" -ForegroundColor Green
        Write-Host ""
        Write-Host "=== 使用方法 ===" -ForegroundColor Cyan
        Write-Host "浏览文件列表:"
        Write-Host "  http://localhost:${FilesPort}/k8s/"
        Write-Host ""
        Write-Host "下载示例 (kubectl):"
        Write-Host "  curl -O http://localhost:${FilesPort}/k8s/dl.k8s.io/release/v1.29.10/bin/linux/amd64/kubectl"
        Write-Host ""
        Write-Host "配置 Kubespray:"
        $ip = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object {$_.InterfaceAlias -notlike "*Loopback*"} | Select-Object -First 1).IPAddress
        Write-Host "  files_repo: `"http://${ip}:${FilesPort}/k8s`""
    }
} catch {
    Write-Host "✗ 文件服务器启动失败，请检查日志:" -ForegroundColor Red
    Write-Host "  docker logs kubespray-files"
    exit 1
}
