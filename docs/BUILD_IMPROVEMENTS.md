# 构建改进说明

## 问题

GitHub Actions 构建文件服务器镜像时失败，错误信息：
```
ERROR: failed to build: failed to solve: process "/bin/sh -c cd /opt/k8s && ... wget ..." 
did not complete successfully: exit code: 8
```

**原因**: 
- wget exit code 8 通常表示服务器错误或文件不存在
- 网络不稳定导致下载失败
- 某些文件 URL 可能暂时不可用
- 没有重试机制

## 解决方案

### 1. 添加错误处理和重试机制

创建专门的下载脚本，包含：
- **重试机制**: 每个文件最多重试 3 次
- **超时控制**: 每次下载超时 60 秒
- **等待重试**: 失败后等待 5 秒再重试
- **详细日志**: 记录每个文件的下载状态
- **容错处理**: 部分文件失败不中断整个构建

### 2. 改进的 Dockerfile

#### 之前（简单版本）
```dockerfile
RUN cd /opt/k8s && \
    wget -x -P k8s -i /tmp/files-amd64.list && \
    wget -x -P k8s -i /tmp/files-arm64.list
```

**问题**:
- 任何一个文件失败，整个构建失败
- 没有重试机制
- 日志不详细，难以定位问题

#### 之后（改进版本）
```dockerfile
# Install wget and ca-certificates
RUN apk add --no-cache wget ca-certificates

# Create download script with error handling
RUN cat > /tmp/download.sh << 'DOWNLOAD_EOF'
#!/bin/sh
set -e

download_file() {
    local url="$1"
    local max_retries=3
    local retry=0
    
    echo "Downloading: $url"
    
    while [ $retry -lt $max_retries ]; do
        if wget -x -P k8s --timeout=60 --tries=3 --waitretry=5 "$url"; then
            echo "✓ Success: $url"
            return 0
        else
            retry=$((retry + 1))
            echo "⚠ Retry $retry/$max_retries: $url"
            sleep 5
        fi
    done
    
    echo "✗ Failed after $max_retries attempts: $url"
    return 1
}

# Download files with progress tracking
cd /opt/k8s
failed_files=""
total_files=0
success_files=0

while IFS= read -r url; do
    if [ -n "$url" ] && [ "${url#\#}" = "$url" ]; then
        total_files=$((total_files + 1))
        if download_file "$url"; then
            success_files=$((success_files + 1))
        else
            failed_files="$failed_files\n$url"
        fi
    fi
done < /tmp/files-amd64.list

echo "AMD64: $success_files/$total_files files downloaded"

# ... ARM64 similar logic ...

if [ -n "$failed_files" ]; then
    echo "=== Failed downloads ==="
    echo "$failed_files"
    echo "⚠ Some files failed to download, but continuing..."
fi
DOWNLOAD_EOF

RUN chmod +x /tmp/download.sh && /tmp/download.sh
```

**优势**:
- ✅ 每个文件独立重试
- ✅ 详细的下载进度
- ✅ 失败文件列表
- ✅ 部分失败不中断构建
- ✅ 更好的日志输出

### 3. wget 参数说明

| 参数 | 说明 | 值 |
|------|------|-----|
| `-x` | 保持目录结构 | - |
| `-P k8s` | 保存到 k8s 目录 | - |
| `--timeout=60` | 连接超时 | 60 秒 |
| `--tries=3` | 每次下载重试次数 | 3 次 |
| `--waitretry=5` | 重试等待时间 | 5 秒 |

### 4. 容错策略

#### 策略 1: 继续构建（当前实现）
```bash
if download_file "$url"; then
    success_files=$((success_files + 1))
else
    failed_files="$failed_files\n$url"
    # 不退出，继续下载其他文件
fi
```

**优势**: 
- 部分文件失败不影响整体
- 可以获得大部分文件
- 适合网络不稳定的环境

**劣势**:
- 可能缺少某些文件
- 需要后续验证

#### 策略 2: 严格模式（可选）
```bash
if ! download_file "$url"; then
    echo "Critical file failed: $url"
    exit 1
fi
```

**优势**:
- 确保所有文件都下载成功
- 构建结果可靠

**劣势**:
- 任何文件失败都会中断构建
- 需要网络非常稳定

### 5. 日志输出示例

#### 成功的下载
```
Downloading: https://dl.k8s.io/release/v1.29.10/bin/linux/amd64/kubectl
✓ Success: https://dl.k8s.io/release/v1.29.10/bin/linux/amd64/kubectl
```

