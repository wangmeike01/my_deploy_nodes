# My DePIN Nodes (私有部署指南)

> **关于本仓库**
> 这是一个为您定制的 DePIN 节点部署工具集。代码结构完全复刻自 `readyName` 的原始仓库，以确保最大兼容性，但移除了所有“设备锁”、“上传数据”和“远程验证”的逻辑。
> **你可以放心地在任意 Mac 设备上运行这些脚本，它们是纯净且完全属于你自己的。**

---

## �️ 第一步：下载仓库 (只需做一次)

在任何新电脑上，打开终端 (Terminal)，运行以下命令将代码下载到本地：

```bash
cd ~/Desktop
git clone https://github.com/wangmeike01/my_deploy_nodes.git
cd my_deploy_nodes
```

---

## 📦 第二步：安装节点 (按顺序执行)

请在终端中依次运行以下命令。

### 1. 安装 Tashi (Docker版)
此脚本会自动检查 Docker 环境并启动容器。虽然它会显示“正在检查设备注册...”，但请放心，我们已经修改了底层逻辑，它会**直接通过**验证。

```bash
bash Tashi/tashi_install.sh
```
*   **注意**：确保 Docker Desktop 已经启动。
*   **结果**：安装完成后，桌面上会出现 `My_Tashi.command` 图标。

### 2. 安装 OptimAI (Optimal)
此脚本保留了原版的完整安装流程。

```bash
bash Optimal/deploy_optimai.sh
```
*   **交互提示**：安装过程中会提示你输入 OptimAI 的邮箱/密码进行登录，这是官方 CLI 的正常行为，请放心输入（数据直接发送给 OptimAI 官方，不经过任何第三方验证服务器）。
*   **去验证化**：脚本内部的 `upload_device_info`（上传设备信息）代码已被架空，不会上传任何数据。
*   **结果**：安装完成后，桌面上会出现 `Optimai.command` 图标。

### 3. 安装 Nexus (纯净版)
这是一个完全自包含的安装脚本，不依赖外部文件。

```bash
bash Nexus/deploy_nexus_for_mac.sh
```
*   **交互提示**：如果是首次安装，脚本会询问你是否同意条款（输入 `y`），或者提示你输入 Node ID。
*   **Node ID 配置**：如果你有旧的 `node-id`，可以直接复制文件；如果是新机器，让它自动生成即可。
*   **结果**：安装完成后，桌面上会出现 `nexus.command` 图标。

### 4. 安装 Dria
最简单的安装脚本。

```bash
bash Dria/instal_dria.sh
```
*   **结果**：安装完成后，桌面上会出现 `dria_start.command` 图标。

---

## 🚀 第三步：日常启动 (一键管理)

安装完上面 4 个节点后，你的桌面上应该有 4 个分散的图标。为了方便管理，我们使用仓库自带的总控启动器。

1.  **准备启动器**：
    确保你已经在 `~/Desktop/my_deploy_nodes` 目录下，运行：
    ```bash
    cp start_all.command ~/Desktop/
    chmod +x ~/Desktop/start_all.command
    ```

2.  **日常使用**：
    以后每次重启电脑，只需要双击桌面的 **`start_all.command`**。
    *   它会自动打开所有 4 个节点的窗口。
    *   **自动排版**：它会自动把窗口调整到合适的大小，并整齐地排列在屏幕上（Nexus 左下，OptimAI 右下，Tashi/Dria 在上方）。

---

## � 如何更新

由于我们完全保留了 Git 仓库结构，更新代码非常简单：

1.  打开终端，进入目录：
    ```bash
    cd ~/Desktop/my_deploy_nodes
    ```
2.  拉取最新代码：
    ```bash
    git pull
    ```
3.  如果脚本有更新，重新运行对应的 `bash xxx.sh` 即可覆盖安装。

---

## ❓ 常见问题

**Q: 脚本运行到“Checking device registration...”的时候卡了一下是正常的吗？**
A: 正常的。原版脚本这里会去请求服务器，超时会报错。**修改版脚本**这里虽然也显示这行字（为了保持原汁原味），但内部直接返回“成功”，所以不会真的卡住。

**Q: 我需要保留 ~/Desktop/my_deploy_nodes 这个文件夹吗？**
A: **是的，请保留。** 这一整套工具都依赖这个文件夹里的脚本。不要删除它。
