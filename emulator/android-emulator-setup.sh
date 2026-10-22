#!/usr/bin/env bash
set -e

DOTFILES_BIN="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LAUNCHER="$DOTFILES_BIN/android-emulator-start-pixel-7.sh"

echo "=================================================="
echo "    正在自动化安装与配置 Android Emulator (AVD)    "
echo "=================================================="

# 1. 检查 yay 是否存在
if ! command -v yay &>/dev/null; then
    echo "❌ 错误: 未检测到 yay 包管理器"
    exit 1
fi

# 2. 检查并安装核心包 (需要 sudo 权限确认)
if pacman -Q android-sdk-cmdline-tools-latest android-emulator android-tools jdk17-openjdk &>/dev/null; then
    echo "✅ 核心组件已全部安装，跳过包安装步骤..."
else
    echo "📦 正在刷新软件源并安装基础依赖 (android-tools, jdk17-openjdk)..."
    sudo pacman -Sy --needed --noconfirm android-tools jdk17-openjdk

    # 如果 yay 缓存中已经构建好了包，直接使用 pacman -U 安装，避免 yay 的依赖标记 bug
    CACHED_CMDLINE=$(ls -t ~/.cache/yay/android-sdk-cmdline-tools-latest/android-sdk-cmdline-tools-latest-[0-9]*.pkg.tar.zst 2>/dev/null | grep -v 'debug' | head -n 1 || true)
    CACHED_EMULATOR=$(ls -t ~/.cache/yay/android-emulator/android-emulator-[0-9]*.pkg.tar.zst 2>/dev/null | grep -v 'debug' | head -n 1 || true)

    if [ -n "$CACHED_CMDLINE" ] && [ -n "$CACHED_EMULATOR" ]; then
        echo "⚡ 发现 yay 已经预先构建好的安装包，直接安装..."
        sudo pacman -U --needed --noconfirm "$CACHED_CMDLINE" "$CACHED_EMULATOR"
    else
        echo "📦 正在通过 yay 安装剩余组件..."
        yay -S --needed --noconfirm android-sdk-cmdline-tools-latest android-emulator
    fi
fi

# 3. 确定目标用户并修复 /opt/android-sdk 权限，方便后续下载镜像与更新
TARGET_USER="${SUDO_USER:-$USER}"
TARGET_HOME=$(getent passwd "$TARGET_USER" | cut -d: -f6)
echo "🔑 正在为用户 $TARGET_USER 设置 /opt/android-sdk 写入权限..."
sudo chown -R "$TARGET_USER:$TARGET_USER" /opt/android-sdk

# 4. 配置临时环境变量用于执行当前脚本
export ANDROID_HOME=/opt/android-sdk
export ANDROID_SDK_ROOT=/opt/android-sdk
export PATH=$PATH:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/emulator:$ANDROID_HOME/platform-tools

# 5. 自动接受 Google 许可协议
echo "📜 正在同意 Google Android SDK 许可协议..."
yes | sdkmanager --licenses >/dev/null 2>&1 || true

# 6. 下载 Android 11 Google APIs 镜像（带 libndk_translation，能安装仅含 ARM 原生库的 APK）
IMG="system-images;android-30;google_apis;x86_64"
echo "📥 正在下载系统镜像: $IMG ..."
sdkmanager "$IMG"

# 7. 创建虚拟设备 AVD (型号: Google Pixel 7)
AVD_NAME="pixel_7"
DEVICE_PROFILE="pixel_7"
echo "📱 正在为用户 $TARGET_USER 创建虚拟设备: $AVD_NAME (Google Pixel 7)..."
if [ -n "$SUDO_USER" ] && [ "$SUDO_USER" != "root" ]; then
    sudo -u "$TARGET_USER" bash -c "export ANDROID_HOME=/opt/android-sdk ANDROID_SDK_ROOT=/opt/android-sdk PATH=\$PATH:\$ANDROID_HOME/cmdline-tools/latest/bin:\$ANDROID_HOME/emulator:\$ANDROID_HOME/platform-tools; echo 'no' | avdmanager create avd -n '$AVD_NAME' -d '$DEVICE_PROFILE' -k '$IMG' --force"
else
    echo "no" | avdmanager create avd -n "$AVD_NAME" -d "$DEVICE_PROFILE" -k "$IMG" --force
fi

# 8. 优化虚拟机配置 (核显、3G 内存、2核、720x1600)
CONFIG_FILE="$TARGET_HOME/.android/avd/${AVD_NAME}.avd/config.ini"
if [ -f "$CONFIG_FILE" ]; then
    echo "⚙️ 正在优化虚拟设备配置 (核显、3G 内存、2核 CPU、720x1600)..."
    sed -i '/^hw.camera.back/d' "$CONFIG_FILE"
    sed -i '/^hw.ramSize/d' "$CONFIG_FILE"
    sed -i '/^hw.cpu.ncore/d' "$CONFIG_FILE"
    sed -i '/^hw.keyboard/d' "$CONFIG_FILE"
    sed -i '/^hw.gpu.enabled/d' "$CONFIG_FILE"
    sed -i '/^hw.gpu.mode/d' "$CONFIG_FILE"
    sed -i '/^hw.lcd.density/d' "$CONFIG_FILE"
    sed -i '/^hw.lcd.height/d' "$CONFIG_FILE"
    sed -i '/^hw.lcd.width/d' "$CONFIG_FILE"
    sed -i '/^showDeviceFrame/d' "$CONFIG_FILE"
    sed -i '/^skin.name/d' "$CONFIG_FILE"
    sed -i '/^skin.dynamic/d' "$CONFIG_FILE"
    cat << 'CFG' >> "$CONFIG_FILE"
hw.camera.back=webcam0
hw.ramSize=3072
hw.cpu.ncore=2
hw.keyboard=yes
hw.gpu.enabled=yes
hw.gpu.mode=host
hw.lcd.density=320
hw.lcd.height=1600
hw.lcd.width=720
showDeviceFrame=no
skin.name=720x1600
skin.dynamic=yes
CFG
fi

# 9. 桌面快捷方式指向仓库里的启动脚本
chmod +x "$LAUNCHER"
mkdir -p "$TARGET_HOME/.local/share/applications"
DESKTOP_FILE="$TARGET_HOME/.local/share/applications/pixel-7-emulator.desktop"
cat << EOF > "$DESKTOP_FILE"
[Desktop Entry]
Name=Pixel 7 (Android 模拟器)
Comment=Android Emulator running Google Pixel 7
Exec=$LAUNCHER
Icon=android
Terminal=false
Type=Application
Categories=Development;System;
EOF
if [ -n "$SUDO_USER" ] && [ "$SUDO_USER" != "root" ]; then
    chown "$TARGET_USER:$TARGET_USER" "$DESKTOP_FILE"
fi

echo ""
echo "=================================================="
echo "🎉 安装与配置已全部完成！"
echo "👉 后续启动模拟器，只需运行："
echo "   $LAUNCHER"
echo "   （也可以直接在应用启动器中搜索「Pixel 7」启动）"
echo "=================================================="
