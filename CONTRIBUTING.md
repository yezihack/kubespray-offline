# 贡献指南

感谢你对本项目的关注！

## 如何贡献

### 报告问题

如果你发现了 bug 或有功能建议，请：

1. 检查是否已有相关 issue
2. 创建新 issue，提供详细信息：
   - 问题描述
   - 复现步骤
   - 期望行为
   - 实际行为
   - 环境信息（OS、Docker 版本等）

### 提交代码

1. Fork 本仓库
2. 创建特性分支：`git checkout -b feature/your-feature`
3. 提交更改：`git commit -am 'Add some feature'`
4. 推送到分支：`git push origin feature/your-feature`
5. 创建 Pull Request

### 更新文件列表

如果需要更新 Kubespray 版本或添加新文件：

1. 更新 `temp/files.list` - 添加新的下载链接
2. 更新 `temp/images.list` - 添加新的镜像
3. 更新 `README.md` 中的版本号
4. 更新 `.github/workflows/build-kubespray-offline.yml` 中的 `KUBESPRAY_VERSION`

### 测试

在提交 PR 前，请确保：

1. 本地构建成功
2. 镜像可以正常启动
3. 文件和镜像可以正常访问
4. 文档已更新

### 代码规范

- Shell 脚本使用 `shellcheck` 检查
- YAML 文件使用 `yamllint` 检查
- 提交信息遵循 [Conventional Commits](https://www.conventionalcommits.org/)

## 开发环境设置

```bash
# 克隆仓库
git clone https://github.com/your-username/kubespray-offline.git
cd kubespray-offline

# 本地测试构建
docker build -f Dockerfile.files -t kubespray-files:test .
docker build -f Dockerfile.images -t kubespray-images:test .

# 运行测试
./scripts/deploy-offline-files.sh
./scripts/deploy-offline-registry.sh
```

## 发布流程

1. 更新版本号
2. 更新 CHANGELOG.md
3. 创建 tag：`git tag v0.1.0-2.25.0`
4. 推送 tag：`git push origin v0.1.0-2.25.0`
5. GitHub Actions 自动构建和推送镜像

## 联系方式

如有问题，请通过以下方式联系：

- 创建 GitHub Issue
- 发送邮件到维护者

## 许可证

通过贡献代码，你同意你的贡献将在与本项目相同的许可证下发布。
