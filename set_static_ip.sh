#!/bin/bash

# 检测操作系统类型
if grep -qi 'alpine' /etc/os-release; then
    os="alpine"
elif grep -qi 'debian' /etc/os-release || grep -qi 'ubuntu' /etc/os-release; then
    os="debian"
else
    echo "不支持的操作系统类型。"
    exit 1
fi

# 获取用户输入的静态 IP 配置
read -p "请输入要设置的静态IP地址（如：192.168.2.5）: " ip_address
read -p "请输入子网掩码（如：255.255.255.0）: " netmask
read -p "请输入网关地址（如：192.168.2.1）: " gateway
read -p "请输入DNS服务器（多个DNS用空格隔开，如：8.8.8.8 8.8.4.4）: " dns_servers

# 根据操作系统类型进行配置
if [ "$os" = "alpine" ]; then
    # 配置 Alpine Linux 的网络
    echo -e "正在配置 Alpine Linux 的静态 IP..."

    # 备份网络配置文件
    cp /etc/network/interfaces /etc/network/interfaces.backup

    # 写入新的静态 IP 配置
    cat <<EOL > /etc/network/interfaces
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet static
    address $ip_address
    netmask $netmask
    gateway $gateway
    dns-nameservers $dns_servers
EOL

    # 重新启动网络服务
    /etc/init.d/networking restart

elif [ "$os" = "debian" ]; then
    # 配置 Debian/Ubuntu 的网络
    echo -e "正在配置 Debian/Ubuntu 的静态 IP..."

    # 备份网络配置文件
    cp /etc/network/interfaces /etc/network/interfaces.backup

    # 写入新的静态 IP 配置
    cat <<EOL > /etc/network/interfaces
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet static
    address $ip_address
    netmask $netmask
    gateway $gateway
    dns-nameservers $dns_servers
EOL

    # 重新启动网络服务
    systemctl restart networking
else
    echo "不支持的操作系统类型。"
    exit 1
fi

echo "静态IP配置已完成。"
