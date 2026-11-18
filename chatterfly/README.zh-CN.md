# Chatterfly 卸载工具

[English](README.md) | **简体中文**

一键彻底卸载腾讯 Chatterfly 输入法（`com.tencent.inputmethod.chatterfly`），停止其后台 LaunchAgents 服务并清除所有系统级与用户级残留文件。

## 使用方法

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/zfdang/macos-app-uninstall-script/main/chatterfly/uninstall.sh)"
```

先预览待删除项（Dry Run，不执行删除）：

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/zfdang/macos-app-uninstall-script/main/chatterfly/uninstall.sh)" -- --dry-run
```

手动指定输出语言（缺省为英文，系统支持中文时自动显示中文）：

```bash
./chatterfly/uninstall.sh --lang en
./chatterfly/uninstall.sh --lang zh
```

或者克隆仓库后运行：

```bash
git clone https://github.com/zfdang/macos-app-uninstall-script.git
cd macos-app-uninstall-script
./chatterfly/uninstall.sh
```

## 清理范围

| 类别 | 路径 / 目标 |
|------|-------------|
| 后台服务 (LaunchAgents) | `/Library/LaunchAgents/com.tencent.ChatterflyServices.plist`<br>`/Library/LaunchAgents/com.tencent.ChatterflyTaskManager.plist`<br>`~/Library/LaunchAgents/com.tencent.ChatterflyTaskManager.plist` |
| 运行中进程 | `Chatterfly`、`ChatterflyPreference`、`ChatterflyTaskManager`、`ChatterflyServices`、`ChatterflyHelper`、`ChatterflyInstaller`、`ChatterflyXdelta` |
| 输入法主程序 | `/Library/Input Methods/Chatterfly.app` |
| 应用支持数据 | `~/Library/Application Support/Chatterfly/`<br>`~/Library/Application Support/com.tencent.inputmethod.chatterfly/`<br>`~/Library/Application Support/com.tencent.ChatterflyTaskManager/`<br>`~/Library/Application Support/com.tencent.ChatterflyPreference/`<br>`~/Library/Application Support/com.tencent.ChatterflyInstaller/` |
| `~/Library` 根目录数据 (RaftMonitor) | `~/Library/com.tencent.inputmethod.chatterfly/`<br>`~/Library/com.tencent.ChatterflyTaskManager/`<br>`~/Library/com.tencent.ChatterflyPreference/` |
| 偏好设置 (`Preferences` & `defaults`) | `~/Library/Preferences/com.tencent.inputmethod.chatterfly.plist`<br>`~/Library/Preferences/com.tencent.ChatterflyPreference.plist`<br>`~/Library/Preferences/com.tencent.ChatterflyTaskManager.plist`<br>`~/Library/Preferences/com.tencent.ChatterflyInstaller.plist`<br>`~/Library/Preferences/ChatterflyServices.plist` |
| 缓存 (`Caches`) | `~/Library/Caches/com.tencent.inputmethod.chatterfly`<br>`~/Library/Caches/com.tencent.ChatterflyTaskManager`<br>`~/Library/Caches/com.tencent.ChatterflyPreference`<br>`~/Library/Caches/ChatterflyServices`<br>`~/Library/Caches/com.tencent.ChatterflyInstaller`<br>`~/Library/Caches/com.tencent.yuanbao.installType`（仅在未安装 `/Applications/Yuanbao.app` 时清理） |
| HTTP 存储 | `~/Library/HTTPStorages/com.tencent.inputmethod.chatterfly`<br>`~/Library/HTTPStorages/com.tencent.ChatterflyTaskManager`<br>`~/Library/HTTPStorages/com.tencent.ChatterflyPreference`<br>`~/Library/HTTPStorages/ChatterflyServices`<br>`~/Library/HTTPStorages/com.tencent.ChatterflyInstaller` |
| WebKit 数据 | `~/Library/WebKit/com.tencent.ChatterflyInstaller` |
| 保存的应用状态 | `~/Library/Saved Application State/com.tencent.inputmethod.chatterfly.savedState`<br>`~/Library/Saved Application State/com.tencent.ChatterflyPreference.savedState`<br>`~/Library/Saved Application State/com.tencent.ChatterflyTaskManager.savedState`<br>`~/Library/Saved Application State/com.tencent.ChatterflyInstaller.savedState` |
| 最近使用记录 | `~/Library/Application Support/com.apple.sharedfilelist/.../com.tencent.chatterfly*.sfl*` |
| 临时目录 (`$TMPDIR`) | `$TMPDIR/com.tencent.chatterfly`<br>`$TMPDIR/com.tencent.ChatterflyInstaller` |
| 下载目录安装包 | `~/Downloads/Chatterfly_V*.app`、`~/Downloads/Chatterfly_V*.zip`、`~/Downloads/Chatterfly_V*.dmg`、`~/Downloads/ChatterflyInstaller*` |

## 注意事项

- 脚本会先 `launchctl bootout` / `unload` 后台服务再结束进程，防止 `ChatterflyServices`（每 3 秒重启）被 `launchd` 拉起。
- 删除 `/Library/Input Methods/Chatterfly.app` 与 `/Library/LaunchAgents/com.tencent.Chatterfly*.plist` 需要管理员权限（`sudo`），脚本仅在检测到系统级残留时才会请求密码。
- 卸载完成后建议注销或重启 macOS 以确保输入法服务缓存完全刷新。
