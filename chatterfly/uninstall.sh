#!/usr/bin/env bash

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

DRY_RUN=false
LANG_OVERRIDE=""

detect_lang() {
    if [ -n "$LANG_OVERRIDE" ]; then
        echo "$LANG_OVERRIDE"
        return
    fi

    local locale_val="${LC_ALL:-${LC_MESSAGES:-${LANG:-}}}"
    case "$locale_val" in
        zh*|ZH*)
            echo "zh"
            return
            ;;
    esac

    if defaults read -g AppleLanguages 2>/dev/null | grep -qi "zh"; then
        echo "zh"
        return
    fi

    echo "en"
}

while [ $# -gt 0 ]; do
    case "$1" in
        --dry-run|-n)
            DRY_RUN=true
            ;;
        --lang)
            shift
            if [ $# -eq 0 ]; then
                echo "Missing value for --lang (expected: en or zh)" >&2
                exit 1
            fi
            case "$1" in
                en|zh) LANG_OVERRIDE="$1" ;;
                *)
                    echo "Unsupported language: $1 (expected: en or zh)" >&2
                    exit 1
                    ;;
            esac
            ;;
        --lang=*)
            val="${1#--lang=}"
            case "$val" in
                en|zh) LANG_OVERRIDE="$val" ;;
                *)
                    echo "Unsupported language: $val (expected: en or zh)" >&2
                    exit 1
                    ;;
            esac
            ;;
        --help|-h)
            echo "Usage: $0 [--dry-run|-n] [--lang en|zh] [--help|-h]"
            echo "  --dry-run, -n   Preview items to be removed without making changes"
            echo "  --lang en|zh    Force output language (default: auto-detect, fallback en)"
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}" >&2
            exit 1
            ;;
    esac
    shift
done

UI_LANG="$(detect_lang)"

msg() {
    if [ "$UI_LANG" = "zh" ]; then
        printf '%s' "$2"
    else
        printf '%s' "$1"
    fi
}

run_quiet() {
    if $DRY_RUN; then
        echo -e "  ${BLUE}[dry-run]${NC} $*"
    else
        "$@" >/dev/null 2>&1 || true
    fi
}

echo ""
echo "=========================================="
echo "  $(msg "Chatterfly Uninstaller" "Chatterfly 卸载工具")"
echo "=========================================="
if $DRY_RUN; then
    echo -e "  ${BLUE}$(msg "Mode: Dry Run (preview only, no changes made)" "运行模式: Dry Run（仅预览，不执行删除）")${NC}"
fi
echo ""

# Step 1: Check enabled input source
echo -e "${YELLOW}[1/6]${NC} $(msg "Checking enabled input sources..." "检查输入法启用状态...")"
if defaults read com.apple.HIToolbox AppleEnabledInputSources 2>/dev/null | grep -qi "chatterfly"; then
    echo "  $(msg "Chatterfly input source is currently enabled." "检测到已启用 Chatterfly 输入法。")"
    echo "  $(msg "Please remove Chatterfly in System Settings -> Keyboard -> Input Sources." "请先前往 系统设置 → 键盘 → 输入法 移除 Chatterfly。")"
    if ! $DRY_RUN; then
        if [ -r /dev/tty ] && [ -t 1 ]; then
            echo -e "  ${YELLOW}$(msg "Press Enter to continue after removing..." "移除后按回车继续...")${NC}"
            read -r </dev/tty || true
        else
            echo -e "  ${YELLOW}$(msg "Non-interactive mode: continuing cleanup (please log out or restart afterward)." "非交互模式：继续执行后续清理（完成后请注销或重启）。")${NC}"
        fi
    fi
else
    echo -e "  ${GREEN}$(msg "No enabled Chatterfly input source detected, skipping." "未检测到已启用的 Chatterfly 输入法源，跳过")${NC}"
fi

# Step 2: Unload LaunchAgents before killing processes so launchd does not respawn them
echo -e "${YELLOW}[2/6]${NC} $(msg "Unloading LaunchAgents background services..." "卸载 LaunchAgents 后台服务...")"
USER_UID=$(id -u)
launch_labels=(
    "com.tencent.ChatterflyServices"
    "com.tencent.ChatterflyTaskManager"
)
launch_plists=(
    "/Library/LaunchAgents/com.tencent.ChatterflyServices.plist"
    "/Library/LaunchAgents/com.tencent.ChatterflyTaskManager.plist"
    "$HOME/Library/LaunchAgents/com.tencent.ChatterflyTaskManager.plist"
)

unloaded=0
for label in "${launch_labels[@]}"; do
    if launchctl print "gui/${USER_UID}/${label}" >/dev/null 2>&1; then
        run_quiet launchctl bootout "gui/${USER_UID}/${label}"
        if ! $DRY_RUN; then
            echo "  $(msg "Stopped service: " "已停止服务: ")$label"
        fi
        unloaded=$((unloaded + 1))
    fi
done

