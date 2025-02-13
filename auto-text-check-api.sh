#!/bin/bash

# 初始化调试模式标志
debug_mode=false

# 处理命令行参数
while getopts "t" opt; do
    case $opt in
        t)
            debug_mode=true
            ;;
    esac
done

# 设置 API 密钥和其他常量
api_key="app-jlPYjfHIRLXbSoy9gw3ZOyXw"
user="abc-123"
log_file="lang-check/commit-317ed-0213.txt"

# 检查文件是否存在
if [ ! -f "$log_file" ]; then
    echo "错误：文件 $log_file 不存在"
    exit 1
fi

# 读取 .txt 文件内容
query_content=$(<"$log_file")

# 调试输出
if [ "$debug_mode" = true ]; then
    echo "===== 调试信息 ====="
    echo "文件路径: $log_file"
    echo "文件内容长度: ${#query_content}"
    echo "文件内容预览（前 100 个字符）:"
    echo "${query_content:0:100}"
    echo "=================="
fi

# 准备 JSON 数据
json_data=$(cat <<EOF
{
    "inputs": {"query": $(printf '%s' "$query_content" | jq -R -s .)},
    "response_mode": "blocking",
    "user": "$user"
}
EOF
)

# 调试输出
if [ "$debug_mode" = true ]; then
    echo "===== API 请求数据 ====="
    echo "$json_data"
    echo "===================="
fi

# 通过 curl 发送 POST 请求
if [ "$debug_mode" = true ]; then
    # 带调试信息的请求，设置 30 秒超时
    response=$(curl -X POST 'https://api.dify.ai/v1/completion-messages' \
    --header "Authorization: Bearer $api_key" \
    --header "Content-Type: application/json" \
    --data "$json_data" \
    --max-time 30 \
    -v | jq -r '.answer')
else
    # 不带调试信息的请求，设置 30 秒超时
    response=$(curl -X POST 'https://api.dify.ai/v1/completion-messages' \
    --header "Authorization: Bearer $api_key" \
    --header "Content-Type: application/json" \
    --data "$json_data" \
    --max-time 30 \
    -s | jq -r '.answer')
fi

# 检查 curl 是否成功
if [ $? -ne 0 ]; then
    echo "错误：API 请求超时或失败"
    exit 1
fi

# 只输出 API 响应
echo "$response"
