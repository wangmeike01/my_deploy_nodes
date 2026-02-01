#!/bin/bash

# 设置错误处理
set -e

# 捕获中断信号
trap 'echo -e "\n\033[33m⚠️ 脚本被中断\033[0m"; exit 0' INT TERM

echo "🧹 正在清理 Spotlight 索引..."

# macOS 清理 Spotlight 索引
if [[ "$OSTYPE" == "darwin"* ]]; then
  echo "1. 停止 Spotlight 索引服务..."
  sudo mdutil -a -i off
  
  echo "2. 删除旧的索引文件..."
  sudo rm -rf /.Spotlight-V100
  
  echo "3. 重启 Spotlight 索引服务..."
  sudo mdutil -a -i on
  
  echo "✅ Spotlight 索引清理完成！系统将在后台自动重建索引。"
else
  echo "⚠️  此脚本仅适用于 macOS"
fi

echo "按任意键退出..."
read -n 1 -s
