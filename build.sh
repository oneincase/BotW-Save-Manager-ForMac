#!/bin/bash
# ============================================================
# Botw 存档管理器 - 一键打包脚本
# 构建 macOS .app 并打包为 DMG 安装镜像
# ============================================================

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# 项目根目录
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$PROJECT_DIR"

# 输出目录
DIST_DIR="$PROJECT_DIR/dist"
APP_NAME="Botw 存档管理器.app"
APP_PATH="$DIST_DIR/$APP_NAME"
DMG_NAME="BotwSaveManager-Installer.dmg"
DMG_PATH="$DIST_DIR/$DMG_NAME"

echo -e "${YELLOW}========================================${NC}"
echo -e "${YELLOW}  Botw 存档管理器 - macOS 打包脚本${NC}"
echo -e "${YELLOW}========================================${NC}"
echo ""

# 检查 .NET SDK
echo -e "${GREEN}[1/5] 检查环境...${NC}"
if ! command -v dotnet &> /dev/null; then
    echo -e "${RED}❌ 未找到 dotnet 命令${NC}"
    echo "请安装 .NET 6 SDK: brew install dotnet@6"
    exit 1
fi
echo "   ✅ .NET SDK: $(dotnet --version)"

# 检查 create-dmg
if ! command -v create-dmg &> /dev/null; then
    echo -e "${YELLOW}   ⚠ 未安装 create-dmg，正在安装...${NC}"
    brew install create-dmg
fi
echo "   ✅ create-dmg: $(create-dmg --version 2>&1 | head -1)"

# 清理旧构建
echo ""
echo -e "${GREEN}[2/5] 清理旧构建...${NC}"
rm -rf "$DIST_DIR"
mkdir -p "$DIST_DIR"
echo "   ✅ 已清理"

# 发布应用
echo ""
echo -e "${GREEN}[3/5] 发布应用...${NC}"
dotnet publish -c Release -r osx-x64 --self-contained true -p:PublishTrimmed=false 2>&1 | while IFS= read -r line; do
    echo "   $line"
done
echo "   ✅ 发布完成"

# 创建 .app 包
echo ""
echo -e "${GREEN}[4/5] 创建 .app 包...${NC}"
mkdir -p "$APP_PATH/Contents/MacOS"
mkdir -p "$APP_PATH/Contents/Resources"

# 复制发布文件
cp -r BotwSaveManager/bin/Release/net6.0/osx-x64/publish/* "$APP_PATH/Contents/MacOS/"
chmod +x "$APP_PATH/Contents/MacOS/BotwSaveManager"

# 创建 Info.plist
cat > "$APP_PATH/Contents/Info.plist" << 'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>BotwSaveManager</string>
    <key>CFBundleIdentifier</key>
    <string>com.botwsavemanager.mac</string>
    <key>CFBundleName</key>
    <string>Botw 存档管理器</string>
    <key>CFBundleDisplayName</key>
    <string>Botw 存档管理器</string>
    <key>CFBundleVersion</key>
    <string>2.0.0</string>
    <key>CFBundleShortVersionString</key>
    <string>2.0.0</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>LSMinimumSystemVersion</key>
    <string>10.15</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>CFBundleIconFile</key>
    <string>icon.icns</string>
</dict>
</plist>
PLIST

# 复制修复脚本到 dist
cp "$PROJECT_DIR/scripts/fix-quarantine.sh" "$DIST_DIR/fix-quarantine.sh"
chmod +x "$DIST_DIR/fix-quarantine.sh"

APP_SIZE=$(du -sh "$APP_PATH" | cut -f1)
echo "   ✅ .app 包创建完成 (${APP_SIZE})"

# 创建 DMG
echo ""
echo -e "${GREEN}[5/5] 打包 DMG 安装镜像...${NC}"
create-dmg \
    --volname "Botw 存档管理器" \
    --window-pos 200 120 \
    --window-size 600 400 \
    --icon-size 100 \
    --icon "$APP_NAME" 150 190 \
    --app-drop-link 450 190 \
    --no-internet-enable \
    "$DMG_PATH" \
    "$APP_PATH" 2>&1 | while IFS= read -r line; do
    echo "   $line"
done

# 清理临时 DMG
rm -f "$DIST_DIR"/rw.*.dmg 2>/dev/null

DMG_SIZE=$(du -sh "$DMG_PATH" | cut -f1)
echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  🎉 打包完成！${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "  输出目录: $DIST_DIR"
echo "  ├── $APP_NAME    (${APP_SIZE})"
echo "  ├── $DMG_NAME    (${DMG_SIZE})"
echo "  └── fix-quarantine.sh    (损坏修复脚本)"
echo ""
echo -e "${YELLOW}📦 DMG 安装包: ${DMG_PATH}${NC}"
echo ""
echo "💡 如果打开应用提示"已损坏"，请运行:"
echo "   bash dist/fix-quarantine.sh"
