#!/bin/bash

# 颜色设置
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}       Nexus Node 纯净版安装脚本${NC}"
echo -e "${BLUE}========================================${NC}"

# 1. 安装 CLI
echo -e "\n${BLUE}📥 正在安装/更新 Nexus CLI...${NC}"
curl -s https://cli.nexus.xyz/ | sh

# 2. 刷新环境
if [ -f "$HOME/.cargo/env" ]; then
    source "$HOME/.cargo/env"
fi

# 3. 交互式配置 (如果需要)
echo -e "\n${BLUE}⚙️  检查配置...${NC}"
if [ ! -f "$HOME/.nexus/node-id" ]; then
    echo -e "${BLUE}这是您的第一次安装。正在初始化首选项 (可能需要输入 'y')...${NC}"
    # 尝试运行 preference 来触发 setup，或者直接 start
    # Nexus CLI 的行为可能会变，通常 start 会自动生成 ID
fi

# 4. 创建桌面快捷方式
echo -e "\n${BLUE}📝 正在生成桌面启动图标...${NC}"
SHORTCUT_FILE="$HOME/Desktop/My_Nexus.command"

cat > "$SHORTCUT_FILE" <<'EOF'
#!/bin/bash
echo "🚀 启动 Nexus 节点..."
echo "正在在新窗口中运行..."

# 类似原版的启动逻辑
osascript -e 'tell app "Terminal" to do script "cd ~ && nexus-network start --env beta || nexus-cli start --env beta"'

echo "✅ 启动命令已发送"
EOF

chmod +x "$SHORTCUT_FILE"
echo -e "${GREEN}快捷方式已创建: $SHORTCUT_FILE${NC}"
echo -e "${GREEN}✅ 安装完成！${NC}"
