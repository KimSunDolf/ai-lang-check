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

# 获取当前 commit 的 ID（前 5 位）
commit_id=$(git log -1 --oneline | awk '{print $1}' | cut -c1-5)

# 获取 Git 仓库的根目录路径
repo_root=$(git rev-parse --show-toplevel)

# 获取当前的月日时间
current_date=$(date +"%m%d")

# 获取脚本文件的目录路径
script_dir=$(dirname "$(realpath "$0")")

# 设置文件路径，文件名为 commit ID 加上当前月日时间和 .txt 后缀，并保存在脚本文件的同一路径内
log_file="${script_dir}/commit-${commit_id}-${current_date}.txt"

# 创建或清空日志文件
echo "" > "$log_file"

# 获取变动文件列表，过滤掉非文件信息，确保比较当前分支与目标分支之间的差异
changed_files=$(git diff --name-only origin/main...HEAD)

# 遍历每个变动文件
for file in $changed_files
do
    # 检查文件是否存在并且是否为 .md 文件
    if [ -f "$repo_root/$file" ] && [[ "$file" == *.md ]]; then
        # 输出开始标签
        echo "<start---lang-check/$file---start>" >> "$log_file"
        
        # 输出文件内容
        cat "$repo_root/$file" >> "$log_file"
        
        # 输出结束标签
        echo -e "\n\n<end---/$file---end>\n" >> "$log_file"
        
    fi
done

if [ "$debug_mode" = true ]; then
    echo "Output saved to $log_file"
fi

# 设置 API 密钥和其他常量
api_key="app-jlPYjfHIRLXbSoy9gw3ZOyXw"
user=$(git config user.name)  # 获取 Git 配置中的用户名

# 如果获取失败，使用默认值
if [ -z "$user" ]; then
    user="abc-123"  # 默认用户名
    if [ "$debug_mode" = true ]; then
        echo "警告：无法获取 Git 用户名，使用默认值"
    fi
fi

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
