# Doubao IME Uninstaller

**English** | [简体中文](README.zh-CN.md)

One-click script to completely uninstall Doubao IME (`DoubaoIme`) and remove all residual files on macOS.

> Adapted from [missuo/doubaoime-uninstaller](https://github.com/missuo/doubaoime-uninstaller) (MIT License).

## Usage

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/zfdang/macos-app-uninstall-script/main/doubaoime/uninstall.sh)"
```

Preview items to be removed without modifying your system (`--dry-run`):

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/zfdang/macos-app-uninstall-script/main/doubaoime/uninstall.sh)" -- --dry-run
```

Force output language (`en` or `zh`; defaults to `en` and auto-switches to `zh` if the system supports Chinese):

```bash
./doubaoime/uninstall.sh --lang en
./doubaoime/uninstall.sh --lang zh
```

Or clone the repository and run locally:

```bash
git clone https://github.com/zfdang/macos-app-uninstall-script.git
cd macos-app-uninstall-script
./doubaoime/uninstall.sh
```

## Cleanup Scope

| Category | Paths / Targets |
|---|---|
| Running Processes | `DoubaoIme`, `DoubaoImeSettings`, `DoubaoImeInstaller` |
| Main App Bundle | `/Library/Input Methods/DoubaoIme.app` |
| App Data & Logs | `~/Library/Application Support/DoubaoIme/` |
| Preferences | `~/Library/Preferences/com.bytedance.inputmethod.doubaoime*.plist` |
| Caches | `~/Library/Caches/com.bytedance.inputmethod.doubaoime*` |
| HTTP Storages | `~/Library/HTTPStorages/com.bytedance.inputmethod.doubaoime*` |
| Saved Application State | `~/Library/Saved Application State/com.bytedance.inputmethod.doubaoime*.savedState` |
| Downloaded Installers | `~/Downloads/DoubaoImeInstaller*` |

## Notes

- Removing `/Library/Input Methods/DoubaoIme.app` requires administrator privileges (`sudo`), which the script will request automatically when needed.
- Logging out or restarting your Mac after uninstallation is recommended.
