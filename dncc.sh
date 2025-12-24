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

### 检测 netplan（常见于 cloud-init 管理的 VPS）
if [ -d /etc/netplan ] && ls /etc/netplan/*.yaml >/dev/null 2>&1; then
    ACTIVE_MANAGER="netplan"
    DETAILS="【netplan 配置文件】\n  - /etc/netplan/*.yaml\n\n【修改方式】\n  编辑 YAML 文件后执行：\n    sudo netplan apply\n"

    # 检测 cloud-init 是否管理网络（cloud-init 会生成 netplan 配置）
    if [ -f /etc/cloud/cloud.cfg.d/99-disable-network-config.cfg ]; then
        CLOUDINIT_NET="disabled"
    else
        CLOUDINIT_NET="enabled"
    fi

    DETAILS+="\n【cloud-init 网络管理】\n"
    if [ "$CLOUDINIT_NET" = "enabled" ]; then
        DETAILS+="  - cloud-init 正在管理网络（会生成 /etc/netplan/50-cloud-init.yaml）\n"
        DETAILS+="\n【方法 A — 通过 cloud-init 管理网络（推荐在云环境）】\n"
        DETAILS+="  - 修改 cloud-init 用户数据（User-Data）或 /etc/cloud/cloud.cfg.d/ 中的网络配置，cloud-init 会生成 netplan 文件。\n"
        DETAILS+="  - cloud-init 通常在首次启动、手动运行网络模块、执行 'cloud-init clean' 后，或云平台重新注入 metadata 时，才会重新生成 netplan。\n"
        DETAILS+="  - 如需在实例内尝试重新生成并应用（有断网风险，确保你有控制台/救援访问权限）：\n"
        DETAILS+="      sudo cloud-init single --name cc_network_config --frequency always\n"
        DETAILS+="    （或可能使用 'sudo cloud-init init'，但不保证会重新生成网络配置，取决于 datasource 与配置）\n"
        DETAILS+="  - netplan 文件更新后执行：\n"
        DETAILS+="      sudo netplan apply\n\n"
        DETAILS+="【方法 B — 禁用 cloud-init 网络管理并直接管理 netplan】\n"
        DETAILS+="  - 禁用 cloud-init 的网络模块（此后 cloud-init 不会覆盖 /etc/netplan/50-cloud-init.yaml）：\n"
        DETAILS+="      sudo bash -c 'echo \"network: {config: disabled}\" > /etc/cloud/cloud.cfg.d/99-disable-network-config.cfg'\n"
        DETAILS+="  - 之后你可以直接编辑 /etc/netplan/*.yaml（例如：/etc/netplan/01-netcfg.yaml）：\n"
        DETAILS+="      sudo nano /etc/netplan/01-netcfg.yaml\n"
        DETAILS+="  - 修改后执行：\n"
        DETAILS+="      sudo netplan apply\n"
    else
        DETAILS+="  - cloud-init 网络管理已禁用\n"
    fi
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
