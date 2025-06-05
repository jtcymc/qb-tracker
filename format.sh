#!/bin/bash

# 检查是否提供了文件名作为参数
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <file>"
    exit 1
fi

input_file="$1"
output_file="formatted_trackers.txt"

# 检查输入文件是否存在且为非空文件
if [ ! -s "$input_file" ]; then
    echo "Error: File not found or is empty."
    exit 1
fi

# 提取并格式化 Tracker 地址
# 1. 替换逗号为换行符
# 2. 使用 grep 匹配符合要求的 Tracker URL
# 3. 用 sed 去除常见默认端口号
# 4. 去重、去空行、排序
tr ',' '\n' <"$input_file" |
    grep -Eo '((http|https|udp|wss)://[^/[:space:]]+/announce)' |
    sed -E '
    s#(http://[^/:]+):80(/announce)#\1\2#;
    s#(https://[^/:]+):443(/announce)#\1\2#
' |
    sed 's/[[:space:]]*$//' |
    awk 'NF' |
    sort -u >"$output_file"

echo "Formatted trackers have been saved to $output_file"
