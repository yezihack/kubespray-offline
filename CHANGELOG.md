# 更新日志

所有重要的项目更改都将记录在此文件中。

格式基于 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.0.0/)，
版本号遵循 [语义化版本](https://semver.org/lang/zh-CN/)。

## [v0.1.0-2.25.0] - 2024-12-19

### 新增

- 初始版本发布
- 支持 Kubespray v2.25.0
- GitHub Actions 自动构建工作流
- kubespray-files 镜像（离线文件服务）
  - Kubernetes v1.29.10 二进制文件
  - etcd v3.5.16
  - CNI plugins v1.3.0
  - Calico v3.27.4
  - Cilium CLI v0.16.0
  - containerd v1.7.22
  - 其他必需工具和组件
- kubespray-images 镜像（离线镜像仓库）
  - Kubernetes 核心组件镜像
  - 网络插件镜像（Calico, Cilium, Flannel, Weave）
  - 存储插件镜像
  - 监控和管理工具镜像
  - 共计 50+ 个镜像
- 部署脚本
  - deploy-offline-files.sh
  - deploy-offline-registry.sh
- 文档
  - README.md - 项目说明
  - QUICKSTART.md - 快速开始指南
  - CONTRIBUTING.md - 贡献指南
  - examples/kubespray-offline-config.yml - 配置示例

### 技术细节

- 基于 nginx:1.25.2-alpine 构建文件服务器
- 基于 registry:3 构建镜像仓库
- 支持 HTTPS/TLS 配置
- 自动生成自签名证书
- 镜像使用 skopeo 同步

## [未发布]

### 计划

- [ ] 支持多架构（arm64）
- [ ] 添加镜像压缩和优化
- [ ] 支持增量更新
- [ ] 添加 Web UI 管理界面
- [ ] 支持自定义镜像列表
- [ ] 添加健康检查端点
- [ ] 支持镜像缓存清理
- [ ] 添加使用统计和监控

### 考虑中

- 支持其他 Kubernetes 发行版
- 添加镜像扫描功能
- 支持镜像签名验证
- 提供 Helm Chart 部署方式

---

[v0.1.0-2.25.0]: https://github.com/your-username/kubespray-offline/releases/tag/v0.1.0-2.25.0
