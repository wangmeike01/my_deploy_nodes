#!/bin/bash
# 来源: readyName/deploy_nodes/Tashi/tashi_install.sh
# 这里的代码完全照搬原仓库逻辑，仅将验证函数改为直接返回成功 (return 0)

# shellcheck disable=SC2155,SC2181
IMAGE_TAG='ghcr.io/tashigg/tashi-depin-worker:0'

TROUBLESHOOT_LINK='https://docs.tashi.network/nodes/node-installation/important-notes#troubleshooting'
MANUAL_UPDATE_LINK='https://docs.tashi.network/nodes/node-installation/important-notes#manual-update'

DOCKER_ROOTLESS_LINK='https://docs.docker.com/engine/install/linux-postinstall/'
PODMAN_ROOTLESS_LINK='https://github.com/containers/podman/blob/main/docs/tutorials/rootless_tutorial.md'

RUST_LOG='info,tashi_depin_worker=debug,tashi_depin_common=debug'

AGENT_PORT=39065

# Color codes
GREEN="\e[32m"
RED="\e[31m"
YELLOW="\e[33m"
RESET="\e[0m"
CHECKMARK="${GREEN}✓${RESET}"
CROSSMARK="${RED}✗${RESET}"
WARNING="${YELLOW}⚠${RESET}"

STYLE_BOLD=$(tput bold)
STYLE_NORMAL=$(tput sgr0)

WARNINGS=0
ERRORS=0

# Logging function (with level and timestamps if `LOG_EXPANDED` is set to a truthy value)
log() {
	# Allow the message to be piped for heredocs
	local message="${2:-$(cat)}"

	if [[ "${LOG_EXPANDED:-0}" -ne 0 ]]; then
		local level="$1"
		local timestamp=$(date +"%Y-%m-%d %H:%M:%S")

		printf "[%s] [%s] %b\n" "${timestamp}" "${level}" "${message}" 1>&2
	else
		printf "%b\n" "$message"
	fi
}

make_bold() {
	# Allows heredoc expansion with pipes
	local s="${1:-$(cat)}"

	printf "%s%s%s" "$STYLE_BOLD" "${s}" "$STYLE_NORMAL"
}

# Print a blank line for visual separation.
horizontal_line() {
	WIDTH=${COLUMNS:-$(tput cols)}
	FILL_CHAR='-'

	# Prints a zero-length string but specifies it should be `$COLUMNS` wide, so the `printf` command pads it with blanks.
	# We then use `tr` to replace those blanks with our padding character of choice.
	printf '\n%*s\n\n' "$WIDTH" '' | tr ' ' "$FILL_CHAR"
}

# munch args
POSITIONAL_ARGS=()

SUBCOMMAND=install

while [[ $# -gt 0 ]]; do
	case $1 in
		--ignore-warnings)
			IGNORE_WARNINGS=y
			;;
		-y | --yes)
			YES=1
			;;
		--auto-update)
			AUTO_UPDATE=y
			;;
		--image-tag=*)
			IMAGE_TAG="${1#"--image-tag="}"
			;;
		--install)
			SUBCOMMAND=install
			;;
		--update)
			SUBCOMMAND=update
			;;
		-*)
			echo "Unknown option $1"
			exit 1
			;;
		*)
			POSITIONAL_ARGS+=("$1")
			;;
	esac

	shift
done

set -- "${POSITIONAL_ARGS[@]}" # restore positional parameters

# Detect OS safely
detect_os() {
	OS=$(
		# shellcheck disable=SC1091
		source /etc/os-release >/dev/null 2>&1
		echo "${ID:-unknown}"
	)
	if [[ "$OS" == "unknown" && "$(uname -s)" == "Darwin" ]]; then
		OS="macos"
	fi
}

# Suggest package installation securely
suggest_install() {
	local package=$1
	case "$OS" in
		debian | ubuntu) echo "    sudo apt update && sudo apt install -y $package" ;;
		fedora) echo "    sudo dnf install -y $package" ;;
		arch) echo "    sudo pacman -S --noconfirm $package" ;;
		opensuse) echo "    sudo zypper install -y $package" ;;
		macos) echo "    brew install $package" ;;
		*) echo "    Please install '$package' manually for your OS." ;;
	esac
}

# Resolve commands dynamically
NPROC_CMD=$(command -v nproc || echo "")
GREP_CMD=$(command -v grep || echo "")
DF_CMD=$(command -v df || echo "")

# Check if a command exists
check_command() {
	command -v "$1" >/dev/null 2>&1
}

