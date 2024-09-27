if [ "$(id -u)" -ne 0 ]; then
    echo "请使用 root 用户或使用 sudo 执行此命令。"
    exit 1
fi

if ! command -v ufw &> /dev/null; then
    echo "ufw 未安装，正在检查系统类型并安装..."
    if [ -f /etc/debian_version ]; then
        apt update
        apt install ufw -y
    elif [ -f /etc/redhat-release ]; then
        yum install ufw -y
    else
        echo "不支持的系统类型。"
        exit 1
    fi
    ufw enable
fi

while true; do
    ufw status numbered
    echo "选择操作: 1 - 开通端口 2 - 删除端口 0 - 退出"
    read -p "请输入选择: " choice
    case $choice in
        1)
            while true; do
                ufw status numbered
                read -p "请输入要开通的端口号（输入 0 退出）: " port
                [ "$port" -eq 0 ] && break
                ufw allow "$port"
                echo "端口 $port 已开通。"
            done
            ;;
        2)
            while true; do
                ufw status numbered
                read -p "请输入要删除的规则编号（输入 0 退出）: " num
                [ "$num" -eq 0 ] && break
                [ "$num" -gt 0 ] && ufw delete "$num" || echo "无效的输入，请输入有效的规则编号或 0 退出。"
            done
            ;;
        0)
            echo "退出程序。"
            break
            ;;
        *)
            echo "无效的选择，请输入 1、2 或 0。"
            ;;
    esac
done
