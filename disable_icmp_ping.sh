#!/bin/bash

# 脚本名称：disable_icmp_ping.sh
# 功能：禁用 Debian 12 系统的 ICMP ping 响应
# 适用环境：Debian 12，适用于有 UFW 防火墙和无 UFW 防火墙的系统

# 方法二：临时禁用 ICMP ping
disable_icmp_ping_temp() {
    echo "临时禁用 ICMP ping..."
    sysctl -w net.ipv4.icmp_echo_ignore_all=1
    echo "临时禁用完成."
}

# 方法二：永久禁用 ICMP ping
disable_icmp_ping_perm() {
    echo "永久禁用 ICMP ping..."
    if grep -q "net.ipv4.icmp_echo_ignore_all" /etc/sysctl.conf; then
        sed -i 's/net.ipv4.icmp_echo_ignore_all=.*/net.ipv4.icmp_echo_ignore_all=1/' /etc/sysctl.conf
    else
        echo "net.ipv4.icmp_echo_ignore_all=1" >> /etc/sysctl.conf
    fi
    sysctl -p
    echo "永久禁用完成."
}

# 方法三：通过 UFW 禁用 ICMP ping
disable_icmp_ping_ufw() {
    echo "通过 UFW 禁用 ICMP ping..."
    if [ -f /etc/ufw/before.rules ]; then
        # 备份 before.rules 文件
        cp /etc/ufw/before.rules /etc/ufw/before.rules.backup

        # 修改 before.rules 文件
        sed -i '/-A ufw-before-input -p icmp --icmp-type echo-request -j ACCEPT/ s/ACCEPT/DROP/' /etc/ufw/before.rules
        
        echo "UFW 规则已更新，重启 UFW..."
        ufw reload
        echo "通过 UFW 禁用 ICMP ping 完成."
    else
        echo "/etc/ufw/before.rules 文件不存在，无法配置 UFW 规则。"
    fi
}

# 检查是否安装了 UFW
if command -v ufw >/dev/null 2>&1; then
    disable_icmp_ping_temp
    disable_icmp_ping_perm
    disable_icmp_ping_ufw
else
    echo "UFW 未安装，跳过 UFW 配置..."
    disable_icmp_ping_temp
    disable_icmp_ping_perm
fi

echo "所有操作已完成。ICMP ping 已禁用。"
