#!/usr/bin/env bash
set -e

SCRIPT_PATH="$(readlink -f "${BASH_SOURCE[0]}")"

# 1. 自动补全 SDK 结构 (补充缺失的 platform-tools 软链接，避免 Broken AVD 报错)
USER_SDK="$HOME/.android/sdk"
if [ ! -d "/opt/android-sdk/platform-tools" ]; then
    mkdir -p "$USER_SDK/platform-tools"
    ln -sf /usr/bin/adb "$USER_SDK/platform-tools/adb"
    [ -e "$USER_SDK/emulator" ] || ln -sfn /opt/android-sdk/emulator "$USER_SDK/emulator"
    [ -e "$USER_SDK/system-images" ] || ln -sfn /opt/android-sdk/system-images "$USER_SDK/system-images"
    [ -e "$USER_SDK/cmdline-tools" ] || ln -sfn /opt/android-sdk/cmdline-tools "$USER_SDK/cmdline-tools"
    [ -e "$USER_SDK/licenses" ] || ln -sfn /opt/android-sdk/licenses "$USER_SDK/licenses" 2>/dev/null || true
    export ANDROID_HOME="$USER_SDK"
    export ANDROID_SDK_ROOT="$USER_SDK"
else
    export ANDROID_HOME=/opt/android-sdk
    export ANDROID_SDK_ROOT=/opt/android-sdk
fi

export ANDROID_AVD_HOME="$HOME/.android/avd"
export PATH=$PATH:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/emulator:$ANDROID_HOME/platform-tools

AVD_NAME="pixel_7"
DEVICE_PROFILE="pixel_7"
# Android 11 Google APIs x86_64 ships libndk_translation, so arm64-only APKs can install.
IMG="system-images;android-30;google_apis;x86_64"
CONFIG_FILE="$ANDROID_AVD_HOME/${AVD_NAME}.avd/config.ini"

# 支持传入指定的 APK 路径，默认使用已下载的讯飞 AI 学
APK_PATH="${1:-$HOME/Downloads/讯飞AI学-4.9.0.13591.apk}"
PKG_NAME="com.iflytek.aistudyclient.parentcontrol"

# 2. 检查虚拟设备是否存在，若不存在则根据 Google Pixel 7 硬件配置自动创建
if ! emulator -list-avds 2>/dev/null | grep -qx "$AVD_NAME"; then
    echo "📱 未检测到虚拟手机 [$AVD_NAME]，正在基于 Google Pixel 7 规格自动创建..."
    echo "no" | avdmanager create avd -n "$AVD_NAME" -d "$DEVICE_PROFILE" -k "$IMG" --force

    if [ -f "$CONFIG_FILE" ]; then
        echo "⚙️ 优化 Pixel 7 虚拟机配置 (3G 内存、2核 CPU、核显、720x1600、键盘)..."
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
    echo "✅ 虚拟手机 [$AVD_NAME] 创建并配置完成！"
fi

# 3. 注册/更新 Omarchy 桌面菜单快捷方式 (纯图形启动 Terminal=false)
DESKTOP_DIR="$HOME/.local/share/applications"
DESKTOP_FILE="$DESKTOP_DIR/pixel-7-emulator.desktop"
mkdir -p "$DESKTOP_DIR"
cat << EOF > "$DESKTOP_FILE"
[Desktop Entry]
Name=Pixel 7 (Android 模拟器)
GenericName=Android 模拟器
Comment=Android Emulator running Google Pixel 7
Exec=$SCRIPT_PATH
Icon=android
Terminal=false
Type=Application
Categories=Development;System;
Keywords=pixel;pixel7;pixel-7;xunfei;android;emulator;moniqi;安卓;模拟器;讯飞;
EOF

# 清理旧的 xunfei 快捷方式以及 Waydroid 讯飞快捷方式
rm -f "$DESKTOP_DIR/xunfei-emulator.desktop"
rm -f "$DESKTOP_DIR/waydroid.com.iflytek.aistudyclient.parentcontrol.desktop"

# 尝试从 Waydroid 中卸载无法正常运行的讯飞应用
waydroid app remove com.iflytek.aistudyclient.parentcontrol >/dev/null 2>&1 || true

# 刷新桌面数据库与 Omarchy 菜单缓存
update-desktop-database "$DESKTOP_DIR" >/dev/null 2>&1 || true
omarchy-menu refresh >/dev/null 2>&1 || true

# 4. 后台等待模拟器系统完全启动后自动安装并打开应用
(
    TARGET_DEV=""
    for i in {1..150}; do
        TARGET_DEV=$(adb devices 2>/dev/null | awk '$2=="device" && $1~/^emulator-/ {print $1; exit}')
        if [ -n "$TARGET_DEV" ]; then
            BOOT=$(adb -s "$TARGET_DEV" shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')
            if [ "$BOOT" = "1" ]; then
                break
            fi
        fi
        sleep 2
    done

    if [ -n "$TARGET_DEV" ] && [ -f "$APK_PATH" ]; then
        echo ""
        echo "✨ [后台助手] 虚拟手机 ($AVD_NAME / $TARGET_DEV) 系统就绪！"
        if ! adb -s "$TARGET_DEV" shell pm list packages 2>/dev/null | grep -q "$PKG_NAME"; then
            echo "📦 [后台助手] 正在安装 $APK_PATH ..."
            adb -s "$TARGET_DEV" install -r "$APK_PATH"
            echo "✅ [后台助手] 应用安装成功！"
        fi
        echo "🎉 [后台助手] 正在打开应用..."
        adb -s "$TARGET_DEV" shell monkey -p "$PKG_NAME" -c android.intent.category.LAUNCHER 1 >/dev/null 2>&1 || true
    fi
) &

echo "🚀 正在启动 Android 模拟器 (设备型号: Google Pixel 7 / AVD: $AVD_NAME)..."
echo "💡 提示：用 adb install 安装 APK。拖进窗口会让模拟器崩溃。"
exec emulator -avd "$AVD_NAME"