for plist in "${launch_plists[@]}"; do
    if [ -e "$plist" ]; then
        run_quiet launchctl unload "$plist"
    fi
done

if [ "$unloaded" -eq 0 ]; then
    echo -e "  ${GREEN}$(msg "No active Chatterfly LaunchAgents found." "未检测到活跃的 Chatterfly LaunchAgents")${NC}"
else
    echo -e "  ${GREEN}$(msg "Background services stopped." "后台服务已停止")${NC}"
fi

# Step 3: Terminate processes
echo -e "${YELLOW}[3/6]${NC} $(msg "Terminating Chatterfly processes..." "终止 Chatterfly 相关进程...")"
processes=(
    "Chatterfly"
    "ChatterflyPreference"
    "ChatterflyTaskManager"
    "ChatterflyServices"
    "ChatterflyHelper"
    "ChatterflyInstaller"
    "ChatterflyXdelta"
)

killed=0
for proc in "${processes[@]}"; do
    if pgrep -x "$proc" >/dev/null 2>&1; then
        if $DRY_RUN; then
            echo -e "  ${BLUE}[dry-run]${NC} $(msg "Terminate process: " "终止进程: ")$proc"
        else
            killall "$proc" 2>/dev/null || true
            sleep 0.2
            killall -9 "$proc" 2>/dev/null || true
            echo "  $(msg "Terminated: " "已终止: ")$proc"
        fi
        killed=$((killed + 1))
    fi
done

if [ "$killed" -eq 0 ]; then
    echo -e "  ${GREEN}$(msg "No running Chatterfly processes found." "无运行中的 Chatterfly 进程")${NC}"
else
    echo -e "  ${GREEN}$(msg "Process cleanup complete." "进程清理完成")${NC}"
fi

# Step 4: Remove system-level app, LaunchAgents, and root-owned markers (requires sudo)
echo -e "${YELLOW}[4/6]${NC} $(msg "Removing input method app and system-level files..." "移除输入法主程序与系统级配置...")"
system_targets=(
    "/Library/Input Methods/Chatterfly.app"
    "/Library/LaunchAgents/com.tencent.ChatterflyServices.plist"
    "/Library/LaunchAgents/com.tencent.ChatterflyTaskManager.plist"
)

# Installer creates root-owned com.tencent.yuanbao.installType in Caches;
# only remove it if Tencent Yuanbao desktop app is not installed.
if [ ! -d "/Applications/Yuanbao.app" ] && [ -e "$HOME/Library/Caches/com.tencent.yuanbao.installType" ]; then
    system_targets+=("$HOME/Library/Caches/com.tencent.yuanbao.installType")
fi

sys_removed=0
for target in "${system_targets[@]}"; do
    if [ -e "$target" ]; then
        if $DRY_RUN; then
            echo -e "  ${BLUE}[dry-run]${NC} sudo rm -rf \"$target\""
        else
            sudo rm -rf "$target"
            echo "  $(msg "Removed: " "已移除: ")$target"
        fi
        sys_removed=$((sys_removed + 1))
    fi
done

if [ "$sys_removed" -eq 0 ]; then
    echo -e "  ${GREEN}$(msg "No system-level files found, skipping." "系统级文件已不存在，跳过")${NC}"
else
    echo -e "  ${GREEN}$(msg "System-level cleanup complete ($sys_removed item(s))." "系统级文件清理完成（共 $sys_removed 项）")${NC}"
fi

# Step 5: Remove user-level files, preferences, caches, and temp directories
echo -e "${YELLOW}[5/6]${NC} $(msg "Cleaning user data, preferences, and caches..." "清理用户数据、偏好设置与缓存...")"

user_targets=(
    "$HOME/Library/Application Support/Chatterfly"
    "$HOME/Library/Application Support/com.tencent.inputmethod.chatterfly"
    "$HOME/Library/Application Support/com.tencent.ChatterflyTaskManager"
    "$HOME/Library/Application Support/com.tencent.ChatterflyPreference"
    "$HOME/Library/Application Support/com.tencent.ChatterflyInstaller"
    "$HOME/Library/com.tencent.inputmethod.chatterfly"
    "$HOME/Library/com.tencent.ChatterflyTaskManager"
    "$HOME/Library/com.tencent.ChatterflyPreference"
    "$HOME/Library/LaunchAgents/com.tencent.ChatterflyTaskManager.plist"
    "$HOME/Library/Preferences/com.tencent.inputmethod.chatterfly.plist"
    "$HOME/Library/Preferences/com.tencent.ChatterflyPreference.plist"
    "$HOME/Library/Preferences/com.tencent.ChatterflyTaskManager.plist"
    "$HOME/Library/Preferences/com.tencent.ChatterflyInstaller.plist"
    "$HOME/Library/Preferences/ChatterflyServices.plist"
    "$HOME/Library/Caches/com.tencent.inputmethod.chatterfly"
    "$HOME/Library/Caches/com.tencent.ChatterflyTaskManager"
    "$HOME/Library/Caches/com.tencent.ChatterflyPreference"
    "$HOME/Library/Caches/ChatterflyServices"
    "$HOME/Library/Caches/com.tencent.ChatterflyInstaller"
    "$HOME/Library/HTTPStorages/com.tencent.inputmethod.chatterfly"
    "$HOME/Library/HTTPStorages/com.tencent.ChatterflyTaskManager"
    "$HOME/Library/HTTPStorages/com.tencent.ChatterflyPreference"
    "$HOME/Library/HTTPStorages/ChatterflyServices"
    "$HOME/Library/HTTPStorages/com.tencent.ChatterflyInstaller"
    "$HOME/Library/WebKit/com.tencent.ChatterflyInstaller"
    "$HOME/Library/Saved Application State/com.tencent.inputmethod.chatterfly.savedState"
    "$HOME/Library/Saved Application State/com.tencent.ChatterflyPreference.savedState"
    "$HOME/Library/Saved Application State/com.tencent.ChatterflyTaskManager.savedState"
    "$HOME/Library/Saved Application State/com.tencent.ChatterflyInstaller.savedState"
)

