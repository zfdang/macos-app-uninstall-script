# macOS App Uninstall Scripts

[English](README.md) | **简体中文**

一键彻底卸载 macOS 应用的脚本集合 —— 不仅删除 `.app` 本体，还清理 `LaunchAgents` / `LaunchDaemons`、后台进程、`Application Support`、`Preferences`、`Caches`、`HTTPStorages`、`WebKit`、临时目录及安装包等全部系统及用户级残留文件。

每个子目录对应一个 macOS 应用，内含独立的一键卸载脚本 `uninstall.sh`。脚本缺省输出英文，当检测到系统支持中文时自动输出中文提示。

---

## 已收录应用列表

| 应用 | 目录 | 一键卸载命令 | 说明 |
|---|---|---|---|
| **Chatterfly（腾讯输入法）** | [`chatterfly/`](chatterfly/) | `bash -c "$(curl -fsSL https://raw.githubusercontent.com/zfdang/macos-app-uninstall-script/main/chatterfly/uninstall.sh)"` | 卸载 Chatterfly 输入法、LaunchAgents 后台服务及全部残留 |
| **豆包输入法 (Doubao IME)** | [`doubaoime/`](doubaoime/) | `bash -c "$(curl -fsSL https://raw.githubusercontent.com/zfdang/macos-app-uninstall-script/main/doubaoime/uninstall.sh)"` | 卸载豆包输入法及全部残留（整理自 [missuo/doubaoime-uninstaller](https://github.com/missuo/doubaoime-uninstaller)） |

> **提示：** 所有脚本均支持 `--dry-run`（`-n`）预览待清理项，并支持 `--lang en|zh` 手动指定输出语言。

---

## 使用方法

### 方式一：远程一键执行（推荐）

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/zfdang/macos-app-uninstall-script/main/<app-dir>/uninstall.sh)"
```

先预览待删除项（Dry Run，不执行删除）：

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/zfdang/macos-app-uninstall-script/main/<app-dir>/uninstall.sh)" -- --dry-run
```

### 方式二：克隆仓库到本地执行

```bash
git clone https://github.com/zfdang/macos-app-uninstall-script.git
cd macos-app-uninstall-script
./<app-dir>/uninstall.sh
```

---

## 如何新增 App 卸载脚本

欢迎通过 Pull Request 为更多 macOS 应用补充一键卸载脚本！请遵循以下规范：

### 1. 目录结构规范

每个应用单独建立一个**全小写、无空格**的目录（如 `wechat/`、`chatterfly/`）：

```text
<app-name>/
├── README.md        # 英文说明文档（默认文档：使用方法、清理路径对照表、注意事项）
├── README.zh-CN.md  # 中文说明文档（推荐补充）
└── uninstall.sh     # 一键卸载脚本（需具备可执行权限 chmod +x）
```

### 2. 调查应用安装路径清单（macOS 常见残留位置）

编写脚本前，建议按以下清单全面排查目标应用在系统与用户目录写入的所有位置：

1. **应用 / 输入法主程序**
   - `/Applications/<App>.app`、`~/Applications/<App>.app`
   - `/Library/Input Methods/<App>.app`（输入法类应用）
2. **后台服务与守护进程（优先卸载再删文件，避免被 `launchd` 自动拉起）**
   - `/Library/LaunchAgents/`、`/Library/LaunchDaemons/`
   - `~/Library/LaunchAgents/`、`/Library/PrivilegedHelperTools/`
   - 检查活跃服务：`launchctl list | grep -i <keyword>`
3. **运行中进程**
   - `ps aux | grep -i <keyword>`
4. **用户库目录 (`~/Library`)**
   - `~/Library/Application Support/<App or BundleID>`
   - `~/Library/<BundleID>`（部分应用会直接在 `~/Library/` 下创建目录）
   - `~/Library/Preferences/<BundleID>*.plist`（配合 `defaults delete <domain>` 清除 `cfprefsd` 缓存）
   - `~/Library/Caches/<BundleID>*`
   - `~/Library/HTTPStorages/<BundleID>*`
   - `~/Library/WebKit/<BundleID>*`
   - `~/Library/Containers/<BundleID>*` 与 `~/Library/Group Containers/<TeamID>.<BundleID>*`
   - `~/Library/Saved Application State/<BundleID>.savedState`
   - `~/Library/Logs/<App or BundleID>`
   - `~/Library/Application Support/com.apple.sharedfilelist/com.apple.LSSharedFileList.ApplicationRecentDocuments/`
5. **安装包记录、插件与临时目录**
   - `pkgutil --pkgs | grep -i <keyword>` 与 `/private/var/db/receipts/`
   - `/Library/QuickLook/`、`~/Library/QuickLook/`
   - `$TMPDIR`（`getconf DARWIN_USER_TEMP_DIR`）与 `~/Downloads/` 中的安装包
6. **输入法专项检查**
   - 检查 `defaults read com.apple.HIToolbox AppleEnabledInputSources` 中是否仍启用了该输入法源，并提示用户先在「系统设置 → 键盘 → 输入法」中移除。
7. **进阶技巧**
   - 查看主程序及内嵌组件 `Contents/Info.plist` 获取全部 Bundle ID。
   - 若官方安装包内自带卸载器或 helper，可用 `strings` 分析其清理路径，再结合实机 `find /Library ~/Library -maxdepth 4 -iname "*<keyword>*"` 补充官方未清理的残留。

### 3. 脚本编写规范

- **Shebang 与安全选项**：使用 `#!/usr/bin/env bash` 与 `set -euo pipefail`（兼容 macOS 自带的 Bash 3.2）。
- **中英文自适应**：缺省输出英文（`en`），当系统支持中文（`LC_ALL`/`LANG` 或 `defaults read -g AppleLanguages` 包含 `zh`）时自动输出中文（`zh`），同时支持 `--lang en|zh`。
- **支持 `--dry-run` / `-n`**：方便用户在删除前预览影响范围。
- **幂等性**：若某路径或进程已不存在应静默跳过，重复执行不报错。
- **避免过度宽泛的通配符**：使用精确的 Bundle ID 或路径前缀，切勿使用 `*keyword*` 匹配整个 `~/Library/Preferences` 以免误删无关文件。
- **按需请求 `sudo`**：仅在确认存在 `/Library/...` 等系统级路径时调用 `sudo`。
- **交互读取兼容**：脚本可能通过 `bash -c "$(curl ...)"` 运行，读取用户输入时建议使用 `read -r </dev/tty` 并做好非交互回退。

### 4. 提交 PR 检查清单

- [ ] 新增 `<app-name>/uninstall.sh` 并赋予可执行权限（`chmod +x <app-name>/uninstall.sh`）
- [ ] 通过 `bash -n <app-name>/uninstall.sh` 语法检查，并实测 `--dry-run`（含 `--lang en` 与 `--lang zh`）
- [ ] 新增 `<app-name>/README.md`（英文）及可选 `<app-name>/README.zh-CN.md`（中文）
- [ ] 更新根目录 `README.md` 和 `README.zh-CN.md` 中的应用列表

---

## 致谢

- 豆包输入法卸载脚本整理自 [missuo/doubaoime-uninstaller](https://github.com/missuo/doubaoime-uninstaller)

## License

[MIT](LICENSE)
