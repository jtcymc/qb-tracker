#!/bin/bash

# 用法提示
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <file>"
    exit 1
fi

input_file="$1"
output_file="$2"

# 检查文件是否存在且非空
if [ ! -s "$input_file" ]; then
    echo "Error: File not found or is empty."
    exit 1
fi

# 清空输出文件
: >"$output_file"

# 读取文件并处理每个 Tracker
while IFS= read -r tracker; do
    # 去除前后空格并跳过空行或注释
    tracker=$(echo "$tracker" | xargs)
    [ -z "$tracker" ] && continue
    [[ "$tracker" =~ ^# ]] && continue

    # 提取协议
    protocol=$(echo "$tracker" | cut -d: -f1)

    case "$protocol" in
    http | https)
        if curl -s -f --max-time 2 "$tracker" -o /dev/null; then
            echo "Success: $tracker"
            echo "$tracker" >>"$output_file"
        else
            echo "Failed: $tracker"
        fi
        ;;
    udp)
        hostport=$(echo "$tracker" | cut -d/ -f3)
        host=${hostport%%:*}
        port=${hostport##*:}

        # 如果没有明确端口，则默认使用 80
        if [ "$host" = "$port" ]; then
            port=80
        fi

        if nc -z -u -w1 "$host" "$port" &>/dev/null; then
            echo "Success: $tracker"
            echo "$tracker" >>"$output_file"
        else
            echo "Failed: $tracker"
        fi
        ;;
    wss)
        if command -v wscat >/dev/null 2>&1; then
            if timeout 2 wscat -c "$tracker" &>/dev/null; then
                echo "Success: $tracker"
                echo "$tracker" >>"$output_file"
            else
                echo "Failed: $tracker"
            fi
        else
            echo "wscat not installed, skipping: $tracker"
        fi
        ;;
    *)
        echo "Unknown protocol or invalid tracker: $tracker"
        ;;
    esac
done <"$input_file"

echo "Testing complete. Valid trackers saved to $output_file"
