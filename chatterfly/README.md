# Chatterfly Uninstaller

**English** | [简体中文](README.zh-CN.md)

One-click script to completely uninstall Tencent Chatterfly IME (`com.tencent.inputmethod.chatterfly`), stop its background LaunchAgents, and remove all system- and user-level leftover files on macOS.

## Usage

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/zfdang/macos-app-uninstall-script/main/chatterfly/uninstall.sh)"
```

Preview items to be removed without modifying your system (`--dry-run`):

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/zfdang/macos-app-uninstall-script/main/chatterfly/uninstall.sh)" -- --dry-run
```

Force output language (`en` or `zh`; defaults to `en` and auto-switches to `zh` if the system supports Chinese):

```bash
./chatterfly/uninstall.sh --lang en
./chatterfly/uninstall.sh --lang zh
```

Or clone the repository and run locally:

```bash
git clone https://github.com/zfdang/macos-app-uninstall-script.git
cd macos-app-uninstall-script
./chatterfly/uninstall.sh
```

## Cleanup Scope

| Category | Paths / Targets |
|---|---|
| Background Services (`LaunchAgents`) | `/Library/LaunchAgents/com.tencent.ChatterflyServices.plist`<br>`/Library/LaunchAgents/com.tencent.ChatterflyTaskManager.plist`<br>`~/Library/LaunchAgents/com.tencent.ChatterflyTaskManager.plist` |
| Running Processes | `Chatterfly`, `ChatterflyPreference`, `ChatterflyTaskManager`, `ChatterflyServices`, `ChatterflyHelper`, `ChatterflyInstaller`, `ChatterflyXdelta` |
| Main App Bundle | `/Library/Input Methods/Chatterfly.app` |
| Application Support | `~/Library/Application Support/Chatterfly/`<br>`~/Library/Application Support/com.tencent.inputmethod.chatterfly/`<br>`~/Library/Application Support/com.tencent.ChatterflyTaskManager/`<br>`~/Library/Application Support/com.tencent.ChatterflyPreference/`<br>`~/Library/Application Support/com.tencent.ChatterflyInstaller/` |
| `~/Library` Root Data (RaftMonitor) | `~/Library/com.tencent.inputmethod.chatterfly/`<br>`~/Library/com.tencent.ChatterflyTaskManager/`<br>`~/Library/com.tencent.ChatterflyPreference/` |
| Preferences & `defaults` Domains | `~/Library/Preferences/com.tencent.inputmethod.chatterfly.plist`<br>`~/Library/Preferences/com.tencent.ChatterflyPreference.plist`<br>`~/Library/Preferences/com.tencent.ChatterflyTaskManager.plist`<br>`~/Library/Preferences/com.tencent.ChatterflyInstaller.plist`<br>`~/Library/Preferences/ChatterflyServices.plist` |
| Caches | `~/Library/Caches/com.tencent.inputmethod.chatterfly`<br>`~/Library/Caches/com.tencent.ChatterflyTaskManager`<br>`~/Library/Caches/com.tencent.ChatterflyPreference`<br>`~/Library/Caches/ChatterflyServices`<br>`~/Library/Caches/com.tencent.ChatterflyInstaller`<br>`~/Library/Caches/com.tencent.yuanbao.installType` (only removed when `/Applications/Yuanbao.app` is not present) |
| HTTP Storages | `~/Library/HTTPStorages/com.tencent.inputmethod.chatterfly`<br>`~/Library/HTTPStorages/com.tencent.ChatterflyTaskManager`<br>`~/Library/HTTPStorages/com.tencent.ChatterflyPreference`<br>`~/Library/HTTPStorages/ChatterflyServices`<br>`~/Library/HTTPStorages/com.tencent.ChatterflyInstaller` |
| WebKit Data | `~/Library/WebKit/com.tencent.ChatterflyInstaller` |
| Saved Application State | `~/Library/Saved Application State/com.tencent.inputmethod.chatterfly.savedState`<br>`~/Library/Saved Application State/com.tencent.ChatterflyPreference.savedState`<br>`~/Library/Saved Application State/com.tencent.ChatterflyTaskManager.savedState`<br>`~/Library/Saved Application State/com.tencent.ChatterflyInstaller.savedState` |
| Recent Documents | `~/Library/Application Support/com.apple.sharedfilelist/.../com.tencent.chatterfly*.sfl*` |
| Temp Directory (`$TMPDIR`) | `$TMPDIR/com.tencent.chatterfly`<br>`$TMPDIR/com.tencent.ChatterflyInstaller` |
| Downloaded Installers | `~/Downloads/Chatterfly_V*.app`, `~/Downloads/Chatterfly_V*.zip`, `~/Downloads/Chatterfly_V*.dmg`, `~/Downloads/ChatterflyInstaller*` |

## Notes

- LaunchAgents are unloaded via `launchctl bootout` / `unload` before killing processes so `ChatterflyServices` (`StartInterval: 3`) is not immediately respawned by `launchd`.
- Removing `/Library/Input Methods/Chatterfly.app` and `/Library/LaunchAgents/com.tencent.Chatterfly*.plist` requires administrator privileges (`sudo`), which is only requested when system-level targets exist.
- Logging out or restarting macOS after uninstallation is recommended to fully clear cached input method state.
