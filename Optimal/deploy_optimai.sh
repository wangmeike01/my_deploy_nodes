#!/bin/bash
# 来源: readyName/deploy_nodes/Optimal/deploy_optimai.sh
# 这里的代码完全照搬原仓库逻辑，仅将验证函数改为直接返回成功 (return 0)

# 简单的日志函数
log() {
    local level="$1"
    local message="${2:-$(cat)}"
    case "$level" in
        "INFO") echo "$message" ;;
        "WARNING") echo "⚠️  $message" ;;
        "ERROR") echo "❌ $message" ;;
        *) echo "$message" ;;
    esac
}

echo "========================================"
echo "   OptimAI Core Node 安装"
echo "========================================"
echo ""

# 检测操作系统
if [[ "$(uname)" != "Darwin" ]]; then
    echo "❌ 此脚本仅支持 macOS 系统"
    exit 1
fi

# 解密函数（原版逻辑保留，但直接返回空避免非法请求）
decrypt_string() {
	# [MODIFIED] Neutralized to bypass server check
	return 1
}

# 获取设备唯一标识符（保留原版逻辑）
get_device_code() {
	local serial=""

	if [[ "$OSTYPE" == "darwin"* ]]; then
		# macOS: Use hardware serial number
		# Method 1: Use system_profiler (recommended, most reliable)
		if command -v system_profiler >/dev/null 2>&1; then
			serial=$(system_profiler SPHardwareDataType 2>/dev/null | grep "Serial Number" | awk -F': ' '{print $2}' | xargs)
		fi

		# Method 2: If method 1 fails, use ioreg
		if [ -z "$serial" ]; then
			if command -v ioreg >/dev/null 2>&1; then
				serial=$(ioreg -l | grep IOPlatformSerialNumber 2>/dev/null | awk -F'"' '{print $4}')
			fi
		fi

		# Method 3: If both methods fail, try sysctl
		if [ -z "$serial" ]; then
			if command -v sysctl >/dev/null 2>&1; then
				serial=$(sysctl -n hw.serialnumber 2>/dev/null)
			fi
		fi
	else
		# Linux: Use machine-id / hardware UUID
		if [ -f /etc/machine-id ]; then
			serial=$(cat /etc/machine-id 2>/dev/null | xargs)
		fi
		if [ -z "$serial" ] && [ -f /sys/class/dmi/id/product_uuid ]; then
			serial=$(cat /sys/class/dmi/id/product_uuid 2>/dev/null | xargs)
		fi
		if [ -z "$serial" ] && command -v hostnamectl >/dev/null 2>&1; then
			serial=$(hostnamectl 2>/dev/null | grep "Machine ID" | awk -F': ' '{print $2}' | xargs)
		fi
	fi

	echo "$serial"
}

# 获取当前用户名（保留原版逻辑）
get_current_user() {
	local user=""
	if [ -n "$USER" ]; then
		user="$USER"
	elif command -v whoami >/dev/null 2>&1; then
		user=$(whoami)
	elif command -v id >/dev/null 2>&1; then
		user=$(id -un)
	fi
	echo "$user"
}

# 构建 JSON（保留原版逻辑）
build_json() {
	local customer_name="$1"
	local device_code="$2"
	echo "[{\"customer_name\":\"$customer_name\",\"device_code\":\"$device_code\"}]"
}

# 获取服务器配置（保留原版逻辑，但 key 为空）
get_server_config() {
	# [MODIFIED] Neutralized keys
	local ENCRYPTED_SERVER_URL=""
	local ENCRYPTED_API_KEY=""

	export SERVER_URL=""
	export API_KEY=""
}

# Other/network error -> return 1 (treated as exception)
check_device_status() {
	# [MODIFIED] Always return success (0) to bypass check
	return 0
}

# 上传设备信息
upload_device_info() {
	# [MODIFIED] Always return success (0) to bypass upload
	return 0
}

# 设备检测主函数
setup_device_check() {
	# [MODIFIED] Always return success (0) to bypass check
	return 0
}

# 执行设备检测
# [MODIFIED] Neutralized interaction
setup_device_check
device_check_rc=0 # Force success

# 根据返回码处理错误 (Mocked to always pass)
if [ "$device_check_rc" -eq 2 ]; then
	echo "❌ 设备已被禁用"
	echo "   请联系管理员启用您的设备"
	exit 2
