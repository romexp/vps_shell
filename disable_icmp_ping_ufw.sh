#!/bin/bash

# 脚本名称：disable_icmp_ping_ufw.sh
# 功能：通过 UFW 禁用 ICMP ping 请求
# 适用环境：Debian 12 或支持 UFW 的其他 Linux 系统

# 检查 UFW 是否已安装
if ! command -v ufw >/dev/null 2>&1; then
    echo "UFW 未安装，请先安装 UFW。"
    exit 1
fi

# 确保 UFW 已启用
ufw status | grep -q "Status: active"
if [ $? -ne 0 ]; then
    echo "UFW 未启用，正在启用..."
    ufw enable
fi

# 通过 UFW 禁用 ICMP ping
echo "通过 UFW 禁用 ICMP ping..."

# 备份 before.rules 文件
cp /etc/ufw/before.rules /etc/ufw/before.rules.backup

# 修改 before.rules 文件，丢弃 ICMP echo 请求（ping 请求）
sed -i '/-A ufw-before-input -p icmp --icmp-type echo-request -j ACCEPT/ s/ACCEPT/DROP/' /etc/ufw/before.rules

# 重新加载 UFW 规则
ufw reload

echo "ICMP ping 请求已被 UFW 禁用。"
