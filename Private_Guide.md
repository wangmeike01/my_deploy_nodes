# My DePIN Nodes (私有部署指南)

> **关于本仓库**
> 这是一个为您定制的 DePIN 节点部署工具集。代码结构完全复刻自 `readyName` 的原始仓库，以确保最大兼容性，但移除了所有“设备锁”、“上传数据”和“远程验证”的逻辑。
> **你可以放心地在任意 Mac 设备上运行这些脚本，它们是纯净且完全属于你自己的。**

---

## 🚀 极速安装指南

**不需要下载代码，不需要 `git clone`。**
直接打开终端 (Terminal)，复制下面的命令并运行，即可完成安装。

---

### 1. 安装 Tashi (Docker版)
此命令会自动检查 Docker 环境并启动容器。

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/wangmeike01/my_deploy_nodes/main/Tashi/tashi_install.sh)
```

### 2. 安装 OptimAI (Optimal)
此命令会下载 OptimAI CLI 并启动节点（去除了设备锁验证）。

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/wangmeike01/my_deploy_nodes/main/Optimal/deploy_optimai.sh)
```

### 3. 安装 Nexus (纯净版)
此命令会自动完成配置并启动 Nexus 节点。

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/wangmeike01/my_deploy_nodes/main/Nexus/deploy_nexus_for_mac.sh)
```

### 4. 安装 Dria
最简单的安装脚本。

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/wangmeike01/my_deploy_nodes/main/Dria/instal_dria.sh)
```

---

## 🎮 下载总控启动器 (推荐)

安装完上面 4 个节点后，运行这条命令，你的桌面上就会生成一个 **`start_all.command`** 图标。以后每次重启电脑，双击它就能一键启动并自动排列所有节点窗口。

```bash
curl -fsSL https://raw.githubusercontent.com/wangmeike01/my_deploy_nodes/main/start_all.command -o ~/Desktop/start_all.command && chmod +x ~/Desktop/start_all.command
```

---

## 🔄 如何更新节点

如果官方发布了新版本，你只需要**再次运行上面的安装命令**即可。脚本会自动处理更新逻辑。

例如，从新安装 Nexus：
```bash
bash <(curl -fsSL https://raw.githubusercontent.com/wangmeike01/my_deploy_nodes/main/Nexus/deploy_nexus_for_mac.sh)
```