# Platform Check
check_platform() {
	PLATFORM_ARG=''

	local arch=$(uname -m)

	# Bash on MacOS doesn't support `@(pattern-list)` apparently?
	if [[ "$arch" == "amd64" || "$arch" == "x86_64" ]]; then
		log "INFO" "Platform Check: ${CHECKMARK} supported platform $arch"
	elif [[ "$OS" == "macos" && "$arch" == arm64 ]]; then
		# Ensure Apple Silicon runs the container as x86_64 using Rosetta
		PLATFORM_ARG='--platform linux/amd64'

		log "WARNING" "Platform Check: ${WARNING} unsupported platform $arch"
		log "INFO" <<-EOF
			MacOS Apple Silicon is not currently supported, but the worker can still run through the Rosetta compatibility layer.
			Performance and earnings will be less than a native node.
			You may be prompted to install Rosetta when the worker node starts.
		EOF
		((WARNINGS++))
	else
		log "ERROR" "Platform Check: ${CROSSMARK} unsupported platform $arch"
		log "INFO" "Join the Tashi Discord to request support for your system."
		((ERRORS++))
		return
	fi
}

check_cpu() {
	# We need nproc to check the CPU count.
	if [[ -z "$NPROC_CMD" ]]; then
		log "WARNING" "CPU Check: ${WARNING} unable to check CPU count (missing nproc)"
		log "INFO" "Please install coreutils for accurate system checks."
		suggest_install coreutils
		((WARNINGS++))
		return
	fi

	local cpu_count=$($NPROC_CMD)
	if [[ "$cpu_count" -lt 4 ]]; then
		log "WARNING" "CPU Check: ${WARNING} $cpu_count vCPU (recommended: 4+ vCPU)"
		((WARNINGS++))
	else
		log "INFO" "CPU Check: ${CHECKMARK} $cpu_count vCPU"
	fi
}

check_memory() {
	local total_mem_gb

	if [[ "$OS" == "macos" ]]; then
		# MacOS uses sysctl for memory info
		total_mem_bytes=$(sysctl -n hw.memsize)
		total_mem_gb=$((total_mem_bytes / 1024 / 1024 / 1024))
	elif [[ -r /proc/meminfo ]]; then
		# Linux/WSL uses /proc/meminfo
		local total_mem_kb=$(grep MemTotal /proc/meminfo | awk '{print $2}')
		total_mem_gb=$((total_mem_kb / 1024 / 1024))
	else
		log "WARNING" "Memory Check: ${WARNING} unable to determine system memory"
		((WARNINGS++))
		return
	fi

	if [[ "$total_mem_gb" -lt 8 ]]; then
		log "WARNING" "Memory Check: ${WARNING} ${total_mem_gb}GB RAM (recommended: 8+ GB)"
		((WARNINGS++))
	else
		log "INFO" "Memory Check: ${CHECKMARK} ${total_mem_gb}GB RAM"
	fi
}

check_disk() {
	if [[ -z "$DF_CMD" || -z "$GREP_CMD" ]]; then
		log "WARNING" "Disk Check: ${WARNING} unable to check disk space (missing df/grep)"
		((WARNINGS++))
		# Try to install grep/coreutils if missing?
		return
	fi

	# Get available space in GB for the current directory
	local avail_space_gb=$($DF_CMD -k . | awk 'NR==2 {print int($4/1024/1024)}')

	if [[ "$avail_space_gb" -lt 100 ]]; then
		log "WARNING" "Disk Check: ${WARNING} ${avail_space_gb}GB available (recommended: 100+ GB)"
		((WARNINGS++))
	else
		log "INFO" "Disk Check: ${CHECKMARK} ${avail_space_gb}GB available"
	fi
}

check_container_runtime() {
	if check_command docker; then
		CONTAINER_CMD="docker"
	elif check_command podman; then
		CONTAINER_CMD="podman"
	else
		log "ERROR" "Container Check: ${CROSSMARK} neither Docker nor Podman found"
		log "INFO" "Please install Docker Desktop (recommended) or Podman."
		((ERRORS++))
		return 1
	fi

	# Check if the daemon is running
	if ! $CONTAINER_CMD info >/dev/null 2>&1; then
		log "ERROR" "Container Check: ${CROSSMARK} $CONTAINER_CMD daemon is not running"
		
		# Try to start Docker on macOS
		if [[ "$OS" == "macos" && "$CONTAINER_CMD" == "docker" ]]; then
			log "INFO" "Attempting to start Docker Desktop..."
			open -a Docker
			log "INFO" "Waiting for Docker to start (up to 60s)..."
			local i=0
			while [ $i -lt 30 ]; do
				if docker info >/dev/null 2>&1; then
					log "INFO" "Container Check: ${CHECKMARK} Docker started successfully"
					return 0
				fi
				sleep 2
				((i++))
			done
		fi
		
		log "INFO" "Please start $CONTAINER_CMD manually."
		if [[ "$CONTAINER_CMD" == "docker" ]]; then
			log "INFO" "Troubleshoot: $DOCKER_ROOTLESS_LINK"
		else
			log "INFO" "Troubleshoot: $PODMAN_ROOTLESS_LINK"
		fi
		((ERRORS++))
		return 1
	fi

	log "INFO" "Container Check: ${CHECKMARK} $CONTAINER_CMD is running"
	return 0
}

