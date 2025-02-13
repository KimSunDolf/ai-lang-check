#!/bin/bash

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

# 输出日志文件路径
echo "Output saved to $log_file"
