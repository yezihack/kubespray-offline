# 项目结构说明

```
kubespray-offline/
├── .github/
│   └── workflows/
│       └── build-kubespray-offline.yml    # GitHub Actions 工作流
├── scripts/
│   ├── deploy-offline-files.sh            # 文件服务器部署脚本
│   └── deploy-offline-registry.sh         # 镜像仓库部署脚本
├── temp/
│   ├── files.list                         # 离线文件下载列表
│   ├── files.list.template                # 文件列表模板
│   ├── images.list                        # 离线镜像列表
│   └── images.list.template               # 镜像列表模板
├── examples/
│   └── kubespray-offline-config.yml       # Kubespray 离线配置示例
├── .env.example                           # 环境变量示例
├── .gitignore                             # Git 忽略文件
├── CHANGELOG.md                           # 更新日志
├── CONTRIBUTING.md                        # 贡献指南
├── docker-compose.yml                     # Docker Compose 配置
├── Makefile                               # Make 命令集合
├── need.md                                # 需求文档
├── PROJECT_STRUCTURE.md                   # 本文件
├── QUICKSTART.md                          # 快速开始指南
└── README.md                              # 项目说明

运行时生成的文件（不提交到 Git）:
├── Dockerfile.files                       # 文件服务器 Dockerfile
├── Dockerfile.images                      # 镜像仓库 Dockerfile
├── registry-data/                         # 镜像仓库数据
├── certs/                                 # TLS 证书
└── .env                                   # 环境变量配置
```

## 目录说明

### .github/workflows/

包含 GitHub Actions 自动化工作流配置。

- `build-kubespray-offline.yml`: 主要的构建和推送工作流
  - 构建 kubespray-files 镜像
  - 构建 kubespray-images 镜像
  - 推送到 Docker Hub

### scripts/

包含部署和管理脚本。

- `deploy-offline-files.sh`: 一键部署文件服务器
- `deploy-offline-registry.sh`: 一键部署镜像仓库（包含证书生成）

### temp/

包含 Kubespray 依赖的文件和镜像列表。

- `files.list`: 实际的文件下载 URL 列表
- `files.list.template`: Kubespray 原始模板（包含变量）
- `images.list`: 实际的镜像列表
- `images.list.template`: Kubespray 原始模板（包含变量）

### examples/

包含配置示例和参考文档。

- `kubespray-offline-config.yml`: 完整的 Kubespray 离线配置示例

## 核心文件说明

### GitHub Actions 工作流

**build-kubespray-offline.yml**

- 触发条件: push 到 main 分支、创建 tag、手动触发
- 两个并行任务:
  1. `build-files`: 构建文件服务器镜像
  2. `build-images`: 构建镜像仓库
- 使用 Docker Buildx 进行构建
- 自动推送到 Docker Hub

### 部署脚本

**deploy-offline-files.sh**

- 启动 nginx 文件服务器
- 默认端口: 8080
- 提供文件浏览和下载服务

**deploy-offline-registry.sh**

- 生成自签名证书
- 配置 /etc/hosts
- 启动 Docker Registry
- 默认端口: 5000
- 支持 HTTPS

### Docker Compose

**docker-compose.yml**

- 定义两个服务: kubespray-files 和 kubespray-registry
- 配置网络和存储卷
- 包含健康检查
- 支持环境变量配置

### Makefile

提供常用命令的快捷方式:

- `make help`: 显示帮助
- `make deploy`: 部署所有服务
- `make test`: 测试服务
- `make clean`: 清理环境
- 更多命令见 `make help`

## 工作流程

### 1. 开发流程

```
编辑文件列表 → 提交代码 → GitHub Actions 构建 → 推送到 Docker Hub
```

### 2. 使用流程

```
拉取镜像 → 部署服务 → 配置 Kubespray → 部署 Kubernetes
```

### 3. 更新流程

```
更新列表 → 更新版本号 → 创建 tag → 自动构建新版本
```

## 镜像构建过程

### kubespray-files 镜像

1. 基于 nginx:1.25.2-alpine
2. 安装 wget
3. 根据 files.list 下载所有文件
4. 配置 nginx 提供文件服务
5. 暴露 80 端口

### kubespray-images 镜像

1. 启动临时 Docker Registry
2. 使用 skopeo 同步所有镜像到本地 registry
3. 打包 registry 数据到镜像
4. 基于 registry:3 创建最终镜像
5. 暴露 5000 端口

## 配置文件

### .env

运行时环境变量配置（从 .env.example 复制）:

- Docker Hub 用户名
- 版本号
- 端口配置
- 证书路径

### kubespray-offline-config.yml

Kubespray 离线部署配置:

- 文件下载源
- 镜像仓库地址
- 镜像映射关系
- containerd 配置

## 数据持久化

### 文件服务器

- 容器内路径: `/opt/k8s`
- 可选挂载: `files-data` volume

### 镜像仓库

- 容器内路径: `/var/lib/registry`
- 推荐挂载: `registry-data` volume

### 证书

- 主机路径: `./certs/` 或 `/opt/registry/certs/`
- 容器路径: `/certs/`

## 网络配置

### 端口映射

- 文件服务器: 8080:80
- 镜像仓库: 5000:5000

### 域名解析

- 镜像仓库域名: `hub.kubespray.local`
- 需要在 `/etc/hosts` 中配置

## 安全考虑

1. **证书管理**
   - 生产环境使用正式 CA 签发的证书
   - 定期更新证书

2. **访问控制**
   - 考虑添加认证机制
   - 限制网络访问范围

3. **镜像安全**
   - 定期扫描镜像漏洞
   - 及时更新基础镜像

## 故障排查

### 日志位置

- 文件服务器: `docker logs kubespray-files`
- 镜像仓库: `docker logs kubespray-registry`

### 常见问题

1. 证书问题 → 重新生成证书
2. 端口冲突 → 修改 .env 中的端口配置
3. 磁盘空间不足 → 清理旧数据或扩容

## 维护建议

1. 定期更新 Kubespray 版本
2. 定期更新基础镜像
3. 监控磁盘使用情况
4. 备份重要数据
5. 记录配置变更

## 扩展功能

可以考虑添加的功能:

- Web UI 管理界面
- 镜像使用统计
- 自动清理过期镜像
- 多版本并存
- 镜像扫描集成
- 监控告警
