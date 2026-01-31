#!/bin/bash

# 颜色设置
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}   OptimAI (Optimal) 纯净版安装脚本${NC}"
echo -e "${BLUE}========================================${NC}"

# 1. 检查/安装 OptimAI CLI
echo -e "\n${YELLOW}🔍 正在检查 OptimAI CLI...${NC}"
if ! command -v optimai-cli >/dev/null 2>&1; then
    echo -e "${YELLOW}📥 未检测到 CLI，正在下载官方版本...${NC}"
    # 使用官方下载链接
    curl -L -f https://optimai.network/download/cli-node/mac -o /tmp/optimai-cli
    
    if [ $? -eq 0 ]; then
        chmod +x /tmp/optimai-cli
        echo -e "${GREEN}📦 正在安装到 /usr/local/bin/ ...${NC}"
        # 需要 sudo 权限移动到系统目录
        sudo mv /tmp/optimai-cli /usr/local/bin/optimai-cli
        echo -e "${GREEN}✅ OptimAI CLI 安装成功！${NC}"
    else
        echo -e "${RED}❌ 下载失败，请检查网络连接。${NC}"
        exit 1
    fi
else
    echo -e "${GREEN}✅ OptimAI CLI 已安装。${NC}"
fi

# 2. 交互式登录 (这是区别于服务商脚本的关键)
echo -e "\n${BLUE}🔐 [关键步骤] 身份认证${NC}"
echo -e "${YELLOW}请在下方根据提示输入您的注册邮箱进行登录：${NC}"
echo -e "(如果已登录过，虽然会报错但无影响)${NC}"
echo ""

# 调用官方登录命令
optimai-cli auth login

# 3. 创建桌面启动快捷方式
echo -e "\n${BLUE}📝 正在生成桌面启动图标...${NC}"
SHORTCUT_FILE="$HOME/Desktop/My_Optimal.command"

cat > "$SHORTCUT_FILE" <<'EOF'
#!/bin/bash
echo "🚀 启动 OptimAI 节点..."
# 检查 Docker
if ! docker info >/dev/null 2>&1; then
    echo "⚠️  Docker 未运行，尝试启动..."
    open -a Docker
    sleep 10
fi

# 停止旧的
optimai-cli node stop >/dev/null 2>&1

# 启动新的
echo "✅ 正在启动..."
optimai-cli node start

echo ""
echo "Press any key to close..."
read -n 1 -s
EOF

chmod +x "$SHORTCUT_FILE"

echo -e "\n${GREEN}🎉 安装完成！${NC}"
echo -e "您可以通过桌面的 ${GREEN}My_Optimal.command${NC} 来启动节点。"
