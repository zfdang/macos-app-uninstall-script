# 豆包输入法卸载工具

[English](README.md) | **简体中文**

一键彻底卸载豆包输入法（`DoubaoIme`），清除所有残留文件。

> 本目录脚本参考并整理自 [missuo/doubaoime-uninstaller](https://github.com/missuo/doubaoime-uninstaller)（MIT License）。

## 使用方法

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/zfdang/macos-app-uninstall-script/main/doubaoime/uninstall.sh)"
```

先预览待删除项（Dry Run，不执行删除）：

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/zfdang/macos-app-uninstall-script/main/doubaoime/uninstall.sh)" -- --dry-run
```

手动指定输出语言（缺省为英文，系统支持中文时自动显示中文）：

```bash
./doubaoime/uninstall.sh --lang en
./doubaoime/uninstall.sh --lang zh
```

或者克隆仓库后运行：

```bash
git clone https://github.com/zfdang/macos-app-uninstall-script.git
cd macos-app-uninstall-script
./doubaoime/uninstall.sh
```

## 清理范围

| 类别 | 路径 |
|------|------|
| 运行中进程 | `DoubaoIme`、`DoubaoImeSettings`、`DoubaoImeInstaller` |
| 输入法主程序 | `/Library/Input Methods/DoubaoIme.app` |
| 应用数据与日志 | `~/Library/Application Support/DoubaoIme/` |
| 偏好设置 | `~/Library/Preferences/com.bytedance.inputmethod.doubaoime*.plist` |
| 缓存 | `~/Library/Caches/com.bytedance.inputmethod.doubaoime*` |
| HTTP 存储 | `~/Library/HTTPStorages/com.bytedance.inputmethod.doubaoime*` |
| 保存的应用状态 | `~/Library/Saved Application State/com.bytedance.inputmethod.doubaoime*.savedState` |
| 下载的安装包 | `~/Downloads/DoubaoImeInstaller*` |

## 注意事项

- 删除 `/Library/Input Methods/DoubaoIme.app` 需要管理员权限（`sudo`），脚本会自动请求
- 卸载完成后建议注销或重启 Mac
