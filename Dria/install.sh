#!/bin/bash

# 颜色设置
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}       Dria Node 纯净版安装脚本${NC}"
echo -e "${BLUE}========================================${NC}"

# 1. 安装 Ollama (前置依赖)
echo -e "\n${BLUE}🔍 检查 Ollama...${NC}"
if [ ! -d "/Applications/Ollama.app" ]; then
    echo "📥 请先安装 Ollama (https://ollama.com)"
    echo "脚本将尝试为您打开下载页面..."
    open https://ollama.com
    # 也可以选择自动下载，但保持简单让用户手动装更稳
else
    echo -e "${GREEN}✅ Ollama 已安装${NC}"
    if ! pgrep -x "Ollama" >/dev/null; then
        echo "🚀 启动 Ollama..."
        open -a Ollama
    fi
fi

# 2. 安装 Dria
echo -e "\n${BLUE}📥 安装 Dria Launcher...${NC}"
# 官方安装命令
curl -fsSL https://dria.co/launcher | bash

# 3. 创建桌面快捷方式
echo -e "\n${BLUE}📝 正在生成桌面启动图标...${NC}"
SHORTCUT_FILE="$HOME/Desktop/My_Dria.command"

cat > "$SHORTCUT_FILE" <<'EOF'
#!/bin/bash
echo "🚀 启动 Dria..."
dkn-compute-launcher start
EOF

chmod +x "$SHORTCUT_FILE"
echo -e "${GREEN}快捷方式已创建: $SHORTCUT_FILE${NC}"
echo -e "${GREEN}✅ 安装完成！${NC}"