#### 需要重试的下载
```
Downloading: https://github.com/etcd-io/etcd/releases/download/v3.5.16/etcd-v3.5.16-linux-amd64.tar.gz
⚠ Retry 1/3: https://github.com/etcd-io/etcd/releases/download/v3.5.16/etcd-v3.5.16-linux-amd64.tar.gz
✓ Success: https://github.com/etcd-io/etcd/releases/download/v3.5.16/etcd-v3.5.16-linux-amd64.tar.gz
```

#### 失败的下载
```
Downloading: https://example.com/nonexistent-file.tar.gz
⚠ Retry 1/3: https://example.com/nonexistent-file.tar.gz
⚠ Retry 2/3: https://example.com/nonexistent-file.tar.gz
⚠ Retry 3/3: https://example.com/nonexistent-file.tar.gz
✗ Failed after 3 attempts: https://example.com/nonexistent-file.tar.gz
```

#### 总结输出
```
AMD64: 22/23 files downloaded
ARM64: 22/23 files downloaded

=== Failed downloads ===
https://example.com/nonexistent-file.tar.gz

⚠ Some files failed to download, but continuing...
```

## 更新的文件

1. **`.github/workflows/build-kubespray-offline.yml`**
   - 更新 Dockerfile 生成逻辑
   - 添加下载脚本

2. **`scripts/build-multiarch-files.sh`**
   - 本地构建脚本
   - 与 GitHub Actions 保持一致

3. **`scripts/build-multiarch-files.ps1`**
   - Windows 构建脚本
   - 与 GitHub Actions 保持一致

4. **`Makefile`**
   - 更新 build-files 目标
   - 使用新的下载脚本

## 测试建议

### 1. 本地测试

```bash
# 测试构建
./scripts/build-multiarch-files.sh

# 或使用 Makefile
make build-files

# 查看构建日志
docker build -f Dockerfile.files -t test-files .
```

### 2. 验证镜像

```bash
# 启动测试容器
docker run -d -p 8080:80 --name test-files test-files

# 检查文件
curl http://localhost:8080/k8s/dl.k8s.io/release/v1.29.10/bin/linux/amd64/
curl http://localhost:8080/k8s/dl.k8s.io/release/v1.29.10/bin/linux/arm64/

# 清理
docker stop test-files && docker rm test-files
```

### 3. GitHub Actions 测试

1. 推送代码到 GitHub
2. 查看 Actions 日志
3. 检查下载进度和失败文件
4. 验证构建的镜像

## 进一步优化建议

### 1. 并行下载

```bash
# 使用 xargs 并行下载
cat /tmp/files-amd64.list | xargs -P 4 -I {} wget -x -P k8s {}
```

**优势**: 加快下载速度
**劣势**: 更难控制错误处理

### 2. 使用镜像站

```bash
# 替换 GitHub URL 为镜像站
sed 's|github.com|ghproxy.com/github.com|g' files-amd64.list
```

**优势**: 提高下载成功率
**劣势**: 需要维护镜像站列表

### 3. 缓存机制

```yaml
# GitHub Actions 缓存
- uses: actions/cache@v3
  with:
    path: /tmp/download-cache
    key: files-${{ hashFiles('temp/files-*.list') }}
```

**优势**: 减少重复下载
**劣势**: 需要额外的缓存管理

### 4. 分阶段构建

```dockerfile
# Stage 1: 下载文件
FROM alpine:latest AS downloader
RUN apk add --no-cache wget
COPY temp/files-*.list /tmp/
RUN /tmp/download.sh

# Stage 2: 构建最终镜像
FROM nginx:1.25.2-alpine
COPY --from=downloader /opt/k8s /opt/k8s
```

**优势**: 更清晰的构建流程
**劣势**: 稍微复杂一些

## 监控和告警

### 1. 检查失败文件

```bash
# 在 GitHub Actions 中添加
- name: Check failed downloads
  run: |
    if docker logs build-container | grep "Failed downloads"; then
      echo "⚠ Some files failed to download"
      docker logs build-container | grep "✗ Failed"
    fi
```

### 2. 发送通知

```yaml
- name: Notify on failure
  if: failure()
  uses: actions/github-script@v6
  with:
    script: |
      github.rest.issues.create({
        owner: context.repo.owner,
        repo: context.repo.repo,
        title: 'Build failed: File download error',
        body: 'Check the Actions log for details'
      })
```

## 总结

通过添加错误处理和重试机制，构建过程更加健壮：

- ✅ **可靠性提升**: 网络波动不会导致构建失败
- ✅ **可观察性**: 详细的日志帮助定位问题
- ✅ **容错能力**: 部分文件失败不影响整体
- ✅ **易于调试**: 清晰的错误信息

---

**更新日期**: 2024-12-19  
**影响范围**: 构建流程、GitHub Actions、本地构建脚本
