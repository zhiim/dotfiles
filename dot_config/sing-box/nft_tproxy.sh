#!/bin/bash

# ==========================================
# 配置区域
# ==========================================
PROXY_MODE="singbox"
TPROXY_PORT="9898"
FWMARK="1"
ENABLE_IPV6="true"
TABLE_V4="100"
TABLE_V6="101"
PROXY_VIRT="true"  # 是否带离 libvirt 流量

if [ "$PROXY_MODE" = "singbox" ]; then
    PROXY_USER="singbox"
    SERVICE_NAME="sing-box"
elif [ "$PROXY_MODE" = "mihomo" ]; then
    PROXY_USER="mihomo"
    SERVICE_NAME="mihomo"
    DNS_PORT="1053"
else
    echo "无效的 PROXY_MODE 设置: $PROXY_MODE"
    echo "请将 PROXY_MODE 设置为 'singbox' 或 'mihomo'"
    exit 1
fi

# 检查权限
if [ "$EUID" -ne 0 ]; then
  echo "请使用 root 权限运行此脚本 (例如: sudo $0 start)"
  exit 1
fi

# ==========================================
# 生成 nftables 规则的函数
# ==========================================
apply_nft_rules_v4() {
    local nft_config="
table ip proxy_tproxy {
    set reserved_v4 {
        type ipv4_addr
        flags interval
        elements = { 10.0.0.0/8, 127.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16, 224.0.0.0/4, 255.255.255.255/32 }
    }
    set nat_v4 {
        type ipv4_addr
        flags interval
        elements = { 10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16 }
    }

    # PREROUTING 链：处理局域网设备转发到本机的流量
    chain prerouting {
        type filter hook prerouting priority mangle; policy accept;

        # 1. DIVERT：处理已建立连接的包，优化性能
        meta l4proto tcp socket transparent 1 meta mark set $FWMARK accept

        # 2. 绕过 tailscale 和 libvirt
        iifname \"tailscale0\" return
        ip daddr 100.64.0.0/10 return

        $( [ "$PROXY_VIRT" = "false" ] && echo "iifname \"virbr0\" return" )

        # 3. 绕过本机所有公网/局域网 IP
        fib daddr type local return

        # 4. Sing-box DNS 劫持逻辑 (劫持发往局域网 IP 的 DNS 请求)
        $( if [ "$PROXY_MODE" = "singbox" ]; then
            echo "ip daddr @nat_v4 meta l4proto { tcp, udp } th dport 53 meta mark set $FWMARK tproxy to :$TPROXY_PORT"
        fi )

        # 5. 绕过发往保留地址的普通流量
        ip daddr @reserved_v4 return

        # 6. TPROXY 接管剩余所有公网流量
        meta l4proto { tcp, udp } meta mark set $FWMARK tproxy to :$TPROXY_PORT
    }

    # OUTPUT 链：处理本机发出的流量
    chain output {
        type route hook output priority mangle; policy accept;

        # 1. 防止代理进程自身流量死循环
        skuid \"$PROXY_USER\" return

        # 2. 绕过 tailscale 发出的流量
        meta mark 0x40000 return
        ip daddr 100.64.0.0/10 return

        # 3. 绕过本机 IP
        fib daddr type local return

        # 4. Sing-box DNS 本机劫持逻辑
        $( if [ "$PROXY_MODE" = "singbox" ]; then
            echo "ip daddr @nat_v4 meta l4proto { tcp, udp } th dport 53 meta mark set $FWMARK"
        fi )

        # 5. 绕过保留地址
        ip daddr @reserved_v4 return

        # 6. 为本机发出的公网流量打标签以交由策略路由处理
        meta l4proto { tcp, udp } meta mark set $FWMARK
    }
}"

    # 若使用 Mihomo，额外追加 NAT 表用于 DNS 重定向
    if [ "$PROXY_MODE" = "mihomo" ]; then
        nft_config="$nft_config
table ip proxy_mihomo_dns {
    # 局域网发往本机的 DNS 请求
    chain prerouting {
        type nat hook prerouting priority -155; policy accept;
        iifname \"tailscale0\" return
        ip daddr 100.64.0.0/10 return
        $( [ "$PROXY_VIRT" = "false" ] && echo "iifname \"virbr0\" return" )
        meta l4proto { tcp, udp } th dport 53 redirect to :$DNS_PORT
    }
    # 本机发出的 DNS 请求
    chain output {
        type nat hook output priority -155; policy accept;
        meta mark 0x40000 return
        ip daddr 100.64.0.0/10 return
        skuid \"$PROXY_USER\" return
        meta l4proto { tcp, udp } th dport 53 redirect to :$DNS_PORT
    }
}"
    fi

    # 应用规则
    echo "$nft_config" | nft -f -
}

