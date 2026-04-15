#!/bin/bash

# ==========================================
# 配置区域
# ==========================================
PROXY_USER="singbox_tproxy"
PROXY_PORT="9898"
FWMARK="1"
TABLE_V4="100"
TABLE_V6="101"

# 检查是否以 root 权限运行
if [ "$EUID" -ne 0 ]; then
  echo "请使用 root 权限运行此脚本 (例如: sudo $0 start)"
  exit 1
fi

start() {
    echo "▶ 清理旧连接状态..."
    conntrack -F 2>/dev/null || true

    echo "▶ 正在配置 IPv4 规则..."

    sysctl -w net.ipv4.ip_forward=1 >/dev/null
    sysctl -w net.ipv6.conf.all.forwarding=1 >/dev/null

    # 1. IPv4 路由策略
    ip rule add fwmark $FWMARK table $TABLE_V4 2>/dev/null || true
    ip route add local 0.0.0.0/0 dev lo table $TABLE_V4 2>/dev/null || true

    # 2. IPv4 DIVERT 链 (处理已建立连接的 TCP 包，提高性能)
    iptables -t mangle -N DIVERT
    iptables -t mangle -A DIVERT -j MARK --set-mark $FWMARK
    iptables -t mangle -A DIVERT -j ACCEPT
    iptables -t mangle -I PREROUTING -p tcp -m socket -j DIVERT

    # 3. IPv4 SINGBOX 链 (处理局域网转发到本机的流量)
    iptables -t mangle -N SINGBOX
    iptables -t mangle -A SINGBOX -d 10.0.0.0/8 -p udp --dport 53 -j TPROXY --on-ip 127.0.0.1 --on-port $PROXY_PORT --tproxy-mark $FWMARK
    iptables -t mangle -A SINGBOX -d 172.16.0.0/12 -p udp --dport 53 -j TPROXY --on-ip 127.0.0.1 --on-port $PROXY_PORT --tproxy-mark $FWMARK
    iptables -t mangle -A SINGBOX -d 192.168.0.0/16 -p udp --dport 53 -j TPROXY --on-ip 127.0.0.1 --on-port $PROXY_PORT --tproxy-mark $FWMARK
    iptables -t mangle -A SINGBOX -d 10.0.0.0/8 -j RETURN
    iptables -t mangle -A SINGBOX -d 172.16.0.0/12 -j RETURN
    iptables -t mangle -A SINGBOX -d 192.168.0.0/16 -j RETURN
    iptables -t mangle -A SINGBOX -d 127.0.0.0/8 -j RETURN
    iptables -t mangle -A SINGBOX -d 224.0.0.0/4 -j RETURN
    iptables -t mangle -A SINGBOX -d 255.255.255.255/32 -j RETURN 

    # 绕过本机公网 IPv4 地址
    v4address=($(ip -4 addr show | grep inet | grep -v "127.0.0.1" | awk '{print $2}' | cut -d/ -f1))
    for a in "${v4address[@]}"; do
        iptables -t mangle -A SINGBOX -d "$a" -j RETURN
    done

    # 绕过 tailscale
    iptables -t mangle -I SINGBOX 1 -i tailscale0 -j RETURN
    iptables -t mangle -I SINGBOX 2 -d 100.64.0.0/10 -j RETURN

    iptables -t mangle -A SINGBOX -p udp -j TPROXY --on-ip 127.0.0.1 --on-port $PROXY_PORT --tproxy-mark $FWMARK
    iptables -t mangle -A SINGBOX -p tcp -j TPROXY --on-ip 127.0.0.1 --on-port $PROXY_PORT --tproxy-mark $FWMARK
    iptables -t mangle -A PREROUTING -j SINGBOX

    # 4. IPv4 SINGBOX_MASK 链 (处理本机流量)
    iptables -t mangle -N SINGBOX_MASK
    iptables -t mangle -A SINGBOX_MASK -d 10.0.0.0/8 -p udp --dport 53 -j MARK --set-mark $FWMARK
    iptables -t mangle -A SINGBOX_MASK -d 172.16.0.0/12 -p udp --dport 53 -j MARK --set-mark $FWMARK
    iptables -t mangle -A SINGBOX_MASK -d 192.168.0.0/16 -p udp --dport 53 -j MARK --set-mark $FWMARK
    iptables -t mangle -A SINGBOX_MASK -d 10.0.0.0/8 -j RETURN
    iptables -t mangle -A SINGBOX_MASK -d 172.16.0.0/12 -j RETURN
    iptables -t mangle -A SINGBOX_MASK -d 192.168.0.0/16 -j RETURN
    iptables -t mangle -A SINGBOX_MASK -d 127.0.0.0/8 -j RETURN
    iptables -t mangle -A SINGBOX_MASK -d 224.0.0.0/4 -j RETURN
    iptables -t mangle -A SINGBOX_MASK -d 255.255.255.255/32 -j RETURN

    iptables -t mangle -I SINGBOX_MASK 1 -d 100.64.0.0/10 -j RETURN
    iptables -t mangle -I SINGBOX_MASK 2 -m mark --mark 0x40000 -j RETURN

    iptables -t mangle -A SINGBOX_MASK -p tcp -j MARK --set-mark $FWMARK
    iptables -t mangle -A SINGBOX_MASK -p udp -j MARK --set-mark $FWMARK
    iptables -t mangle -A OUTPUT -m owner ! --uid-owner $PROXY_USER -j SINGBOX_MASK


    echo "▶ 正在配置 IPv6 规则..."

    # 1. IPv6 路由策略
    ip -6 rule add fwmark $FWMARK table $TABLE_V6 2>/dev/null || true
    ip -6 route add local ::/0 dev lo table $TABLE_V6 2>/dev/null || true

    # 2. IPv6 DIVERT6 链
    ip6tables -t mangle -N DIVERT6
    ip6tables -t mangle -A DIVERT6 -j MARK --set-mark $FWMARK
    ip6tables -t mangle -A DIVERT6 -j ACCEPT
    ip6tables -t mangle -I PREROUTING -p tcp -m socket -j DIVERT6

    # 3. IPv6 SINGBOX6 链
    ip6tables -t mangle -N SINGBOX6
    ip6tables -t mangle -A SINGBOX6 -d fe80::/10 -p udp --dport 53 -j TPROXY --on-ip ::1 --on-port $PROXY_PORT --tproxy-mark $FWMARK
    ip6tables -t mangle -A SINGBOX6 -d fc00::/7 -p udp --dport 53 -j TPROXY --on-ip ::1 --on-port $PROXY_PORT --tproxy-mark $FWMARK
    ip6tables -t mangle -A SINGBOX6 -d fe80::/10 -j RETURN
    ip6tables -t mangle -A SINGBOX6 -d fc00::/7 -j RETURN
    ip6tables -t mangle -A SINGBOX6 -d ::1/128 -j RETURN
    ip6tables -t mangle -A SINGBOX6 -d ff00::/8 -j RETURN

    # 绕过本机公网 IPv6 地址
    v6address=($(ip -6 addr show | grep inet6 | grep -v "::1" | awk '{print $2}' | cut -d/ -f1))
    for a in "${v6address[@]}"; do
        ip6tables -t mangle -A SINGBOX6 -d "$a" -j RETURN
    done

    # 绕过 tailscale
    ip6tables -t mangle -I SINGBOX6 1 -i tailscale0 -j RETURN
    ip6tables -t mangle -I SINGBOX6 2 -d fd7a:115c:a1e0::/48 -j RETURN

    ip6tables -t mangle -A SINGBOX6 -p udp -j TPROXY --on-ip ::1 --on-port $PROXY_PORT --tproxy-mark $FWMARK
    ip6tables -t mangle -A SINGBOX6 -p tcp -j TPROXY --on-ip ::1 --on-port $PROXY_PORT --tproxy-mark $FWMARK
    ip6tables -t mangle -A PREROUTING -j SINGBOX6

    # 4. IPv6 SINGBOX_MASK6 链
    ip6tables -t mangle -N SINGBOX_MASK6
    ip6tables -t mangle -A SINGBOX_MASK6 -d fe80::/10 -p udp --dport 53 -j MARK --set-mark $FWMARK
    ip6tables -t mangle -A SINGBOX_MASK6 -d fc00::/7 -p udp --dport 53 -j MARK --set-mark $FWMARK
    ip6tables -t mangle -A SINGBOX_MASK6 -d fe80::/10 -j RETURN
    ip6tables -t mangle -A SINGBOX_MASK6 -d fc00::/7 -j RETURN
    ip6tables -t mangle -A SINGBOX_MASK6 -d ::1/128 -j RETURN
    ip6tables -t mangle -A SINGBOX_MASK6 -d ff00::/8 -j RETURN

    ip6tables -t mangle -I SINGBOX_MASK6 1 -d fd7a:115c:a1e0::/48 -j RETURN
    ip6tables -t mangle -I SINGBOX_MASK6 2 -m mark --mark 0x40000 -j RETURN

    ip6tables -t mangle -A SINGBOX_MASK6 -p tcp -j MARK --set-mark $FWMARK
    ip6tables -t mangle -A SINGBOX_MASK6 -p udp -j MARK --set-mark $FWMARK
    ip6tables -t mangle -A OUTPUT -m owner ! --uid-owner $PROXY_USER -j SINGBOX_MASK6

    echo "✅ TPROXY 规则应用成功！"
}

