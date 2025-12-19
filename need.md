# kubespray 离线文件与镜像的构建

## 需求

- 使用 github action 构建离线文件 kubespray-files:v0.1.0-2.25.0
- 使用 github action 构建离线镜像 kubespray-images:v0.1.0-2.25.0
- 推送到 hub.docker.io 上
- 版本号: v0.1.0-2.25.0，其中2.25.0是固定的，即kubespray-v2.25.0

## 文件

- temp/files.list 是离线下载地址

```sh
wget -x -P temp/files -i temp/files.list

user root;
server {
        listen 80 default_server;
        listen [::]:80 default_server;
        location /k8s/ {
            root /opt/k8s;
            index index.html index.htm;
            autoindex on;
            autoindex_exact_size off;
            autoindex_localtime on;
        }
}
```

## 镜像

- temp/images.list 是离线下载地址
- 使用域名: hub.kubespray.local
- 使用 skopeo 将依赖的镜像同步到我们自己的镜像仓库
- `for image in $(cat temp/images.list); do skopeo copy docker://${image} docker://hub.kubespray.local/k8s/${image#*/}; done`

```sh
mkdir -p /opt/registry/{certs,auth}

# 假设你已有 hub.kubespray.local.crt 和 hub.kubespray.local.key
cp hub.kubespray.local.crt /opt/registry/certs/
cp hub.kubespray.local.key /opt/registry/certs/

docker run -d \
  -p 5000:5000 \
  --restart always \
  --name registry \
  -v /opt/registry/certs:/certs \
  -e REGISTRY_HTTP_TLS_CERTIFICATE=/certs/hub.kubespray.local.crt \
  -e REGISTRY_HTTP_TLS_KEY=/certs/hub.kubespray.local.key \
  registry:3

# 验证
curl http://hub.kubespray.local:5000/v2/_catalog

# 4. 验证镜像已推送
curl http://hub.kubespray.local:5000/v2/_catalog
curl http://hub.kubespray.local:5000/v2/nginx/tags/list

```
