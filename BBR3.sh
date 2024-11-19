#!/bin/sh

# 调整系统内核参数以优化网络性能
# 使用sed命令替换已有配置或添加新配置
sysctl_config_file="/etc/sysctl.conf"

# 减少TCP连接的延迟
sed -i '/^net\.ipv4\.tcp_fin_timeout/d' $sysctl_config_file
sed -i '/^net\.ipv4\.tcp_tw_reuse/d' $sysctl_config_file
sed -i '/^net\.ipv4\.tcp_tw_recycle/d' $sysctl_config_file
echo "net.ipv4.tcp_fin_timeout = 15" >> $sysctl_config_file
echo "net.ipv4.tcp_tw_reuse = 1" >> $sysctl_config_file
echo "net.ipv4.tcp_tw_recycle = 1" >> $sysctl_config_file

# 增加TCP缓冲区大小
sed -i '/^net\.ipv4\.tcp_rmem/d' $sysctl_config_file
sed -i '/^net\.ipv4\.tcp_wmem/d' $sysctl_config_file
echo "net.ipv4.tcp_rmem = 4096 87380 16777216" >> $sysctl_config_file
echo "net.ipv4.tcp_wmem = 4096 65536 16777216" >> $sysctl_config_file

# 启用窗口扩大系数
sed -i '/^net\.ipv4\.tcp_window_scaling/d' $sysctl_config_file
echo "net.ipv4.tcp_window_scaling = 1" >> $sysctl_config_file

# TCP拥塞控制算法 (BBR)
sed -i '/^net\.core\.default_qdisc/d' $sysctl_config_file
sed -i '/^net\.ipv4\.tcp_congestion_control/d' $sysctl_config_file
echo "net.core.default_qdisc = fq" >> $sysctl_config_file
echo "net.ipv4.tcp_congestion_control = bbr" >> $sysctl_config_file

# 调整最大接收和发送缓冲区大小
sed -i '/^net\.core\.rmem_max/d' $sysctl_config_file
sed -i '/^net\.core\.wmem_max/d' $sysctl_config_file
echo "net.core.rmem_max = 16777216" >> $sysctl_config_file
echo "net.core.wmem_max = 16777216" >> $sysctl_config_file

# 启用 TCP Fast Open
echo "启用 TCP Fast Open..."
echo "net.ipv4.tcp_fastopen=3" >> /etc/sysctl.conf


# 检查是否有IPv6地址
if ip -6 addr show | grep -q 'inet6'; then
  # 启用IPv6转发
  sed -i '/^net\.ipv6\.conf\.all\.forwarding/d' $sysctl_config_file
  echo "net.ipv6.conf.all.forwarding = 1" >> $sysctl_config_file

  # 增加IPv6 TCP缓冲区大小
  sed -i '/^net\.ipv6\.tcp_rmem/d' $sysctl_config_file
  sed -i '/^net\.ipv6\.tcp_wmem/d' $sysctl_config_file
  echo "net.ipv6.tcp_rmem = 4096 87380 16777216" >> $sysctl_config_file
  echo "net.ipv6.tcp_wmem = 4096 65536 16777216" >> $sysctl_config_file

  # 启用IPv6窗口扩大系数
  sed -i '/^net\.ipv6\.tcp_window_scaling/d' $sysctl_config_file
  echo "net.ipv6.tcp_window_scaling = 1" >> $sysctl_config_file
fi

# 使配置生效
sysctl -p

# 显示所有修改后的内核参数结果
echo "修改后的系统内核参数："
sysctl net.ipv4.tcp_fin_timeout
sysctl net.ipv4.tcp_tw_reuse
sysctl net.ipv4.tcp_tw_recycle
sysctl net.ipv4.tcp_rmem
sysctl net.ipv4.tcp_wmem
sysctl net.ipv4.tcp_window_scaling
sysctl net.core.default_qdisc
sysctl net.ipv4.tcp_congestion_control
sysctl net.core.rmem_max
sysctl net.core.wmem_max

if ip -6 addr show | grep -q 'inet6'; then
  sysctl net.ipv6.conf.all.forwarding
  sysctl net.ipv6.tcp_rmem
  sysctl net.ipv6.tcp_wmem
  sysctl net.ipv6.tcp_window_scaling
fi

# 调整网络接口的MTU值 (假设 eth0 是目标接口)
MTU_VALUE=$(ping -c 4 -M do -s 1472 specificwebsite.com | grep -oP '(?<=bytes from).*' | awk '{print $4}' | cut -d'=' -f2)
if [ -n "$MTU_VALUE" ]; then
  ifconfig eth0 mtu $MTU_VALUE
  echo "MTU 值已设置为 $MTU_VALUE"
else
  MTU_VALUE=1500
  ifconfig eth0 mtu $MTU_VALUE
  echo "无法确定最佳 MTU 值，使用默认值 $MTU_VALUE"
fi

# 确认BBR是否已启用
AVAILABLE_CONGESTION_CONTROL=$(sysctl net.ipv4.tcp_available_congestion_control)
CURRENT_CONGESTION_CONTROL=$(sysctl net.ipv4.tcp_congestion_control)

echo "可用的拥塞控制算法: $AVAILABLE_CONGESTION_CONTROL"
echo "当前拥塞控制算法: $CURRENT_CONGESTION_CONTROL"

# 优化网络卡设置和防火墙规则（需要手动根据VPS具体情况配置）
echo "请确保使用Virtio或其他高效虚拟网络适配器，并简化防火墙规则以减少延迟。"

# 提示进一步优化的建议
echo "建议进一步使用CDN或中继节点以减少延迟。"

echo "网络优化脚本执行完毕。"
