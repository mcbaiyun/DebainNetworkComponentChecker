#!/bin/bash

echo "=== Debian 网络管理器检测工具 ==="
echo

check_service() {
    local svc="$1"
    if systemctl is-active --quiet "$svc"; then
        echo "● $svc: active"
        return 0
    else
        echo "○ $svc: inactive"
        return 1
    fi
}

echo "正在检测系统中常见的网络管理组件..."
echo

# 结果变量
ACTIVE_MANAGER=""

### 1. systemd-networkd
if check_service "systemd-networkd"; then
    ACTIVE_MANAGER="systemd-networkd"
    echo
    echo "【systemd-networkd 配置文件】"
    echo "  - /etc/systemd/network/*.network"
    echo "  - /etc/systemd/network/*.netdev"
    echo "  - /etc/systemd/network/*.link"
    echo
    echo "【修改方式】"
    echo "  编辑对应的 .network 文件后执行："
    echo "    sudo systemctl restart systemd-networkd"
    echo
fi

### 2. NetworkManager
if check_service "NetworkManager"; then
    ACTIVE_MANAGER="NetworkManager"
    echo
    echo "【NetworkManager 配置文件】"
    echo "  - /etc/NetworkManager/NetworkManager.conf"
    echo "  - /etc/NetworkManager/system-connections/*.nmconnection"
    echo
    echo "【修改方式】"
    echo "  使用 nmcli 或编辑 .nmconnection 文件："
    echo "    sudo nmcli connection show"
    echo "    sudo nmcli connection edit <name>"
    echo
fi

### 3. ifupdown / ifupdown2
if [ -f /etc/network/interfaces ] && grep -q "iface" /etc/network/interfaces; then
    if dpkg -l | grep -q ifupdown2; then
        ACTIVE_MANAGER="ifupdown2"
        echo
        echo "【ifupdown2 配置文件】"
        echo "  - /etc/network/interfaces"
        echo "  - /etc/network/interfaces.d/*.cfg"
        echo
        echo "【修改方式】"
        echo "  修改后无需重启网络，可直接 reload："
        echo "    sudo ifreload -a"
        echo
    else
        ACTIVE_MANAGER="ifupdown"
        echo
        echo "【ifupdown 配置文件】"
        echo "  - /etc/network/interfaces"
        echo "  - /etc/network/interfaces.d/*.cfg"
        echo
        echo "【修改方式】"
        echo "    sudo ifdown <iface> && sudo ifup <iface>"
        echo
    fi
fi

### 4. ConnMan
if check_service "connman"; then
    ACTIVE_MANAGER="ConnMan"
    echo
    echo "【ConnMan 配置文件】"
    echo "  - /etc/connman/main.conf"
    echo "  - /var/lib/connman/*"
    echo
    echo "【修改方式】"
    echo "    sudo connmanctl"
    echo
fi

### 5. wicked（SUSE 系常见，但 Debian 也可能安装）
if check_service "wickedd"; then
    ACTIVE_MANAGER="wicked"
    echo
    echo "【wicked 配置文件】"
    echo "  - /etc/sysconfig/network/ifcfg-*"
    echo
    echo "【修改方式】"
    echo "    sudo wicked ifup <iface>"
    echo
fi

echo "====================================="
echo

if [ -z "$ACTIVE_MANAGER" ]; then
    echo "⚠️ 未检测到常见网络管理器。可能是手动使用 ip/ifconfig 管理网络。"
else
    echo "✔ 当前检测到的网络管理器：$ACTIVE_MANAGER"
fi

echo
echo "检测完成。"
