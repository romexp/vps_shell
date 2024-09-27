#!/bin/bash

# 更新系统并安装 Docker 和 Docker Compose
apk update && apk add docker docker-compose

# 启动 Docker 服务
rc-update add docker boot
service docker start

# 创建 Docker Compose 文件夹
mkdir -p /opt/ldnmp && cd /opt/ldnmp

# 创建 Docker Compose 配置文件
cat <<EOL > docker-compose.yml
version: '3'

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
      MYSQL_ROOT_PASSWORD: rootpassword
      MYSQL_DATABASE: ldnmp_db
      MYSQL_USER: ldnmp_user
      MYSQL_PASSWORD: userpassword
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

# 拉取镜像并启动容器
docker-compose up -d

# 输出部署成功消息
echo "LDNMP environment is up and running!"

