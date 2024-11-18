#!/bin/sh

# 检查是否为root用户
if [ "$(id -u)" -ne 0 ]; then
    echo "请以 root 用户权限运行此脚本！"
    exit 1
fi

echo "开始优化网络设置..."

# 启用 BBR
echo "启用 BBR..."
echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf
echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf

# 调整 TCP 缓冲区大小
echo "调整 TCP 缓冲区大小..."
echo "net.core.rmem_max=16777216" >> /etc/sysctl.conf
echo "net.core.wmem_max=16777216" >> /etc/sysctl.conf
echo "net.ipv4.tcp_rmem=4096 87380 16777216" >> /etc/sysctl.conf
echo "net.ipv4.tcp_wmem=4096 65536 16777216" >> /etc/sysctl.conf

# 启用 TCP Fast Open
echo "启用 TCP Fast Open..."
echo "net.ipv4.tcp_fastopen=3" >> /etc/sysctl.conf

# 应用 sysctl 配置
echo "应用 sysctl 配置..."
sysctl -p

# 调整网络接口 MTU
echo "调整网络接口 MTU..."
DEFAULT_IFACE=$(ip route | grep default | awk '{print $5}' | head -n 1)
if [ -n "$DEFAULT_IFACE" ]; then
    echo "检测到默认网络接口: $DEFAULT_IFACE"
    ifconfig "$DEFAULT_IFACE" mtu 1400
    echo "MTU 已调整为 1400"
else
    echo "未能检测到默认网络接口，请手动设置 MTU！"
fi

# 检查 BBR 是否成功启用
BBR_STATUS=$(sysctl net.ipv4.tcp_congestion_control | awk '{print $3}')
if [ "$BBR_STATUS" = "bbr" ]; then
    echo "BBR 已成功启用！"
else
    echo "BBR 启用失败，请检查配置！"
fi

echo "网络优化完成！请重启网络或服务器以确保设置生效。"
