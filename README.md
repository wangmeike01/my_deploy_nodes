# My DePIN Nodes (纯净版)

这是一个为您定制的 DePIN 节点部署工具集。
它去除了原服务商的“设备锁”限制，直接使用官方安装源，能够支持在任意 Mac 设备上运行。

## 包含项目
*   **Optimal (OptimAI)**
*   **Tashi**
*   **Nexus**
*   **Dria**

## 如何使用

### 第一步：首次安装 (每台新机器做一次)
你需要分别运行这4个脚本来安装软件并生成桌面快捷方式。

```bash
# 1. 安装 OptimAI (需要登录邮箱)
bash Optimal/install.sh

# 2. 安装 Tashi (需要去后台绑定设备)
bash Tashi/install.sh

# 3. 安装 Nexus
bash Nexus/install.sh

# 4. 安装 Dria
bash Dria/install.sh
```

**⚠️ 注意**：因为这是纯净版，脚本运行过程中如果弹出官方的登录/绑定提示，请务必按提示操作。

### 第二步：日常启动
安装完成后，你的桌面上会出现 4 个以 `My_` 开头的启动图标。
你可以单独点击它们，或者直接运行通过仓库根目录下的：

```bash
./start_all.command
```
它会自动打开所有窗口并排列整齐。

## 🌍 如何在新 Mac Mini 上部署 (保姆级教程)

在新机器上，不需要再手动创建脚本，直接从你的 GitHub 下载即可。

**1. 准备工作**
*   确保新机器已联网。
*   (可选) 安装 Docker Desktop (如果没有安装，Tashi 脚本会提示你)。

**2. 下载你的专属仓库**
打开终端（Terminal），复制并运行以下命令：
```bash
cd ~/Desktop
git clone https://github.com/wangmeike01/my_deploy_nodes.git
cd my_deploy_nodes
```

**3. 逐个安装项目 (只需运行一次)**

**🚀 极速安装 (推荐)**
你可以像原来那样，直接复制下面的“一键命令”到终端运行 (无需手动下载代码)：

```bash
# === 1. 安装 OptimAI ===
bash <(curl -fsSL https://raw.githubusercontent.com/wangmeike01/my_deploy_nodes/main/Optimal/install.sh)

# === 2. 安装 Tashi ===
bash <(curl -fsSL https://raw.githubusercontent.com/wangmeike01/my_deploy_nodes/main/Tashi/install.sh)

# === 3. 安装 Nexus ===
bash <(curl -fsSL https://raw.githubusercontent.com/wangmeike01/my_deploy_nodes/main/Nexus/install.sh)

# === 4. 安装 Dria ===
bash <(curl -fsSL https://raw.githubusercontent.com/wangmeike01/my_deploy_nodes/main/Dria/install.sh)
```

**📂 方式二：手动下载 (备用)**
如果你更喜欢把代码下载下来：
1. `git clone https://github.com/wangmeike01/my_deploy_nodes.git`
2. `cd my_deploy_nodes`
3. 运行 `bash Optimal/install.sh` 等。

**4. 启动所有节点**
一键启动命令（需要先下载了仓库或者有 Start_All 脚本）：
```bash
# 如果你只用了上面的极速安装，可能还没有 Start_All 脚本
# 你可以单独运行这个命令来下载它到桌面：
curl -fsSL https://raw.githubusercontent.com/wangmeike01/my_deploy_nodes/main/start_all.command -o ~/Desktop/start_all.command && chmod +x ~/Desktop/start_all.command
```
下载后，双击桌面的 `start_all.command` 即可。
