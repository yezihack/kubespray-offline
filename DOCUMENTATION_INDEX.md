# 文档索引

欢迎使用 Kubespray 离线部署工具！本文档索引帮助你快速找到需要的信息。

## 📖 快速导航

### 🚀 新手入门

| 文档 | 描述 | 适合人群 |
|------|------|----------|
| [GET_STARTED.md](GET_STARTED.md) | 5 分钟快速开始 | 所有用户 |
| [QUICKSTART.md](QUICKSTART.md) | 详细的快速开始指南 | 新手用户 |
| [README.md](README.md) | 项目概述和功能介绍 | 所有用户 |

### 💻 平台特定指南

| 文档 | 描述 | 适合人群 |
|------|------|----------|
| [WINDOWS_GUIDE.md](WINDOWS_GUIDE.md) | Windows 平台使用指南 | Windows 用户 |
| [QUICKSTART.md](QUICKSTART.md) | Linux/macOS 使用指南 | Linux/macOS 用户 |
| [MULTI_ARCH_GUIDE.md](MULTI_ARCH_GUIDE.md) | 多架构支持指南 | ARM64/混合架构用户 |

### 🔧 配置和使用

| 文档 | 描述 | 适合人群 |
|------|------|----------|
| [examples/kubespray-offline-config.yml](examples/kubespray-offline-config.yml) | Kubespray 离线配置示例 | 部署人员 |
| [docker-compose.yml](docker-compose.yml) | Docker Compose 配置 | 运维人员 |
| [.env.example](.env.example) | 环境变量配置示例 | 运维人员 |

### 📚 深入了解

| 文档 | 描述 | 适合人群 |
|------|------|----------|
| [PROJECT_STRUCTURE.md](PROJECT_STRUCTURE.md) | 项目结构说明 | 开发者 |
| [IMPLEMENTATION_SUMMARY.md](IMPLEMENTATION_SUMMARY.md) | 实现细节和技术总结 | 开发者 |
| [ARCHITECTURE_DESIGN.md](ARCHITECTURE_DESIGN.md) | 多架构支持架构设计 | 开发者/架构师 |
| [MULTIARCH_FILES_BUILD.md](MULTIARCH_FILES_BUILD.md) | 多架构文件镜像构建指南 | 开发者 |
| [CONTRIBUTING.md](CONTRIBUTING.md) | 贡献指南 | 贡献者 |
| [CHANGELOG.md](CHANGELOG.md) | 更新日志 | 所有用户 |

### 🐳 Docker Hub 文档

| 文档 | 描述 | 用途 |
|------|------|------|
| [DOCKERHUB_OVERVIEW_FILES.md](DOCKERHUB_OVERVIEW_FILES.md) | 文件服务器镜像说明 | Docker Hub Overview |
| [DOCKERHUB_OVERVIEW_IMAGES.md](DOCKERHUB_OVERVIEW_IMAGES.md) | 镜像仓库说明 | Docker Hub Overview |

## 📋 按使用场景查找

### 场景 1: 我是新手，想快速开始

1. 阅读 [GET_STARTED.md](GET_STARTED.md)
2. 根据你的操作系统:
   - Windows: 阅读 [WINDOWS_GUIDE.md](WINDOWS_GUIDE.md)
   - Linux/macOS: 阅读 [QUICKSTART.md](QUICKSTART.md)
3. 参考 [examples/kubespray-offline-config.yml](examples/kubespray-offline-config.yml) 配置 Kubespray

### 场景 2: 我想了解项目功能

1. 阅读 [README.md](README.md) - 项目概述
2. 查看 [CHANGELOG.md](CHANGELOG.md) - 了解版本历史
3. 阅读 [IMPLEMENTATION_SUMMARY.md](IMPLEMENTATION_SUMMARY.md) - 了解技术细节

### 场景 3: 我想部署到生产环境

1. 阅读 [QUICKSTART.md](QUICKSTART.md) - 完整部署流程
2. 参考 [examples/kubespray-offline-config.yml](examples/kubespray-offline-config.yml) - 生产配置
3. 查看 [PROJECT_STRUCTURE.md](PROJECT_STRUCTURE.md) - 了解架构
4. 阅读安全和性能优化部分

### 场景 4: 我想贡献代码

1. 阅读 [CONTRIBUTING.md](CONTRIBUTING.md) - 贡献指南
2. 查看 [PROJECT_STRUCTURE.md](PROJECT_STRUCTURE.md) - 项目结构
3. 阅读 [IMPLEMENTATION_SUMMARY.md](IMPLEMENTATION_SUMMARY.md) - 实现细节
4. 查看 [.github/workflows/build-kubespray-offline.yml](.github/workflows/build-kubespray-offline.yml) - CI/CD 流程

### 场景 5: 我遇到了问题

