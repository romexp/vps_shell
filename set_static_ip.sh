#!/bin/bash

# 检查 docker 和 docker-compose 是否安装
if ! command -v docker &> /dev/null; then
    echo "Docker 未安装，正在安装 Docker..."
    apk update && apk add docker
fi

if ! command -v docker-compose &> /dev/null; then
    echo "Docker Compose 未安装，正在安装 Docker Compose..."
    apk add docker-compose
fi

# 启动 Docker 服务
rc-update add docker boot
service docker start

# 创建部署目录
mkdir -p /opt/ldnmp && cd /opt/ldnmp

# 获取自定义域名
read -p "请输入要绑定的域名: " domain_name

# 生成 8 位随机密码
db_password=$(openssl rand -base64 8)

# 设置默认数据库名和用户名
db_name="wordpress_db"
db_user="wordpress_user"

# 创建 Docker Compose 配置文件
cat <<EOL > docker-compose.yml
version: '3.8'

services:
  nginx:
    image: nginx:alpine
    container_name: ldnmp-nginx
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx/conf:/etc/nginx/conf.d
      - ./nginx/logs:/var/log/nginx
      - ./nginx/html:/usr/share/nginx/html
    networks:
      - ldnmp-net

  php:
    image: php:7.4-fpm-alpine
    container_name: ldnmp-php
    volumes:
      - ./nginx/html:/usr/share/nginx/html
    networks:
      - ldnmp-net

  mariadb:
    image: mariadb:latest
    container_name: ldnmp-mariadb
    environment:
      MYSQL_ROOT_PASSWORD: $db_password
      MYSQL_DATABASE: $db_name
      MYSQL_USER: $db_user
      MYSQL_PASSWORD: $db_password
    ports:
      - "3306:3306"
    volumes:
      - ./mariadb/data:/var/lib/mysql
    networks:
      - ldnmp-net

networks:
  ldnmp-net:
    driver: bridge
EOL

# 启动 LDNMP 环境
docker-compose up -d

# 下载 WordPress 最新版本
curl -o wordpress.tar.gz https://wordpress.org/latest.tar.gz
tar -xzf wordpress.tar.gz
rm wordpress.tar.gz
mv wordpress/* ./nginx/html/
chown -R www-data:www-data ./nginx/html/

# 配置 Nginx 虚拟主机文件
mkdir -p nginx/conf
cat <<EOL > nginx/conf/default.conf
server {
    listen 80;
    server_name $domain_name;
    root /usr/share/nginx/html;
    index index.php index.html index.htm;

    location / {
        try_files \$uri \$uri/ /index.php?\$args;
    }

    location ~ \.php\$ {
        include fastcgi_params;
        fastcgi_pass ldnmp-php:9000;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        fastcgi_index index.php;
    }

    location ~ /\.ht {
        deny all;
    }
}
EOL

# 使用 Certbot 自动申请免费 SSL 证书（有效期三个月）
apk add certbot
certbot certonly --standalone -d $domain_name --non-interactive --agree-tos --email admin@$domain_name

# 配置 Nginx 使用 SSL
cat <<EOL > nginx/conf/ssl.conf
server {
    listen 443 ssl;
    server_name $domain_name;
    root /usr/share/nginx/html;
    index index.php index.html index.htm;

    ssl_certificate /etc/letsencrypt/live/$domain_name/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$domain_name/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;

    location / {
        try_files \$uri \$uri/ /index.php?\$args;
    }

    location ~ \.php\$ {
        include fastcgi_params;
        fastcgi_pass ldnmp-php:9000;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        fastcgi_index index.php;
    }

    location ~ /\.ht {
        deny all;
    }
}
EOL

# 重启 Nginx 服务
docker-compose restart nginx

# 输出信息
echo "WordPress 已部署，数据库信息如下："
echo "数据库名: $db_name"
echo "数据库用户: $db_user"
echo "数据库密码: $db_password"
echo "访问 http://$domain_name 完成 WordPress 安装"
