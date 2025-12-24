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
DETAILS=""

### 1. systemd-networkd
if check_service "systemd-networkd"; then
    ACTIVE_MANAGER="systemd-networkd"
    DETAILS="【systemd-networkd 配置文件】\n  - /etc/systemd/network/*.network\n  - /etc/systemd/network/*.netdev\n  - /etc/systemd/network/*.link\n\n【修改方式】\n  编辑对应的 .network 文件后执行：\n    sudo systemctl restart systemd-networkd\n"
fi

### 2. NetworkManager
if check_service "NetworkManager"; then
    ACTIVE_MANAGER="NetworkManager"
    DETAILS="【NetworkManager 配置文件】\n  - /etc/NetworkManager/NetworkManager.conf\n  - /etc/NetworkManager/system-connections/*.nmconnection\n\n【修改方式】\n  使用 nmcli 或编辑 .nmconnection 文件：\n    sudo nmcli connection show\n    sudo nmcli connection edit <name>\n"
fi

### 3. ifupdown / ifupdown2
if [ -f /etc/network/interfaces ] && grep -q "iface" /etc/network/interfaces; then
    if dpkg -l | grep -q ifupdown2; then
        ACTIVE_MANAGER="ifupdown2"
        DETAILS="【ifupdown2 配置文件】\n  - /etc/network/interfaces\n  - /etc/network/interfaces.d/*.cfg\n\n【修改方式】\n  修改后无需重启网络，可直接 reload：\n    sudo ifreload -a\n"
    else
        ACTIVE_MANAGER="ifupdown"
        DETAILS="【ifupdown 配置文件】\n  - /etc/network/interfaces\n  - /etc/network/interfaces.d/*.cfg\n\n【修改方式】\n    sudo ifdown <iface> && sudo ifup <iface>\n"
    fi
fi

### 4. ConnMan
if check_service "connman"; then
    ACTIVE_MANAGER="ConnMan"
    DETAILS="【ConnMan 配置文件】\n  - /etc/connman/main.conf\n  - /var/lib/connman/*\n\n【修改方式】\n    sudo connmanctl\n"
fi

### 5. wicked（SUSE 系常见，但 Debian 也可能安装）
if check_service "wickedd"; then
    ACTIVE_MANAGER="wicked"
    DETAILS="【wicked 配置文件】\n  - /etc/sysconfig/network/ifcfg-*\n\n【修改方式】\n    sudo wicked ifup <iface>\n"
fi

echo
echo "检测完成。"
echo

if [ -z "$ACTIVE_MANAGER" ]; then
    echo "⚠️ 未检测到常见网络管理器。可能是手动使用 ip/ifconfig 管理网络。"
else
    echo "✔ 当前检测到的网络管理器：$ACTIVE_MANAGER"
    echo
    echo -e "$DETAILS"
fi

echo "====================================="
echo
