#!/bin/bash

if ! command -v notify-send &> /dev/null; then
    echo "请先安装 libnotify 包以使用 notify-send。"
    exit 1
fi

if ! command -v xdg-open &> /dev/null; then
    echo "请先安装 xdg-utils 以支持自动打开浏览器。"
    exit 1
fi

LAST_CHECK_TIME=0
COOLDOWN=10 

echo "网络认证监听脚本已启动..."

# 监听网络事件
nmcli monitor | while read -r line; do
    if [[ "$line" =~ [Cc]onnected|已连接 ]]; then

        CURRENT_TIME=$(date +%s)

        # 防抖逻辑：如果距离上次检查不到 COOLDOWN 秒，则忽略
        if (( CURRENT_TIME - LAST_CHECK_TIME > COOLDOWN )); then
            LAST_CHECK_TIME=$CURRENT_TIME

            # 将 sleep 和网络检查放到后台子shell中执行，避免阻塞主循环
            (
                sleep 3

                # 强制检查当前的网络连通性状态
                STATE=$(nmcli networking connectivity check)

                if [ "$STATE" = "portal" ]; then
                    echo "WIFI 需要认证..."

                    PORTAL_URL="http://connect.rom.miui.com/generate_204"

                    ACTION=$(notify-send \
                        -a "网络管理" \
                        -u critical \
                        -i network-wireless \
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
    fi
done
