#!/bin/bash

if ! command -v notify-send &> /dev/null || ! command -v xdg-open &> /dev/null; then
    echo "缺少依赖: notify-send 或 xdg-open 包未安装。"
    exit 1
fi

LAST_CHECK_TIME=0
COOLDOWN=5
PORTAL_URL="http://connect.rom.miui.com/generate_204"

check_portal() {
    local current_time
    current_time=$(date +%s)

    # 防抖逻辑
    if (( current_time - LAST_CHECK_TIME > COOLDOWN )); then
        LAST_CHECK_TIME=$current_time

        # 使用后台子shell执行，避免阻塞
        (
            sleep 1
            # 强制检查当前网络状态
            STATE=$(nmcli networking connectivity check)
            echo "当前网络状态: $STATE"

            if [ "$STATE" = "portal" ]; then
                echo "WIFI 需要认证..."
                ACTION=$(notify-send \
                    -a "网络管理" \
                    -u critical \
                    -i network-manager \
                    -t 15000 \
                    -w \
                    -A "default=打开认证" \
                    "Wi-Fi 认证" "当前连接需要网页登录。点击此通知打开认证页面。")

                if [ "$ACTION" = "default" ]; then
                    xdg-open "$PORTAL_URL"
                fi
            fi
        ) &
    fi
}

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