1. 查看对应平台指南的"故障排查"部分:
   - Windows: [WINDOWS_GUIDE.md](WINDOWS_GUIDE.md#故障排查)
   - Linux/macOS: [QUICKSTART.md](QUICKSTART.md#故障排查)
2. 查看 GitHub Issues
3. 创建新的 Issue

## 📁 文件清单

### 核心文档

```
├── README.md                          # 项目说明
├── GET_STARTED.md                     # 快速开始（推荐首先阅读）
├── QUICKSTART.md                      # 详细快速开始指南
├── WINDOWS_GUIDE.md                   # Windows 使用指南
├── DOCUMENTATION_INDEX.md             # 本文档
├── PROJECT_STRUCTURE.md               # 项目结构
├── IMPLEMENTATION_SUMMARY.md          # 实现总结
├── CONTRIBUTING.md                    # 贡献指南
└── CHANGELOG.md                       # 更新日志
```

### 配置文件

```
├── .env.example                       # 环境变量示例
├── docker-compose.yml                 # Docker Compose 配置
├── Makefile                           # Make 命令
└── examples/
    └── kubespray-offline-config.yml   # Kubespray 配置示例
```

### 脚本文件

```
└── scripts/
    ├── deploy-offline-files.sh        # Linux/macOS 文件服务器部署
    ├── deploy-offline-registry.sh     # Linux/macOS 镜像仓库部署
    ├── deploy-offline-files.ps1       # Windows 文件服务器部署
    └── deploy-offline-registry.ps1    # Windows 镜像仓库部署
```

### 数据文件

```
└── temp/
    ├── files.list                     # 文件下载列表
    ├── files.list.template            # 文件列表模板
    ├── images.list                    # 镜像列表
    └── images.list.template           # 镜像列表模板
```

### CI/CD

```
└── .github/
    └── workflows/
        └── build-kubespray-offline.yml # GitHub Actions 工作流
```

## 🔍 按主题查找

### 安装和部署

- [GET_STARTED.md](GET_STARTED.md) - 快速开始
- [QUICKSTART.md](QUICKSTART.md) - 详细部署步骤
- [WINDOWS_GUIDE.md](WINDOWS_GUIDE.md) - Windows 部署
- [scripts/](scripts/) - 部署脚本

### 配置

- [examples/kubespray-offline-config.yml](examples/kubespray-offline-config.yml) - Kubespray 配置
- [.env.example](.env.example) - 环境变量
- [docker-compose.yml](docker-compose.yml) - Docker Compose

### 开发

- [CONTRIBUTING.md](CONTRIBUTING.md) - 如何贡献
- [PROJECT_STRUCTURE.md](PROJECT_STRUCTURE.md) - 项目结构
- [IMPLEMENTATION_SUMMARY.md](IMPLEMENTATION_SUMMARY.md) - 技术实现
- [.github/workflows/](..github/workflows/) - CI/CD 配置

### 故障排查

- [QUICKSTART.md#故障排查](QUICKSTART.md#故障排查) - Linux/macOS
- [WINDOWS_GUIDE.md#故障排查](WINDOWS_GUIDE.md#故障排查) - Windows

### 维护和更新

- [CHANGELOG.md](CHANGELOG.md) - 版本历史
- [CONTRIBUTING.md](CONTRIBUTING.md) - 更新流程
- [IMPLEMENTATION_SUMMARY.md](IMPLEMENTATION_SUMMARY.md) - 维护指南

## 📊 文档阅读顺序建议

### 初学者路径

1. [README.md](README.md) - 了解项目
2. [GET_STARTED.md](GET_STARTED.md) - 快速开始
3. [QUICKSTART.md](QUICKSTART.md) 或 [WINDOWS_GUIDE.md](WINDOWS_GUIDE.md) - 详细步骤
4. [examples/kubespray-offline-config.yml](examples/kubespray-offline-config.yml) - 配置参考

### 运维人员路径

1. [README.md](README.md) - 项目概述
2. [QUICKSTART.md](QUICKSTART.md) - 部署流程
3. [PROJECT_STRUCTURE.md](PROJECT_STRUCTURE.md) - 架构理解
4. [IMPLEMENTATION_SUMMARY.md](IMPLEMENTATION_SUMMARY.md) - 技术细节
5. 故障排查部分 - 问题解决

### 开发者路径

1. [README.md](README.md) - 项目概述
2. [PROJECT_STRUCTURE.md](PROJECT_STRUCTURE.md) - 项目结构
3. [IMPLEMENTATION_SUMMARY.md](IMPLEMENTATION_SUMMARY.md) - 实现细节
4. [CONTRIBUTING.md](CONTRIBUTING.md) - 贡献指南
5. [.github/workflows/build-kubespray-offline.yml](.github/workflows/build-kubespray-offline.yml) - CI/CD

## 🆘 获取帮助

### 文档内查找

1. 使用文档内的搜索功能（Ctrl+F / Cmd+F）
2. 查看相关文档的目录
3. 参考本索引的场景导航

### 外部资源

- **GitHub Issues**: 报告问题和功能请求
- **GitHub Discussions**: 讨论和问答
- **Kubespray 官方文档**: https://kubespray.io/
- **Kubernetes 文档**: https://kubernetes.io/docs/

### 常见问题快速链接

- 如何开始？→ [GET_STARTED.md](GET_STARTED.md)
- Windows 怎么用？→ [WINDOWS_GUIDE.md](WINDOWS_GUIDE.md)
- 如何配置 Kubespray？→ [examples/kubespray-offline-config.yml](examples/kubespray-offline-config.yml)
- 遇到错误怎么办？→ 查看对应平台指南的故障排查部分
- 如何贡献代码？→ [CONTRIBUTING.md](CONTRIBUTING.md)
- 项目结构是什么？→ [PROJECT_STRUCTURE.md](PROJECT_STRUCTURE.md)

## 📝 文档更新

本文档索引会随着项目更新而更新。如果你发现：

- 文档链接失效
- 缺少重要文档
- 分类不合理
- 其他改进建议

请创建 Issue 或提交 PR。

---

**最后更新**: 2024-12-19

**文档版本**: v0.1.0-2.25.0

**维护者**: 项目团队

---

💡 **提示**: 建议将本文档加入书签，方便随时查阅！