user_tmp="${TMPDIR:-/tmp}"
user_tmp="${user_tmp%/}"
user_targets+=(
    "${user_tmp}/com.tencent.chatterfly"
    "${user_tmp}/com.tencent.ChatterflyInstaller"
)

# Recent documents entries for ChatterflyPreference
shopt -s nullglob
for sfl in "$HOME/Library/Application Support/com.apple.sharedfilelist/com.apple.LSSharedFileList.ApplicationRecentDocuments"/com.tencent.chatterfly*.sfl*; do
    user_targets+=("$sfl")
done
shopt -u nullglob

removed=0
for f in "${user_targets[@]}"; do
    if [ -e "$f" ]; then
        if $DRY_RUN; then
            echo -e "  ${BLUE}[dry-run]${NC} rm -rf \"$f\""
        else
            rm -rf "$f"
            echo "  $(msg "Removed: " "已移除: ")$f"
        fi
        removed=$((removed + 1))
    fi
done

# Clear cfprefsd preference domains
defaults_domains=(
    "com.tencent.inputmethod.chatterfly"
    "com.tencent.ChatterflyPreference"
    "com.tencent.ChatterflyTaskManager"
    "com.tencent.ChatterflyInstaller"
    "ChatterflyServices"
)
for domain in "${defaults_domains[@]}"; do
    if defaults read "$domain" >/dev/null 2>&1; then
        if $DRY_RUN; then
            echo -e "  ${BLUE}[dry-run]${NC} defaults delete \"$domain\""
        else
            defaults delete "$domain" >/dev/null 2>&1 || true
            echo "  $(msg "Deleted defaults domain: " "已清除 defaults 域: ")$domain"
        fi
        removed=$((removed + 1))
    fi
done

if [ "$removed" -eq 0 ]; then
    echo -e "  ${GREEN}$(msg "User data already clean, nothing to do." "用户数据已清理过，无需操作")${NC}"
else
    echo -e "  ${GREEN}$(msg "Cleaned $removed user item(s)." "已清理 $removed 个项目")${NC}"
fi

# Step 6: Clean up installer packages in Downloads
echo -e "${YELLOW}[6/6]${NC} $(msg "Cleaning installer packages in Downloads..." "清理下载目录中的安装包...")"
installer_removed=0
shopt -s nullglob
for f in \
    "$HOME/Downloads"/Chatterfly_V*.app \
    "$HOME/Downloads"/Chatterfly_V*.zip \
    "$HOME/Downloads"/Chatterfly_V*.dmg \
    "$HOME/Downloads"/ChatterflyInstaller*; do
    if [ -e "$f" ]; then
        if $DRY_RUN; then
            echo -e "  ${BLUE}[dry-run]${NC} rm -rf \"$f\""
        else
            rm -rf "$f"
            echo "  $(msg "Removed: " "已移除: ")$f"
        fi
        installer_removed=$((installer_removed + 1))
    fi
done
shopt -u nullglob

if [ "$installer_removed" -eq 0 ]; then
    echo -e "  ${GREEN}$(msg "No installer leftovers found." "未发现安装包残留")${NC}"
else
    echo -e "  ${GREEN}$(msg "Cleaned $installer_removed installer item(s)." "已清理 $installer_removed 个安装包文件")${NC}"
fi

echo ""
echo "=========================================="
if $DRY_RUN; then
    echo -e "  ${BLUE}$(msg "Dry Run complete. No changes were made." "Dry Run 预览完成，未对系统做任何修改")${NC}"
else
    echo -e "  ${GREEN}$(msg "Chatterfly has been completely uninstalled!" "Chatterfly 已彻底卸载！")${NC}"
    echo "  $(msg "Please log out or restart your Mac to ensure all changes take effect." "建议注销或重启 Mac 以确保完全生效")"
fi
echo "=========================================="
echo ""
