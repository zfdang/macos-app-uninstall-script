# macOS App Uninstall Scripts

**English** | [简体中文](README.zh-CN.md)

A collection of one-click uninstall scripts to completely remove macOS apps — not only the `.app` bundle, but also `LaunchAgents` / `LaunchDaemons`, background processes, `Application Support`, `Preferences`, `Caches`, `HTTPStorages`, `WebKit`, temporary files, and downloaded installers.

Each subdirectory corresponds to one macOS application and provides a self-contained `uninstall.sh` script. Scripts default to English and automatically switch to Chinese when the macOS system supports Chinese.

---

## Supported Apps

| App | Directory | One-line Command | Description |
|---|---|---|---|
| **Chatterfly (Tencent IME)** | [`chatterfly/`](chatterfly/) | `bash -c "$(curl -fsSL https://raw.githubusercontent.com/zfdang/macos-app-uninstall-script/main/chatterfly/uninstall.sh)"` | Completely remove Chatterfly IME, LaunchAgents, processes, and all leftovers |
| **Doubao IME** | [`doubaoime/`](doubaoime/) | `bash -c "$(curl -fsSL https://raw.githubusercontent.com/zfdang/macos-app-uninstall-script/main/doubaoime/uninstall.sh)"` | Completely remove Doubao IME and all leftovers (adapted from [missuo/doubaoime-uninstaller](https://github.com/missuo/doubaoime-uninstaller)) |

> **Tip:** All scripts support `--dry-run` (`-n`) to preview what will be removed before making any changes, and `--lang en|zh` to override the output language.

---

## Usage

### Option 1: Run directly via `curl` (Recommended)

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/zfdang/macos-app-uninstall-script/main/<app-dir>/uninstall.sh)"
```

Preview items first with `--dry-run`:

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/zfdang/macos-app-uninstall-script/main/<app-dir>/uninstall.sh)" -- --dry-run
```

### Option 2: Clone and run locally

```bash
git clone https://github.com/zfdang/macos-app-uninstall-script.git
cd macos-app-uninstall-script
./<app-dir>/uninstall.sh
```

---

## How to Add a New App Uninstall Script

Pull Requests for new macOS apps are very welcome! Please follow the conventions below.

### 1. Directory Structure

Create a **lowercase, no-spaces** directory for each app (e.g., `wechat/`, `chatterfly/`):

```text
<app-name>/
├── README.md        # English documentation (usage, cleanup scope table, notes)
├── README.zh-CN.md  # Chinese documentation (optional, recommended)
└── uninstall.sh     # One-click uninstall script (executable: chmod +x)
```

### 2. Checklist for Finding All App Files on macOS

Before writing the script, thoroughly inspect everywhere the app installs or writes files:

1. **Application / Input Method Bundle**
   - `/Applications/<App>.app`, `~/Applications/<App>.app`
   - `/Library/Input Methods/<App>.app` (for Input Methods)
2. **Background Services (`LaunchAgents` / `LaunchDaemons`)**
   - `/Library/LaunchAgents/`, `/Library/LaunchDaemons/`
   - `~/Library/LaunchAgents/`, `/Library/PrivilegedHelperTools/`
   - Check active jobs: `launchctl list | grep -i <keyword>`
   - Always unload (`launchctl bootout` / `launchctl unload`) before killing processes or deleting files so `launchd` does not respawn them.
3. **Running Processes**
   - `ps aux | grep -i <keyword>`
4. **User Library (`~/Library`)**
   - `~/Library/Application Support/<App or BundleID>`
   - `~/Library/<BundleID>` (some apps write directly under `~/Library/`)
   - `~/Library/Preferences/<BundleID>*.plist` (also clear `cfprefsd` via `defaults delete <domain>`)
   - `~/Library/Caches/<BundleID>*`
   - `~/Library/HTTPStorages/<BundleID>*`
   - `~/Library/WebKit/<BundleID>*`
   - `~/Library/Containers/<BundleID>*` and `~/Library/Group Containers/<TeamID>.<BundleID>*`
   - `~/Library/Saved Application State/<BundleID>.savedState`
   - `~/Library/Logs/<App or BundleID>`
   - `~/Library/Application Support/com.apple.sharedfilelist/com.apple.LSSharedFileList.ApplicationRecentDocuments/`
5. **Receipts, Plugins & Temp Files**
   - `pkgutil --pkgs | grep -i <keyword>` and `/private/var/db/receipts/`
   - `/Library/QuickLook/`, `~/Library/QuickLook/`
   - `$TMPDIR` (`getconf DARWIN_USER_TEMP_DIR`) and installer packages in `~/Downloads/`
6. **Input Method Specifics**
   - Check `defaults read com.apple.HIToolbox AppleEnabledInputSources` and prompt the user to remove the input source in **System Settings → Keyboard → Input Sources**.
7. **Pro Tips**
   - Inspect `Contents/Info.plist` of the main `.app` and any embedded `.app` helpers to discover all bundle identifiers.
   - If the installer includes a built-in helper or uninstaller binary, check `strings` on it, and run `find /Library ~/Library -maxdepth 4 -iname "*<keyword>*"` on a live system to catch undocumented leftovers.

### 3. Script Guidelines

- **Shebang & safety flags**: Use `#!/usr/bin/env bash` and `set -euo pipefail` (compatible with macOS default Bash 3.2).
- **Bilingual output**: Default to English (`en`), auto-switch to Chinese (`zh`) when the system supports Chinese (`LC_ALL`/`LANG` or `defaults read -g AppleLanguages`), and support `--lang en|zh`.
- **Dry-run support**: Support `--dry-run` / `-n` so users can inspect every action beforehand.
- **Idempotent**: Skip missing files/processes silently without errors.
- **Avoid overly broad globs**: Match exact bundle IDs or prefixes; never use loose globs like `*keyword*` across `~/Library/Preferences` that could delete unrelated files.
- **On-demand `sudo`**: Only invoke `sudo` when system-level paths actually exist.
- **TTY-safe prompts**: Read interactive input from `/dev/tty` with a non-interactive fallback so `bash -c "$(curl ...)"` works reliably.

### 4. PR Checklist

- [ ] Add `<app-name>/uninstall.sh` with executable permission (`chmod +x <app-name>/uninstall.sh`)
- [ ] Pass `bash -n <app-name>/uninstall.sh` syntax check and verify `--dry-run` (both `--lang en` and `--lang zh`)
- [ ] Add `<app-name>/README.md` (English default) and optionally `<app-name>/README.zh-CN.md`
- [ ] Update the **Supported Apps** table in the root `README.md` and `README.zh-CN.md`

---

## Acknowledgements

- Doubao IME uninstaller is adapted from [missuo/doubaoime-uninstaller](https://github.com/missuo/doubaoime-uninstaller)

## License

[MIT](LICENSE)