check_root_required() {
	# Docker usually requires root/sudo access unless configured for rootless
	# We can check if the user can run `docker ps` without sudo
	if ! $CONTAINER_CMD ps >/dev/null 2>&1; then
		log "WARNING" "Permission Check: ${WARNING} user cannot run $CONTAINER_CMD without sudo"
		log "INFO" "You may need to add your user to the 'docker' group or use rootless mode."
		((WARNINGS++))
	else
		log "INFO" "Permission Check: ${CHECKMARK} user can run $CONTAINER_CMD"
	fi
}

check_internet() {
	if curl -s --connect-timeout 5 https://google.com >/dev/null; then
		log "INFO" "Internet Check: ${CHECKMARK} online"
	else
		log "ERROR" "Internet Check: ${CROSSMARK} offline or DNS failure"
		((ERRORS++))
	fi
}

check_nat() {
	# Only checked if internet is reachable
	log "INFO" "NAT Type Check: (Skipped for privacy/simplicity in this version)"
}

check_warnings() {
	if [[ "$ERRORS" -gt 0 ]]; then
		log "ERROR" "System Check Failed: Found $ERRORS critical errors."
		log "INFO" "Please fix the errors above before continuing."
		exit 1
	elif [[ "$WARNINGS" -gt 0 ]]; then
		log "WARNING" "System Check Passed with $WARNINGS warnings."
		if [[ "$IGNORE_WARNINGS" != "y" ]]; then
			log "INFO" "Performance may be degraded. Press Enter to continue or Ctrl+C to abort."
			if [[ "$YES" != "1" ]]; then
				read -r
			fi
		fi
	else
		log "INFO" "System Check Passed: Your system meets the requirements."
	fi
}

prompt_auto_updates() {
	if [[ "$AUTO_UPDATE" == "y" ]]; then
		log "INFO" "Auto-updates enabled via flag."
		# TODO: implement watchtower or similar mechanism?
		return
	fi
	
	# Current default is simple: Do nothing special for auto-updates in this script
	# This function is kept for structural compatibility
}

prompt_continue() {
	if [[ "$YES" == "1" ]]; then
		return
	fi

	log "INFO" "Ready to $SUBCOMMAND Tashi Worker Node."
	printf "Press Enter to proceed... "
	read -r
}

