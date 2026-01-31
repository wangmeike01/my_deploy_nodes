#!/bin/bash

# 颜色设置
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}       Tashi Worker 纯净版安装脚本${NC}"
echo -e "${BLUE}========================================${NC}"

# 1. 检查 Docker
if ! command -v docker >/dev/null 2>&1; then
    echo -e "${RED}❌ 未检测到 Docker，请先安装 Docker Desktop。${NC}"
    exit 1
fi

if ! docker info >/dev/null 2>&1; then
    echo -e "${YELLOW}⚠️  Docker 未运行，正在启动...${NC}"
    open -a Docker
    echo "等待 Docker 启动 (20秒)..."
    sleep 20
fi

# 2. 准备容器环境
VOLUME_NAME="tashi-depin-worker-auth"
CONTAINER_NAME="tashi-depin-worker"
IMAGE_TAG="ghcr.io/tashigg/tashi-depin-worker:0"

echo -e "\n${BLUE}🐳 正在拉取 Docker 镜像...${NC}"
docker pull $IMAGE_TAG

echo -e "\n${BLUE}📂 准备数据卷...${NC}"
docker volume create $VOLUME_NAME

# 3. 首次运行引导
echo -e "\n${BLUE}🚀 启动 Tashi 容器...${NC}"
# 停止旧的
docker stop $CONTAINER_NAME >/dev/null 2>&1
docker rm $CONTAINER_NAME >/dev/null 2>&1

# 启动 (使用 host 网络或端口映射，这里参考原版映射)
docker run -d \
    --restart unless-stopped \
    --mount type=volume,src=$VOLUME_NAME,dst=/home/worker/auth \
    --name $CONTAINER_NAME \
    -p 39065:39065 \
    -p 127.0.0.1:9000:9000 \
    $IMAGE_TAG run /home/worker/auth

echo -e "\n${GREEN}✅ 容器已启动！${NC}"
echo -e "${YELLOW}👉 [重要] 请按照以下步骤绑定设备：${NC}"
echo "1. 脚本将显示最新的 20 行日志。"
echo "2. 在日志中找到 'Device ID'。"
echo "3. 访问 Tashi 官网控制台进行设备绑定 (Bonding)。"
echo ""
echo "正在获取日志..."
sleep 3
docker logs --tail 20 $CONTAINER_NAME

# 4. 创建桌面快捷方式
echo -e "\n${BLUE}📝 正在生成桌面启动图标...${NC}"
SHORTCUT_FILE="$HOME/Desktop/My_Tashi.command"

cat > "$SHORTCUT_FILE" <<EOF
#!/bin/bash
echo "🚀 启动 Tashi Worker..."
docker start $CONTAINER_NAME || docker run -d --restart unless-stopped --mount type=volume,src=$VOLUME_NAME,dst=/home/worker/auth --name $CONTAINER_NAME -p 39065:39065 -p 127.0.0.1:9000:9000 $IMAGE_TAG run /home/worker/auth
echo "✅ Tashi 已在后台运行"
echo "查看日志请运行: docker logs -f $CONTAINER_NAME"
echo ""
echo "Press any key to close..."
read -n 1 -s
EOF

chmod +x "$SHORTCUT_FILE"
echo -e "${GREEN}快捷方式已创建: $SHORTCUT_FILE${NC}"
