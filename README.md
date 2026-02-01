# My DePIN Nodes (纯净版)

这是一个为您定制的 DePIN 节点部署工具集。
它去除了原服务商的“设备锁”限制，直接使用官方安装源，能够支持在任意 Mac 设备上运行。

## 包含项目
*   **Optimal (OptimAI)**
*   **Tashi**
*   **Nexus**
*   **Dria**

## 🚀 极速安装指南 (所有机器通用)

不管你是新机器还是旧机器，都不需要手动下载代码，直接在终端复制下面的命令运行即可。

**第一步：逐个安装节点**

```bash
# === 1. 安装 OptimAI ===
# (安装时会提示输入邮箱登录)
bash <(curl -fsSL https://raw.githubusercontent.com/wangmeike01/my_deploy_nodes/main/Optimal/install.sh)

# === 2. 安装 Tashi ===
# (会显示 Device ID，请复制该 ID 去 Tashi 官网绑定)
bash <(curl -fsSL https://raw.githubusercontent.com/wangmeike01/my_deploy_nodes/main/Tashi/install.sh)

# === 3. 安装 Nexus ===
bash <(curl -fsSL https://raw.githubusercontent.com/wangmeike01/my_deploy_nodes/main/Nexus/install.sh)

# === 4. 安装 Dria ===
bash <(curl -fsSL https://raw.githubusercontent.com/wangmeike01/my_deploy_nodes/main/Dria/install.sh)
```

**第二步：下载总控启动器**

安装完上面4个后，运行这条命令来获取“一键启动”图标到桌面：

```bash
curl -fsSL https://raw.githubusercontent.com/wangmeike01/my_deploy_nodes/main/start_all.command -o ~/Desktop/start_all.command && chmod +x ~/Desktop/start_all.command
```

---

## 🕹 日常使用

每天重启电脑后，只需要双击桌面的 **`start_all.command`** 图标，它就会自动打开所有窗口并排列整齐。

---

## 🛠 实用工具箱

### 🧹 CPU 占用修复 (Spotlight 清理)
如果发现 Mac 风扇狂转或者变卡，可能是系统索引出问题了。运行这个脚本修复：
```bash
bash <(curl -fsSL https://raw.githubusercontent.com/wangmeike01/my_deploy_nodes/main/utils/clean_spotlight.sh)
```

---

## 📂 (高级) 手动下载源码方式
如果你懂 Git，也可以把仓库克隆下来自己修改：
1. `git clone https://github.com/wangmeike01/my_deploy_nodes.git`
2. `cd my_deploy_nodes`
3. 运行本地脚本：`bash Optimal/install.sh`

