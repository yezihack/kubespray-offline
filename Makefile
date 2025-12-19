.PHONY: help build push deploy clean test

# 默认配置
DOCKERHUB_USERNAME ?= your-username
VERSION ?= v0.1.0-2.25.0
FILES_IMAGE = $(DOCKERHUB_USERNAME)/kubespray-files:$(VERSION)
IMAGES_IMAGE = $(DOCKERHUB_USERNAME)/kubespray-images:$(VERSION)

help: ## 显示帮助信息
	@echo "Kubespray 离线部署工具"
	@echo ""
	@echo "可用命令:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'

setup: ## 初始化环境
	@echo "初始化环境..."
	@cp .env.example .env
	@echo "请编辑 .env 文件配置你的参数"

build-files: ## 构建文件服务器镜像
	@echo "构建文件服务器镜像..."
	@cat > Dockerfile.files << 'EOF'\n\
	FROM nginx:1.25.2-alpine\n\
	RUN apk add --no-cache wget\n\
	RUN mkdir -p /opt/k8s/k8s\n\
	COPY temp/files.list /tmp/files.list\n\
	RUN cd /opt/k8s && wget -x -P k8s -i /tmp/files.list && rm /tmp/files.list\n\
	RUN cat > /etc/nginx/conf.d/default.conf << 'NGINX_EOF'\n\
	server {\n\
	    listen 80 default_server;\n\
	    listen [::]:80 default_server;\n\
	    location /k8s/ {\n\
	        root /opt/k8s;\n\
	        index index.html index.htm;\n\
	        autoindex on;\n\
	        autoindex_exact_size off;\n\
	        autoindex_localtime on;\n\
	    }\n\
	}\n\
	NGINX_EOF\n\
	EXPOSE 80\n\
	CMD ["nginx", "-g", "daemon off;"]\n\
	EOF
	docker build -f Dockerfile.files -t $(FILES_IMAGE) .

build-images: ## 构建镜像仓库
	@echo "构建镜像仓库..."
	@echo "注意: 此过程需要较长时间，请耐心等待"
	# 实际构建逻辑在 GitHub Actions 中

push-files: ## 推送文件服务器镜像
	@echo "推送文件服务器镜像..."
	docker push $(FILES_IMAGE)

push-images: ## 推送镜像仓库
	@echo "推送镜像仓库..."
	docker push $(IMAGES_IMAGE)

pull: ## 拉取镜像
	@echo "拉取镜像..."
	docker pull $(FILES_IMAGE)
	docker pull $(IMAGES_IMAGE)

deploy: ## 部署服务（使用 docker-compose）
	@echo "部署服务..."
	docker-compose up -d

deploy-files: ## 仅部署文件服务器
	@echo "部署文件服务器..."
	@chmod +x scripts/deploy-offline-files.sh
	@./scripts/deploy-offline-files.sh

deploy-registry: ## 仅部署镜像仓库
	@echo "部署镜像仓库..."
	@chmod +x scripts/deploy-offline-registry.sh
	@./scripts/deploy-offline-registry.sh

stop: ## 停止服务
	@echo "停止服务..."
	docker-compose down

clean: ## 清理构建文件和容器
	@echo "清理..."
	docker-compose down -v
	docker rm -f kubespray-files kubespray-registry 2>/dev/null || true
	rm -f Dockerfile.files Dockerfile.images

test: ## 测试服务
	@echo "测试文件服务器..."
	@curl -s http://localhost:8080/k8s/ > /dev/null && echo "✓ 文件服务器正常" || echo "✗ 文件服务器异常"
	@echo "测试镜像仓库..."
	@curl -sk https://hub.kubespray.local:5000/v2/_catalog > /dev/null && echo "✓ 镜像仓库正常" || echo "✗ 镜像仓库异常"

logs-files: ## 查看文件服务器日志
	docker logs -f kubespray-files

logs-registry: ## 查看镜像仓库日志
	docker logs -f kubespray-registry

status: ## 查看服务状态
	@echo "服务状态:"
	@docker ps --filter "name=kubespray" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

gen-certs: ## 生成自签名证书
	@echo "生成自签名证书..."
	@mkdir -p certs
	@openssl req -newkey rsa:4096 -nodes -sha256 \
		-keyout certs/hub.kubespray.local.key \
		-x509 -days 365 \
		-out certs/hub.kubespray.local.crt \
		-subj "/CN=hub.kubespray.local" \
		-addext "subjectAltName=DNS:hub.kubespray.local,DNS:localhost,IP:127.0.0.1"
	@echo "证书已生成到 certs/ 目录"

.DEFAULT_GOAL := help
