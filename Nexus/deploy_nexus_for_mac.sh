#!/bin/bash
# 来源: readyName/deploy_nodes/Nexus/deploy_nexus_for_mac.sh
# 这里的代码完全照搬原仓库逻辑，保留了详细的 create_desktop_shortcuts 函数，但只启用 self-contained 分支

# 柔和色彩设置
GREEN='\033[1;32m'      # 柔和绿色
BLUE='\033[1;36m'       # 柔和蓝色
RED='\033[1;31m'        # 柔和红色
YELLOW='\033[1;33m'     # 柔和黄色
NC='\033[0m'            # 无颜色

# 日志文件设置
LOG_FILE="$HOME/nexus.log"
MAX_LOG_SIZE=10485760 # 10MB，日志大小限制

# 检测操作系统
OS=$(uname -s)
case "$OS" in
  Darwin) OS_TYPE="macOS" ;;
  Linux)
    if [[ -f /etc/os-release ]]; then
      . /etc/os-release
      if [[ "$ID" == "ubuntu" ]]; then
        OS_TYPE="Ubuntu"
      else
        OS_TYPE="Linux"
      fi
    else
      OS_TYPE="Linux"
    fi
    ;;
  *) echo -e "${RED}不支持的操作系统: $OS。本脚本仅支持 macOS 和 Ubuntu。${NC}" ; exit 1 ;;
esac

# 检测 shell 并设置配置文件
if [[ -n "$ZSH_VERSION" ]]; then
  SHELL_TYPE="zsh"
  CONFIG_FILE="$HOME/.zshrc"
elif [[ -n "$BASH_VERSION" ]]; then
  SHELL_TYPE="bash"
  CONFIG_FILE="$HOME/.bashrc"
else
  echo -e "${RED}不支持的 shell。本脚本仅支持 bash 和 zsh。${NC}"
  exit 1
fi

# 日志函数
log() {
  echo -e "[$(date '+%Y-%m-%d %H:%M:%S %Z')] $1" | tee -a "$LOG_FILE"
}

# 安装或更新 Nexus CLI
install_nexus_cli() {
  local attempt=1
  local max_attempts=3
  local success=false
  while [[ $attempt -le $max_attempts ]]; do
    log "${BLUE}正在安装/更新 Nexus CLI（第 $attempt/$max_attempts 次）...${NC}"
    if curl -s https://cli.nexus.xyz/ | sh &>/dev/null; then
      log "${GREEN}Nexus CLI 安装/更新成功！${NC}"
      success=true
      break
    else
      log "${YELLOW}第 $attempt 次安装/更新 Nexus CLI 失败。${NC}"
      ((attempt++))
      sleep 2
    fi
  done

  # 确保配置文件存在
  if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "export PATH=\"$HOME/.cargo/bin:\$PATH\"" > "$CONFIG_FILE"
  fi
  source "$CONFIG_FILE" 2>/dev/null || true
  if [[ -f "$HOME/.zshrc" ]]; then
    source "$HOME/.zshrc" 2>/dev/null || true
  fi
  
  sleep 3

  # 验证安装 result
  if command -v nexus-network &>/dev/null; then
    log "${GREEN}nexus-network 版本：$(nexus-network --version 2>/dev/null)${NC}"
  elif command -v nexus-cli &>/dev/null; then
    log "${GREEN}nexus-cli 版本：$(nexus-cli --version 2>/dev/null)${NC}"
  else
    log "${RED}未找到 nexus-network 或 nexus-cli，退出脚本${NC}"
    exit 1
  fi
}

# 读取或设置 Node ID，添加 5 秒超时
get_node_id() {
  CONFIG_PATH="$HOME/.nexus/config.json"
  if [[ -f "$CONFIG_PATH" ]]; then
    CURRENT_NODE_ID=$(jq -r .node_id "$CONFIG_PATH" 2>/dev/null)
    if [[ -n "$CURRENT_NODE_ID" && "$CURRENT_NODE_ID" != "null" ]]; then
      log "${GREEN}检测到配置文件中的 Node ID：$CURRENT_NODE_ID${NC}"
      echo -e "${BLUE}是否使用此 Node ID? (y/n, 默认 y，5 秒后自动继续): ${NC}"
      use_old_id=""
      read -t 5 -r use_old_id
      use_old_id=${use_old_id:-y} # 默认 y
      if [[ "$use_old_id" =~ ^[Nn]$ ]]; then
        read -rp "请输入新的 Node ID: " NODE_ID_TO_USE
        if [[ -z "$NODE_ID_TO_USE" || ! "$NODE_ID_TO_USE" =~ ^[a-zA-Z0-9-]+$ ]]; then
          echo -e "${RED}无效的 Node ID${NC}"
          exit 1
        fi
        jq --arg id "$NODE_ID_TO_USE" '.node_id = $id' "$CONFIG_PATH" > "$CONFIG_PATH.tmp" && mv "$CONFIG_PATH.tmp" "$CONFIG_PATH"
        log "${GREEN}已更新 Node ID: $NODE_ID_TO_USE${NC}"
      else
        NODE_ID_TO_USE="$CURRENT_NODE_ID"
      fi
    else
      log "${YELLOW}未检测到有效 Node ID，请输入新的 Node ID。${NC}"
      read -rp "请输入新的 Node ID: " NODE_ID_TO_USE
      if [[ -z "$NODE_ID_TO_USE" ]]; then exit 1; fi
      mkdir -p "$HOME/.nexus"
      echo "{\"node_id\": \"${NODE_ID_TO_USE}\"}" > "$CONFIG_PATH"
    fi
  else
    log "${YELLOW}未找到配置文件 $CONFIG_PATH，请输入 Node ID。${NC}"
    read -rp "请输入新的 Node ID: " NODE_ID_TO_USE
    if [[ -z "$NODE_ID_TO_USE" ]]; then exit 1; fi
    mkdir -p "$HOME/.nexus"
    echo "{\"node_id\": \"${NODE_ID_TO_USE}\"}" > "$CONFIG_PATH"
  fi
}