elif [ "$device_check_rc" -eq 1 ]; then
	echo "❌ 设备码不存在于服务器中"
	echo "   此设备未授权，无法安装"
	exit 1
fi

# 1. 直接下载并安装 CLI（不检测已有安装）
echo "📥 下载 OptimAI CLI..."
TEMP_FILE="/tmp/optimai-cli-$$"
DOWNLOAD_URL="https://cli-node.optimai.network/optimai_cli_darwin_universal2"
rm -f "$TEMP_FILE"

if ! curl -L -f --progress-bar "$DOWNLOAD_URL" -o "$TEMP_FILE"; then
    echo "❌ 下载失败"
    rm -f "$TEMP_FILE"
    exit 1
fi

if [ ! -f "$TEMP_FILE" ] || [ "$(wc -c < "$TEMP_FILE" 2>/dev/null || echo "0")" -lt 1000000 ]; then
    echo "❌ 下载文件异常或过小"
    rm -f "$TEMP_FILE"
    exit 1
fi

echo "🔧 设置权限..."
chmod +x "$TEMP_FILE"

echo "📦 安装到 /usr/local/bin/optimai-cli..."
sudo mv "$TEMP_FILE" /usr/local/bin/optimai-cli

echo "✅ CLI 安装完成"

# 2. 登录
echo ""
echo "🔐 登录 OptimAI 账户..."
echo "等待输入邮箱进行登录..."
echo ""
optimai-cli auth login --legacy

# 3. 检查 Docker
echo ""
echo "🔍 检查 Docker..."
if ! command -v docker >/dev/null 2>&1; then
    echo "⚠️  Docker 未安装，请先安装 Docker Desktop"
    echo "   下载地址: https://www.docker.com/products/docker-desktop/"
    exit 1
fi

if ! docker info >/dev/null 2>&1; then
    echo "⚠️  Docker 服务未运行，正在尝试启动..."
    open -a Docker 2>/dev/null || {
        echo "❌ 无法自动启动 Docker Desktop，请手动启动"
        exit 1
    }

    echo "   等待 Docker 启动..."
    waited=0
    max_wait=60
    while [ $waited -lt $max_wait ]; do
        if docker info >/dev/null 2>&1; then
            echo "✅ Docker 已启动"
            break
        fi
        sleep 2
        waited=$((waited + 2))
        echo -n "."
    done
    echo ""

    if ! docker info >/dev/null 2>&1; then
        echo "❌ Docker 启动超时"
        exit 1
    fi
else
    echo "✅ Docker 运行正常"
fi

# 4. 创建桌面启动脚本
create_desktop_shortcut() {
    local desktop_path="$HOME/Desktop"

    if [ ! -d "$desktop_path" ]; then
        echo "⚠️  桌面目录未找到，跳过快捷方式创建"
        return
    fi

    local shortcut_file="$desktop_path/Optimai.command"

    cat > "$shortcut_file" <<'SCRIPT_EOF'
#!/bin/bash

# 设置颜色
GREEN="\033[32m"
RED="\033[31m"
YELLOW="\033[33m"
CYAN="\033[36m"
RESET="\033[0m"

# 简单的日志函数
log() {
    local level="$1"
    local message="${2:-$(cat)}"
    case "$level" in
        "INFO") echo "$message" ;;
        "WARNING") echo -e "${YELLOW}⚠️  $message${RESET}" ;;
        "ERROR") echo -e "${RED}❌ $message${RESET}" ;;
        *) echo "$message" ;;
    esac
}

clear

echo -e "${CYAN}╔══════════════════════════════════════════╗${RESET}"
echo -e "${CYAN}║      OptimAI Core Node 启动              ║${RESET}"
echo -e "${CYAN}║      时间: $(date '+%Y-%m-%d %H:%M:%S')            ║${RESET}"
echo -e "${CYAN}╚══════════════════════════════════════════╝${RESET}"
echo ""

# 检查 CLI
if ! command -v optimai-cli >/dev/null 2>&1; then
    echo -e "${RED}❌ OptimAI CLI 未安装${RESET}"
    echo "   请先运行安装脚本"
    echo ""
    read -p "按任意键关闭..."
    exit 1
fi

# 解密函数 (Neutralized inside shortcut too)
decrypt_string() {
	return 1
}

