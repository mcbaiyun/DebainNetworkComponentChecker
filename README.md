# DebainNetworkComponentChecker

检测并帮助定位 Debian/Ubuntu 上常见网络管理组件的状态与配置路径的轻量级 Bash 脚本集合（核心脚本：`dncc.sh`）。

仓库地址： https://github.com/mcbaiyun/DebainNetworkComponentChecker

## 项目概述

该项目通过 `dncc.sh` 快速检测系统中是否正在运行以下网络管理器：

- `systemd-networkd`
- `NetworkManager`
- `ifupdown` / `ifupdown2`
- `ConnMan`
- `wickedd`（SUSE 环境下常见，Debian 亦可能安装）

脚本会先逐行输出各服务的活动状态（active/inactive），检测完成后汇总当前检测到的网络管理器，并展示对应的配置文件路径与常见修改方式，便于定位网络配置冲突与快速修复。

## 功能特性

- 输出各常见网络管理器的运行状态（● active / ○ inactive）
- 在检测完成后显示被检测到的管理器及其配置文件路径和修改命令示例
- 兼顾 `ifupdown` 系列与现代的 `systemd-networkd` / `NetworkManager`
- 简单易用、无需安装额外依赖（仅依赖常见命令如 `systemctl`、`dpkg`、`grep`）

## 快速开始

下载并运行脚本：

curl
```bash
curl -fsSL 'https://github.com/mcbaiyun/DebainNetworkComponentChecker/raw/refs/heads/main/dncc.sh' | sh
```
wget
```bash
wget -qO- 'https://github.com/mcbaiyun/DebainNetworkComponentChecker/raw/refs/heads/main/dncc.sh' | sh
```

## 输出示例

```
=== Debian 网络管理器检测工具 ===

正在检测系统中常见的网络管理组件...

● systemd-networkd: active
○ NetworkManager: inactive
○ connman: inactive
○ wickedd: inactive

检测完成。

✔ 当前检测到的网络管理器：systemd-networkd

【systemd-networkd 配置文件】
  - /etc/systemd/network/*.network
  - /etc/systemd/network/*.netdev
  - /etc/systemd/network/*.link

【修改方式】
  编辑对应的 .network 文件后执行：
    sudo systemctl restart systemd-networkd

=====================================
```

## 注意事项

- 在容器或没有 systemd 的环境中，`systemctl` 可能不可用；此时脚本会把相应服务标记为 inactive。