#!/usr/bin/env bash
# Adapted from https://github.com/missuo/doubaoime-uninstaller (MIT License)

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

echo ""
echo "=================================="
echo "  $(msg "Doubao IME Uninstaller" "豆包输入法卸载工具")"
echo "=================================="
if $DRY_RUN; then
    echo -e "  ${BLUE}$(msg "Mode: Dry Run (preview only, no changes made)" "运行模式: Dry Run（仅预览，不执行删除）")${NC}"
fi
echo ""

# Step 1: Remove input source
echo -e "${YELLOW}[1/5]${NC} $(msg "Checking enabled input sources..." "移除输入法源...")"
if defaults read com.apple.HIToolbox AppleEnabledInputSources 2>/dev/null | grep -qi "doubaoime"; then
    echo "  $(msg "Please remove Doubao IME in System Settings -> Keyboard -> Input Sources." "请手动前往 系统设置 → 键盘 → 输入法 移除豆包输入法")"
    if ! $DRY_RUN; then
        if [ -r /dev/tty ] && [ -t 1 ]; then
            echo -e "  ${YELLOW}$(msg "Press Enter to continue after removing..." "移除后按回车继续...")${NC}"
            read -r </dev/tty || true
        else
            echo -e "  ${YELLOW}$(msg "Non-interactive mode: continuing cleanup (please log out or restart afterward)." "非交互模式：继续执行后续清理（完成后请注销或重启）。")${NC}"
        fi
    fi
else
    echo -e "  ${GREEN}$(msg "No enabled Doubao IME input source detected, skipping." "未检测到已启用的豆包输入法源，跳过")${NC}"
fi

# Step 2: Kill processes
echo -e "${YELLOW}[2/5]${NC} $(msg "Terminating Doubao IME processes..." "终止豆包输入法进程...")"
for proc in DoubaoIme DoubaoImeSettings DoubaoImeInstaller; do
    if pgrep -x "$proc" >/dev/null 2>&1; then
        if $DRY_RUN; then
            echo -e "  ${BLUE}[dry-run]${NC} $(msg "Terminate process: " "终止进程: ")$proc"
        else
            killall "$proc" 2>/dev/null && echo "  $(msg "Terminated: " "已终止 ")$proc" || true
        fi
    fi
done
echo -e "  ${GREEN}$(msg "Process cleanup complete." "进程清理完成")${NC}"

# Step 3: Remove main app (requires sudo)
echo -e "${YELLOW}[3/5]${NC} $(msg "Removing input method app..." "移除输入法主程序...")"
if [ -d "/Library/Input Methods/DoubaoIme.app" ]; then
    if $DRY_RUN; then
        echo -e "  ${BLUE}[dry-run]${NC} sudo rm -rf \"/Library/Input Methods/DoubaoIme.app\""
    else
        sudo rm -rf "/Library/Input Methods/DoubaoIme.app"
        echo -e "  ${GREEN}$(msg "Removed /Library/Input Methods/DoubaoIme.app" "已移除 /Library/Input Methods/DoubaoIme.app")${NC}"
    fi
else
    echo -e "  ${GREEN}$(msg "Main app not found, skipping." "主程序已不存在，跳过")${NC}"
fi

# Step 4: Remove user-level files
echo -e "${YELLOW}[4/5]${NC} $(msg "Cleaning user data..." "清理用户数据...")"

files=(
    "$HOME/Library/Application Support/DoubaoIme"
    "$HOME/Library/Preferences/com.bytedance.inputmethod.doubaoime.plist"
    "$HOME/Library/Preferences/com.bytedance.inputmethod.doubaoime.installer.plist"
    "$HOME/Library/Preferences/com.bytedance.inputmethod.doubaoime.settings.plist"
    "$HOME/Library/Caches/com.bytedance.inputmethod.doubaoime"
    "$HOME/Library/Caches/com.bytedance.inputmethod.doubaoime.installer"
    "$HOME/Library/Caches/com.bytedance.inputmethod.doubaoime.settings"
    "$HOME/Library/HTTPStorages/com.bytedance.inputmethod.doubaoime"
    "$HOME/Library/HTTPStorages/com.bytedance.inputmethod.doubaoime.installer"
    "$HOME/Library/HTTPStorages/com.bytedance.inputmethod.doubaoime.settings"
    "$HOME/Library/Saved Application State/com.bytedance.inputmethod.doubaoime.savedState"
    "$HOME/Library/Saved Application State/com.bytedance.inputmethod.doubaoime.installer.savedState"
    "$HOME/Library/Saved Application State/com.bytedance.inputmethod.doubaoime.settings.savedState"
)

removed=0
for f in "${files[@]}"; do
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

if [ "$removed" -eq 0 ]; then
    echo -e "  ${GREEN}$(msg "User data already clean, nothing to do." "用户数据已清理过，无需操作")${NC}"
else
    echo -e "  ${GREEN}$(msg "Cleaned $removed item(s)." "已清理 $removed 个项目")${NC}"
fi

# Step 5: Clean up installer in Downloads
echo -e "${YELLOW}[5/5]${NC} $(msg "Cleaning installer packages in Downloads..." "清理下载目录中的安装包...")"
installer_removed=0
shopt -s nullglob
for f in "$HOME/Downloads"/DoubaoImeInstaller*; do
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
echo "=================================="
if $DRY_RUN; then
    echo -e "  ${BLUE}$(msg "Dry Run complete. No changes were made." "Dry Run 预览完成，未对系统做任何修改")${NC}"
else
    echo -e "  ${GREEN}$(msg "Doubao IME has been completely uninstalled!" "豆包输入法已彻底卸载！")${NC}"
    echo "  $(msg "Please log out or restart your Mac to ensure all changes take effect." "建议注销或重启 Mac 以确保完全生效")"
fi
echo "=================================="
echo ""
