#!/bin/bash

if ! command -v notify-send &> /dev/null || ! command -v xdg-open &> /dev/null; then
    echo "缺少依赖: notify-send 或 xdg-open 包未安装。"
    exit 1
fi

PORTAL_URL="http://connect.rom.miui.com/generate_204"
LOCK_DIR="/tmp/wifi_portal_check.lock"  # 目录锁，确保 wifi 认证通知和点击反馈的原子性

check_portal() {
    # 使用后台子shell执行，避免阻塞
    (
        # 如果无法创建锁目录，直接退出
        if ! mkdir "$LOCK_DIR" 2>/dev/null; then
            exit 0
        fi
        # 确保子shell退出时释放锁
        trap 'rmdir "$LOCK_DIR" 2>/dev/null' EXIT

        # 强制检查当前网络状态
        STATE=$(nmcli networking connectivity check)
        echo "当前网络状态: $STATE"

        if [ "$STATE" = "portal" ]; then
            echo "WIFI 需要认证..."
            ACTION=$(notify-send \
                -a "网络管理" \
                -h int:transient:1 \
                -u critical \
                -i network-manager \
                -t 0 \
                -w \
                -A "default=打开认证" \
                "Wi-Fi 认证" "当前连接需要网页登录。点击此通知打开认证页面。")

            if [ "$ACTION" = "default" ]; then
                systemd-run --user xdg-open "$PORTAL_URL"
            fi
        fi
    ) &
}

rm -rf "$LOCK_DIR"

echo "网络认证监听脚本已启动..."

if [ "$(nmcli networking connectivity)" = "portal" ]; then
    check_portal
fi

# 监听网络事件
nmcli monitor | while read -r line; do
    if [[ "$line" =~ [Cc]onnected|已连接 ]]; then
        echo "检测到连接事件: $line"
        check_portal
    fi
done