# Check releases (Mocked or simple)
check_github_updates() {
  local repo_url="https://github.com/nexus-xyz/nexus-cli.git"
  log "${BLUE}检查 Nexus CLI 仓库更新...${NC}"
  local current_commit=$(git ls-remote --heads "$repo_url" main 2>/dev/null | cut -f1)
  if [[ -z "$current_commit" ]]; then return 1; fi
  # Just log it, don't force anything
  log "${GREEN}远程提交: ${current_commit:0:8}${NC}"
  return 1
}

# 启动节点
start_node() {
  log "${BLUE}正在启动 Nexus 节点 (Node ID: $NODE_ID_TO_USE)...${NC}"
  
  if [[ "$OS_TYPE" == "macOS" ]]; then
    log "${BLUE}在 macOS 中打开新终端窗口启动节点...${NC}"
    # 使用与 startAll 类似的定位逻辑
    osascript <<EOF
tell application "Terminal"
  do script "cd ~ && echo \"🚀 正在启动 Nexus 节点...\" && nexus-network start --node-id $NODE_ID_TO_USE || nexus-cli start --node-id $NODE_ID_TO_USE"
end tell
EOF
    sleep 3
  else
    screen -dmS nexus_node bash -c "nexus-network start --node-id '$NODE_ID_TO_USE' >> $LOG_FILE 2>&1"
  fi
  return 0
}

# 创建桌面快捷方式（参考 install_gensyn.sh）
create_desktop_shortcuts() {
  if [[ "$OS_TYPE" != "macOS" ]]; then
    return 0
  fi

  log "${BLUE}正在创建桌面快捷方式...${NC}"

  CURRENT_USER=$(whoami)
  # [MODIFIED] Do not assume rl-swarm path, assume standalone for "clean" install
  DESKTOP_DIR="/Users/$CURRENT_USER/Desktop"
  mkdir -p "$DESKTOP_DIR"

  # 直接执行 nexus.sh 的完整逻辑（内嵌脚本内容 - Self Contained）
  cat > "$DESKTOP_DIR/nexus.command" <<'NEXUS_DIRECT_EOF'
#!/bin/bash
# 柔和色彩设置
GREEN='\033[1;32m'
BLUE='\033[1;36m'
RED='\033[1;31m'
NC='\033[0m'
LOG_FILE="$HOME/nexus.log"
OS=$(uname -s)
case "$OS" in
  Darwin) OS_TYPE="macOS" ;;
  *) echo -e "${RED}不支持的操作系统${NC}" ; exit 1 ;;
esac
if [[ -n "$ZSH_VERSION" ]]; then CONFIG_FILE="$HOME/.zshrc"; else CONFIG_FILE="$HOME/.bashrc"; fi
log() { echo -e "[$(date '+%Y-%m-%d %H:%M:%S %Z')] $1" | tee -a "$LOG_FILE"; }

# 读取 Node ID
CONFIG_PATH="$HOME/.nexus/config.json"
if [[ -f "$CONFIG_PATH" ]]; then
  NODE_ID=$(jq -r .node_id "$CONFIG_PATH" 2>/dev/null)
else
  echo -e "${RED}未找到 Node ID${NC}"; exit 1
fi

log "${BLUE}正在启动 Nexus 节点 (Node ID: $NODE_ID)...${NC}"
nexus-network start --node-id "$NODE_ID" || nexus-cli start --node-id "$NODE_ID"
echo -e "\n${GREEN}✅ Nexus 节点已停止${NC}"
read -n 1 -s
NEXUS_DIRECT_EOF
  
  chmod +x "$DESKTOP_DIR/nexus.command"
  log "${GREEN}已创建 nexus.command${NC}"
}

# 主循环
main() {
  # 简化依赖安装
  if [[ "$OS_TYPE" == "macOS" ]]; then
    if ! command -v brew >/dev/null; then
      log "${BLUE}检查 Homebrew... (如需安装请手动运行)${NC}"
    fi
  fi

  get_node_id

  # 创建桌面快捷方式
  if [[ "$OS_TYPE" == "macOS" ]]; then
    create_desktop_shortcuts
  fi

  # 首次启动节点
  log "${BLUE}首次启动 Nexus 节点...${NC}"
  install_nexus_cli
  start_node
}

main
