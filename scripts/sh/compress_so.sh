#!/bin/bash

# 设置目标目录
LIB_DIR="/Users/dq/Desktop/hz/code/titan-new-data-client/android/app/libs/armeabi-v7a"

# 要压缩的库列表
SO_FILES=("libgol2.so" "libgoworkerd.so")

echo "🔍 开始压缩 Android .so 文件..."

for FILE in "${SO_FILES[@]}"; do
    SO_PATH="$LIB_DIR/$FILE"

    if [ -f "$SO_PATH" ]; then
        echo "📦 处理: $FILE"

        # 添加执行权限（防止 UPX 拒绝压缩）
        chmod +x "$SO_PATH"

        # 压缩文件
        upx --ultra-brute --android-shlib "$SO_PATH"

        echo "✅ 压缩完成: $FILE"
    else
        echo "❌ 找不到文件: $SO_PATH"
    fi
done

echo "🎉 所有文件处理完毕！"
