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
复制以下命令运行，安装过程中**必须**留意屏幕的登录/绑定提示：

```bash
# === 1. 安装 OptimAI ===
# 会提示你输入邮箱登录
bash Optimal/install.sh

# === 2. 安装 Tashi ===
# 会显示 Device ID，请复制该 ID 去 Tashi 官网绑定
bash Tashi/install.sh

# === 3. 安装 Nexus ===
bash Nexus/install.sh

# === 4. 安装 Dria ===
bash Dria/install.sh
```

**4. 启动所有节点**
以后重启机器后，只需运行这个总控命令（或者双击桌面的图标）：
```bash
./start_all.command
```
此命令会自动排列所有窗口到最佳位置。
