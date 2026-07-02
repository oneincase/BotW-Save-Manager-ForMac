#!/bin/bash
# ============================================================
# Botw 存档管理器 - 修复损坏提示脚本
# 当 macOS 提示"应用已损坏，无法打开"时运行此脚本
# ============================================================

APP_NAME="Botw 存档管理器.app"

# 查找应用路径
if [ -d "/Applications/$APP_NAME" ]; then
    APP_PATH="/Applications/$APP_NAME"
elif [ -d "$HOME/Applications/$APP_NAME" ]; then
    APP_PATH="$HOME/Applications/$APP_NAME"
elif [ -d "./$APP_NAME" ]; then
    APP_PATH="./$APP_NAME"
else
    echo "❌ 未找到 \"$APP_NAME\""
    echo "请将本脚本放在 \"$APP_NAME\" 同级目录后重试"
    exit 1
fi

echo "🔧 正在修复: $APP_PATH"

# 1. 移除 quarantine 属性（"已损坏"提示的罪魁祸首）
xattr -dr com.apple.quarantine "$APP_PATH"
echo "   ✅ 已移除 quarantine 属性"

# 2. 移除所有其他扩展属性
xattr -cr "$APP_PATH"
echo "   ✅ 已清除所有扩展属性"

# 3. 添加可执行权限
chmod -R +x "$APP_PATH/Contents/MacOS/"
echo "   ✅ 已设置可执行权限"

echo ""
echo "🎉 修复完成！请重新打开 \"$APP_NAME\""
echo ""
echo "如果仍然提示损坏，请前往："
echo "  系统设置 → 隐私与安全性 → 仍要打开"
