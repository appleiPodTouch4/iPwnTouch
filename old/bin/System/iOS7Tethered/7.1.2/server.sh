#!/bin/bash
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# 如果不是root用户，则自动使用sudo重新运行脚本
if [ "$(id -u)" -ne 0 ]; then
    echo 输入本机密码
    exec sudo "$0" "$@"
fi

# 检查80端口占用
echo "🔍 检测80端口占用情况..."
PID=$(lsof -t -i :80)

if [ -z "$PID" ]; then
    echo "✅ 80端口未被占用"
    cd "$script_dir/Keys Server"
    python -m SimpleHTTPServer 80;
    read -p ok
else
    echo "⚠️ 发现占用80端口的进程(PID): $PID"
    echo "📌 进程详细信息:"
    lsof -i :80 | awk 'NR==1 || /LISTEN/'
    
    echo "🛑 正在强制终止进程 $PID ..."
    kill -9 $PID 2>/dev/null
    
    # 验证是否成功释放
    if [ -z "$(lsof -t -i :80)" ]; then
        echo "✅ 80端口已成功释放"
        cd "$script_dir/Keys Server"
        python -m SimpleHTTPServer 80;
        read -p ok
    else
        echo "❌ 释放失败，请手动检查"
        exit 1
    fi
fi