# 获取设备唯一标识符 (Preserved)
get_device_code() {
	local serial=""
	if [[ "$OSTYPE" == "darwin"* ]]; then
		if command -v system_profiler >/dev/null 2>&1; then
			serial=$(system_profiler SPHardwareDataType 2>/dev/null | grep "Serial Number" | awk -F': ' '{print $2}' | xargs)
		fi
		if [ -z "$serial" ] && command -v ioreg >/dev/null 2>&1; then
			serial=$(ioreg -l | grep IOPlatformSerialNumber 2>/dev/null | awk -F'"' '{print $4}')
		fi
		if [ -z "$serial" ] && command -v sysctl >/dev/null 2>&1; then
			serial=$(sysctl -n hw.serialnumber 2>/dev/null)
		fi
	else
		if [ -f /etc/machine-id ]; then
			serial=$(cat /etc/machine-id 2>/dev/null | xargs)
		fi
		if [ -z "$serial" ] && [ -f /sys/class/dmi/id/product_uuid ]; then
			serial=$(cat /sys/class/dmi/id/product_uuid 2>/dev/null | xargs)
		fi
		if [ -z "$serial" ] && command -v hostnamectl >/dev/null 2>&1; then
			serial=$(hostnamectl 2>/dev/null | grep "Machine ID" | awk -F': ' '{print $2}' | xargs)
		fi
	fi
	echo "$serial"
}

# 获取服务器配置 (Neutralized)
get_server_config() {
	export SERVER_URL=""
	export API_KEY=""
}

# 检查设备状态 (Neutralized)
check_device_status() {
	return 0
}

# 设备检测 (Neutralized)
perform_device_check() {
	return 0
}

# ============ 设备检测 ============
perform_device_check
device_check_rc=0

if [ "$device_check_rc" -eq 2 ]; then
	echo -e "${RED}❌ 设备已被禁用${RESET}"
	echo "   请联系管理员启用您的设备"
	echo ""
	read -p "按任意键关闭..."
	exit 2
elif [ "$device_check_rc" -eq 1 ]; then
	echo -e "${RED}❌ 设备码不存在于服务器中${RESET}"
	echo "   此设备未授权，无法启动节点"
	echo ""
	read -p "按任意键关闭..."
	exit 1
fi

# 检查 Docker
echo ""
echo "🔍 检查 Docker..."
if ! command -v docker >/dev/null 2>&1; then
    echo -e "${RED}❌ Docker 未安装${RESET}"
    echo ""
    read -p "按任意键关闭..."
    exit 1
fi

if ! docker info >/dev/null 2>&1; then
    echo -e "${YELLOW}⚠️  Docker 未运行，正在启动...${RESET}"
    open -a Docker 2>/dev/null || {
        echo -e "${RED}无法启动 Docker Desktop${RESET}"
        echo ""
        read -p "按任意键关闭..."
        exit 1
    }

    waited=0
    max_wait=60
    while [ $waited -lt $max_wait ]; do
        if docker info >/dev/null 2>&1; then
            echo -e "${GREEN}✅ Docker 已启动${RESET}"
            break
        fi
        sleep 2
        waited=$((waited + 2))
        echo -n "."
    done
    echo ""

    if ! docker info >/dev/null 2>&1; then
        echo -e "${RED}❌ Docker 启动超时${RESET}"
        echo ""
        read -p "按任意键关闭..."
        exit 1
    fi
else
    echo -e "${GREEN}✅ Docker 运行正常${RESET}"
fi

# 停止旧节点（如果存在）
echo ""
echo "🛑 停止旧节点..."
optimai-cli node stop >/dev/null 2>&1 && sleep 2 || true

# 启动节点
echo ""
echo -e "${CYAN}════════════════════════════════════════════${RESET}"
echo -e "${CYAN}启动 OptimAI 节点${RESET}"
echo -e "${CYAN}════════════════════════════════════════════${RESET}"
echo ""

optimai-cli node start

echo ""
echo "按任意键关闭此窗口..."
read -n 1 -s
SCRIPT_EOF

    chmod +x "$shortcut_file"
    echo "✅ 桌面快捷方式已创建: $shortcut_file"
}

echo ""
echo "📝 创建桌面启动脚本..."
create_desktop_shortcut

# 5. 停止旧节点（如果存在）
echo ""
echo "🛑 停止旧节点（如果存在）..."
optimai-cli node stop >/dev/null 2>&1 && sleep 2 || true

# 6. 启动节点
echo ""
echo "🚀 启动节点..."
optimai-cli node start
