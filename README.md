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

## 如何部署到新机器
1. 把这个文件夹推送到你的 GitHub。
2. 在新机器上 `git pull` 下来。
3. 按照“第一步”运行一遍安装脚本即可。