apply_nft_rules_v6() {
    local nft_config="
table ip6 proxy_tproxy {
    set reserved_v6 {
        type ipv6_addr
        flags interval
        elements = { ::1/128, fc00::/7, fe80::/10, ff00::/8 }
    }
    set nat_v6 {
        type ipv6_addr
        flags interval
        elements = { fc00::/7, fe80::/10 }
    }

    chain prerouting {
        type filter hook prerouting priority mangle; policy accept;

        meta l4proto tcp socket transparent 1 meta mark set $FWMARK accept

        iifname \"tailscale0\" return
        ip6 daddr fd7a:115c:a1e0::/48 return

        $( [ "$PROXY_VIRT" = "false" ] && echo "iifname \"virbr0\" return" )

        fib daddr type local return

        $( if [ "$PROXY_MODE" = "singbox" ]; then
            echo "ip6 daddr @nat_v6 meta l4proto { tcp, udp } th dport 53 meta mark set $FWMARK tproxy to :$TPROXY_PORT"
        fi )

        ip6 daddr @reserved_v6 return

        meta l4proto { tcp, udp } meta mark set $FWMARK tproxy to :$TPROXY_PORT
    }

    chain output {
        type route hook output priority mangle; policy accept;

        skuid \"$PROXY_USER\" return

        meta mark 0x40000 return
        ip6 daddr fd7a:115c:a1e0::/48 return

        fib daddr type local return

        $( if [ "$PROXY_MODE" = "singbox" ]; then
            echo "ip6 daddr @nat_v6 meta l4proto { tcp, udp } th dport 53 meta mark set $FWMARK"
        fi )

        ip6 daddr @reserved_v6 return

        meta l4proto { tcp, udp } meta mark set $FWMARK
    }
}"

    if [ "$PROXY_MODE" = "mihomo" ]; then
        nft_config="$nft_config
table ip6 proxy_mihomo_dns {
    chain prerouting {
        type nat hook prerouting priority -155; policy accept;
        iifname \"tailscale0\" return
        ip6 daddr fd7a:115c:a1e0::/48 return
        $( [ "$PROXY_VIRT" = "false" ] && echo "iifname \"virbr0\" return" )
        meta l4proto { tcp, udp } th dport 53 redirect to :$DNS_PORT
    }
    chain output {
        type nat hook output priority -155; policy accept;
        meta mark 0x40000 return
        ip6 daddr fd7a:115c:a1e0::/48 return
        skuid \"$PROXY_USER\" return
        meta l4proto { tcp, udp } th dport 53 redirect to :$DNS_PORT
    }
}"
    fi

    echo "$nft_config" | nft -f -
}

# ==========================================
# 启停逻辑
# ==========================================
start() {
    echo "▶ 清理旧状态..."
    stop >/dev/null 2>&1

    sleep 1

    echo "▶ 启动 ${SERVICE_NAME} 服务..."
    systemctl start $SERVICE_NAME

    echo "▶ 正在加载 nftables 规则..."
    sysctl -w net.ipv4.ip_forward=1 >/dev/null

    ip rule add fwmark $FWMARK table $TABLE_V4 2>/dev/null || true
    ip route add local 0.0.0.0/0 dev lo table $TABLE_V4 2>/dev/null || true

    # 应用 nftables 规则
    apply_nft_rules_v4

    if [ "$ENABLE_IPV6" = "true" ]; then
        echo "▶ 启用 IPv6 规则..."
        sysctl -w net.ipv6.conf.all.forwarding=1 >/dev/null

        ip -6 rule add fwmark $FWMARK table $TABLE_V6 2>/dev/null || true
        ip -6 route add local ::/0 dev lo table $TABLE_V6 2>/dev/null || true

        apply_nft_rules_v6
    fi

    echo "▶ nftables TPROXY 规则应用成功！"
}

stop() {
    echo "▶ 清除内核路由规则..."
    ip rule del fwmark $FWMARK table $TABLE_V4 2>/dev/null || true
    ip route del local 0.0.0.0/0 dev lo table $TABLE_V4 2>/dev/null || true

    if [ "$ENABLE_IPV6" = "true" ]; then
        ip -6 rule del fwmark $FWMARK table $TABLE_V6 2>/dev/null || true
        ip -6 route del local ::/0 dev lo table $TABLE_V6 2>/dev/null || true
    fi

    echo "▶ 卸载 nftables 代理表..."
    nft delete table ip proxy_tproxy 2>/dev/null || true
    nft delete table ip proxy_mihomo_dns 2>/dev/null || true

    if [ "$ENABLE_IPV6" = "true" ]; then
        nft delete table ip6 proxy_tproxy 2>/dev/null || true
        nft delete table ip6 proxy_mihomo_dns 2>/dev/null || true
    fi

    echo "▶ 关闭 ${SERVICE_NAME} 服务..."
    systemctl stop $SERVICE_NAME

    echo "▶ 清理连接状态..."
    conntrack -F 2>/dev/null || true

    echo "▶ 代理环境清理完毕！"
}

case "$1" in
    start)
        start
        ;;
    stop)
        stop
        ;;
    *)
        echo "用法: $0 {start|stop}"
        exit 1
        ;;
esac

exit 0
