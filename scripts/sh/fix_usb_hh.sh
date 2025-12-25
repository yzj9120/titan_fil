#!/bin/bash

# 定义U盘标识符和挂载点
USB_IDENTIFIER="/dev/disk8s1"
USB_VOLUME_NAME="HH"
MOUNT_POINT="/Volumes/$USB_VOLUME_NAME"

echo "🔍 正在处理U盘: $USB_IDENTIFIER (卷名: $USB_VOLUME_NAME)"

# 尝试卸载（如果已挂载但异常）
diskutil unmount "$USB_IDENTIFIER" &> /dev/null

# 步骤1: 正常挂载
echo "🔄 尝试正常挂载..."
diskutil mount "$USB_IDENTIFIER"
if [ $? -eq 0 ]; then
    echo "🎉 成功挂载到: $MOUNT_POINT"
    open "$MOUNT_POINT"
    exit 0
fi

# 步骤2: 修复文件系统
echo "⚠️ 挂载失败，尝试修复..."
diskutil repairVolume "$USB_IDENTIFIER"
if [ $? -ne 0 ]; then
    echo "❌ 修复失败，可能是严重文件系统损坏。"
fi

# 步骤3: 再次尝试挂载
diskutil mount "$USB_IDENTIFIER" &> /dev/null
if [ $? -eq 0 ]; then
    echo "🎉 修复后挂载成功！"
    open "$MOUNT_POINT"
    exit 0
fi

# 步骤4: 强制挂载（需要sudo）
echo "⚡ 尝试强制挂载..."
sudo mkdir -p "$MOUNT_POINT"
sudo mount -t msdos "$USB_IDENTIFIER" "$MOUNT_POINT"

if [ $? -eq 0 ]; then
    echo "⚠️ 强制挂载成功！访问路径:"
    echo "   $MOUNT_POINT"
    open "$MOUNT_POINT"
else
    echo "❌ 所有尝试均失败，建议："
    echo "   1. 备份数据后格式化U盘"
    echo "   2. 在其他电脑上测试U盘是否物理损坏"
    echo ""
    echo "📌 格式化命令参考:"
    echo "   diskutil eraseDisk FAT32 HH MBRFormat /dev/disk8"
fi