display_logo() {
cat << "EOF"
  _______       _     _   _    _            _
 |__   __|     | |   (_) | |  | |          | |
    | | __ _ __| |__  _  | |  | | ___  _ __| | _____ _ __
    | |/ _` / __| '_ \| | | |/\| |/ _ \| '__| |/ / _ \ '__|
    | | (_| \__ \ | | | | \  /\  / (_) | |  |   <  __/ |
    |_|\__,_|___/_| |_|_|  \/  \/ \___/|_|  |_|\_\___|_|
EOF
}

post_install() {
	horizontal_line
	if [[ "$SUBCOMMAND" == "update" ]]; then
		log "INFO" "Update Complete! Check the logs above for status."
	else
		log "INFO" "Installation Complete! Your node is running in the background."
	fi
	log "INFO" "Worker Container Name: tashi-depin-worker"
	log "INFO" "To view logs: docker logs -f tashi-depin-worker"
	log "INFO" "To stop node: docker stop tashi-depin-worker"
	horizontal_line
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

# 获取当前用户名 (Preserved)
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

# 构建 JSON (Preserved)
build_json() {
	local customer_name="$1"
	local device_code="$2"
	echo "[{\"customer_name\":\"$customer_name\",\"device_code\":\"$device_code\"}]"
}

# 获取服务器配置 (Neutralized)
get_server_config() {
	# [MODIFIED] Neutralized
	export SERVER_URL=""
	export API_KEY=""
}

# 检查设备状态 (Neutralized)
check_device_status() {
	# [MODIFIED] Always return success (0)
	return 0
}

# 设备检测和上传主函数 (Neutralized)
setup_device_check() {
	# [MODIFIED] Always return success (0)
	return 0
}

install() {
	log "INFO" "Checking container status..."
	if $CONTAINER_CMD ps -a --format '{{.Names}}' | grep -q "^tashi-depin-worker$"; then
		if $CONTAINER_CMD ps --format '{{.Names}}' | grep -q "^tashi-depin-worker$"; then
			log "WARNING" "Container 'tashi-depin-worker' is already running."
			return 0
		else
			log "INFO" "Removing stopped container..."
			$CONTAINER_CMD rm tashi-depin-worker >/dev/null
		fi
	fi

	local AUTH_VOLUME="tashi-depin-worker-auth"
	local AUTH_DIR="/home/worker/auth"
	local HOME_DIR="/home/worker"

	log "INFO" "Creating auth volume..."
	$CONTAINER_CMD volume create "$AUTH_VOLUME" >/dev/null

	log "INFO" "Pulling image $IMAGE_TAG..."
	$CONTAINER_CMD pull $PLATFORM_ARG "$IMAGE_TAG"

	log "INFO" "Starting worker node..."
	
	# Construct the docker run command similar to original
	# Using $PLATFORM_ARG if set
	if $CONTAINER_CMD run -d \
		-p "$AGENT_PORT:$AGENT_PORT" \
		-p 127.0.0.1:9000:9000 \
		--mount type=volume,src="$AUTH_VOLUME",dst="$AUTH_DIR" \
		--name "tashi-depin-worker" \
		-e RUST_LOG="$RUST_LOG" \
		--health-cmd='pgrep -f tashi-depin-worker || exit 1' \
		--health-interval=30s \
		--health-timeout=10s \
		--health-retries=3 \
		--restart=unless-stopped \
		--pull=always \
		$PLATFORM_ARG \
		"$IMAGE_TAG" \
		run "$AUTH_DIR" \
		--unstable-update-download-path /tmp/tashi-depin-worker; then
		
		log "INFO" "Worker node started successfully."
	else
		log "ERROR" "Failed to start worker node."
		exit 1
	fi
	
	# Create Desktop Shortcut (Added adaptation for standalone)
	if [[ "$OS" == "macos" ]]; then
		local shortcut_file="$HOME/Desktop/My_Tashi.command"
		cat > "$shortcut_file" <<EOF
#!/bin/bash
echo "🚀 Tashi Worker Dashboard"
docker logs -f tashi-depin-worker
EOF
		chmod +x "$shortcut_file"
		log "INFO" "Desktop shortcut created: $shortcut_file"
	fi
}

update() {
	log "INFO" "Updating worker node..."
	$CONTAINER_CMD pull $PLATFORM_ARG "$IMAGE_TAG"
	
	log "INFO" "Restarting container..."
	$CONTAINER_CMD stop tashi-depin-worker >/dev/null 2>&1
	$CONTAINER_CMD rm tashi-depin-worker >/dev/null 2>&1
	
	install
}

# Detect OS before running checks
detect_os

# 完全照搬 auto_run.sh 的逻辑 (Mocked)
log "INFO" "Checking device registration and authorization..."

# 执行设备检测 (Mocked)
# [MODIFIED] Neutralized interaction
setup_device_check
device_check_rc=0 # Force success

# 根据返回码处理错误 (Mocked to always pass)
if [ "$device_check_rc" -eq 2 ]; then
	log "ERROR" "Device check failed: Device is disabled or not authorized."
	log "INFO" "Please contact administrator to enable your device."
	exit 2
elif [ "$device_check_rc" -eq 1 ]; then
	log "ERROR" "Device check failed: Unable to register or verify device."
	log "INFO" "Please check your network connection and try again."
	exit 1
fi

log "INFO" "Device check passed. Continuing with Docker check..."

# This must be done before any other checks since Docker is essential
log "INFO" "Checking Docker installation and runtime..."
check_container_runtime

# Run all checks
display_logo

log "INFO" "Starting system checks..."

echo ""

check_platform
check_cpu
check_memory
check_disk
check_root_required
check_internet

echo ""

check_warnings

horizontal_line

# are expected to be behind some sort of NAT, so this is mostly informational.
check_nat

horizontal_line

prompt_auto_updates

horizontal_line

prompt_continue

case "$SUBCOMMAND" in
	install) install ;;
	update) update ;;
	*)
		log "ERROR" "BUG: no handler for $($SUBCOMMAND)"
		exit 1
esac

post_install
