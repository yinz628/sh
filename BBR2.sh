#!/bin/bash

# 检查是否为 root 用户
if [ "$(id -u)" -ne 0 ]; then
    echo "请以 root 用户权限运行此脚本！"
    exit 1
fi

# 优化配置
SYSCTL_CONF="/etc/sysctl.d/99-optimized.conf"

echo "创建优化配置文件: $SYSCTL_CONF"

cat > $SYSCTL_CONF <<EOF
# TCP 和网络相关优化
net.ipv4.tcp_congestion_control = bbr
net.core.default_qdisc = fq
net.core.rmem_max = 67108864
net.core.wmem_max = 67108864
net.core.rmem_default = 67108864
net.core.wmem_default = 67108864
net.core.optmem_max = 65536
net.core.somaxconn = 1000000
net.core.netdev_max_backlog = 100000
net.core.netdev_budget = 50000
net.core.netdev_budget_usecs = 5000
net.ipv4.tcp_rmem = 4096 87380 67108864
net.ipv4.tcp_wmem = 4096 65536 67108864
net.ipv4.tcp_retries2 = 5
net.ipv4.tcp_keepalive_time = 600
net.ipv4.tcp_keepalive_intvl = 15
net.ipv4.tcp_keepalive_probes = 2
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_fin_timeout = 15
net.ipv4.tcp_tw_reuse = 0
net.ipv4.tcp_max_tw_buckets = 5000
net.ipv4.tcp_syn_retries = 1
net.ipv4.tcp_synack_retries = 1
net.ipv4.tcp_max_syn_backlog = 819200
net.ipv4.tcp_timestamps = 1
net.ipv4.tcp_no_metrics_save = 0
net.ipv4.tcp_mtu_probing = 1
net.ipv4.tcp_autocorking = 0
net.ipv4.tcp_slow_start_after_idle = 0
net.ipv4.tcp_notsent_lowat = 16384
net.ipv4.tcp_ecn = 1
net.ipv4.tcp_ecn_fallback = 1
net.ipv4.ip_local_port_range = 1024 65535

# ICMP 配置
net.ipv4.icmp_echo_ignore_all = 0
net.ipv4.icmp_echo_ignore_broadcasts = 1
net.ipv4.icmp_ignore_bogus_error_responses = 1

# ARP 和路由优化
net.ipv4.neigh.default.gc_thresh3 = 8192
net.ipv4.neigh.default.gc_thresh2 = 4096
net.ipv4.neigh.default.gc_thresh1 = 2048
net.ipv6.neigh.default.gc_thresh3 = 8192
net.ipv6.neigh.default.gc_thresh2 = 4096
net.ipv6.neigh.default.gc_thresh1 = 2048
net.ipv4.route.gc_timeout = 100

# 禁用不必要的功能
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv4.conf.all.secure_redirects = 0
net.ipv4.conf.default.secure_redirects = 0
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.send_redirects = 0
net.ipv4.conf.default.rp_filter = 0
net.ipv4.conf.all.rp_filter = 0

# IPv6 配置
net.ipv6.conf.all.disable_ipv6 = 0
net.ipv6.conf.default.disable_ipv6 = 0
net.ipv6.conf.lo.disable_ipv6 = 0
net.ipv6.conf.all.accept_ra = 2
net.ipv6.conf.default.accept_ra = 2
net.ipv6.conf.all.forwarding = 1
net.ipv6.conf.default.forwarding = 1
net.ipv6.conf.lo.forwarding = 1

# 文件句柄限制
fs.file-max = 1000000
fs.inotify.max_user_instances = 8192

# 内存相关优化
vm.swappiness = 1
vm.overcommit_memory = 1

# 进程限制
kernel.pid_max = 4194304

# 链接保护
fs.protected_fifos = 1
fs.protected_hardlinks = 1
fs.protected_regular = 2
fs.protected_symlinks = 1
EOF

echo "优化配置已写入 $SYSCTL_CONF"

# 应用优化配置
echo "应用优化配置..."
sysctl -p $SYSCTL_CONF

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
echo "检查 BBR 是否成功启用..."
BBR_STATUS=$(sysctl net.ipv4.tcp_congestion_control | awk '{print $3}')
if [ "$BBR_STATUS" = "bbr" ]; then
    echo "BBR 已成功启用！"
else
    echo "BBR 启用失败，请检查配置！"
fi

echo "网络优化完成！请重启网络或服务器以确保设置生效。"