stop() {
    echo "▶ 正在清除 IPv4 规则..."

    # 清理 IPv4 路由
    ip rule del fwmark $FWMARK table $TABLE_V4 2>/dev/null || true
    ip route del local 0.0.0.0/0 dev lo table $TABLE_V4 2>/dev/null || true

    # 清理 IPv4 规则和链 (忽略不存在的错误)
    iptables -t mangle -D PREROUTING -p tcp -m socket -j DIVERT 2>/dev/null || true
    iptables -t mangle -F DIVERT 2>/dev/null || true
    iptables -t mangle -X DIVERT 2>/dev/null || true

    iptables -t mangle -D PREROUTING -j SINGBOX 2>/dev/null || true
    iptables -t mangle -F SINGBOX 2>/dev/null || true
    iptables -t mangle -X SINGBOX 2>/dev/null || true

    iptables -t mangle -D OUTPUT -m owner ! --uid-owner $PROXY_USER -j SINGBOX_MASK 2>/dev/null || true
    iptables -t mangle -F SINGBOX_MASK 2>/dev/null || true
    iptables -t mangle -X SINGBOX_MASK 2>/dev/null || true


    echo "▶ 正在清除 IPv6 规则..."

    # 清理 IPv6 路由
    ip -6 rule del fwmark $FWMARK table $TABLE_V6 2>/dev/null || true
    ip -6 route del local ::/0 dev lo table $TABLE_V6 2>/dev/null || true

    # 清理 IPv6 规则和链
    ip6tables -t mangle -D PREROUTING -p tcp -m socket -j DIVERT6 2>/dev/null || true
    ip6tables -t mangle -F DIVERT6 2>/dev/null || true
    ip6tables -t mangle -X DIVERT6 2>/dev/null || true

    ip6tables -t mangle -D PREROUTING -j SINGBOX6 2>/dev/null || true
    ip6tables -t mangle -F SINGBOX6 2>/dev/null || true
    ip6tables -t mangle -X SINGBOX6 2>/dev/null || true

    ip6tables -t mangle -D OUTPUT -m owner ! --uid-owner $PROXY_USER -j SINGBOX_MASK6 2>/dev/null || true
    ip6tables -t mangle -F SINGBOX_MASK6 2>/dev/null || true
    ip6tables -t mangle -X SINGBOX_MASK6 2>/dev/null || true

    echo "▶ 清理连接状态..."
    conntrack -F 2>/dev/null || true

    echo "✅ TPROXY 规则清理完毕！"
}

case "$1" in
    start)
        start
        ;;
    stop)
        stop
        ;;
    restart)
        stop
        sleep 1
        start
        ;;
    *)
        echo "用法: $0 {start|stop|restart}"
        exit 1
        ;;
esac

exit 0
