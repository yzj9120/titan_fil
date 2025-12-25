#!/bin/bash

# 设置目标目录
LIB_DIR="/Users/dq/Desktop/hz/code/titan_fil/macos/libs"

# 要压缩的 dylib 列表
DYLIB_FILES=("gol2.dylib" "libgoworkerd.dylib")

echo "🔍 开始压缩 macOS/iOS .dylib 文件..."

for FILE in "${DYLIB_FILES[@]}"; do
    DYLIB_PATH="$LIB_DIR/$FILE"

    if [ -f "$DYLIB_PATH" ]; then
        echo "📦 处理: $FILE"

        # 0. 备份原始文件
        cp "$DYLIB_PATH" "${DYLIB_PATH}.orig"

        # 1. 移除调试符号
        strip -x "$DYLIB_PATH"

        # 2. 使用 UPX 压缩（去除 --macos 参数）
        upx --best "$DYLIB_PATH"

        # 3. 重签名
        codesign -f -s - "$DYLIB_PATH"

        echo "✅ 压缩完成: $FILE"
        echo "   → 原始大小: $(du -h "${DYLIB_PATH}.orig" | cut -f1)"
        echo "   → 压缩后: $(du -h "$DYLIB_PATH" | cut -f1)"
    else
        echo "❌ 找不到文件: $DYLIB_PATH"
    fi
done

echo "🎉 所有 .dylib 文件处理完毕！"
