#!/bin/sh

# macOS 打包脚本，编译 Flutter macOS .app 并打包为 .dmg
# 用法：直接运行脚本

set -e

# === 当前路径设定 ===
scriptDir="$(cd "$(dirname "$0")" && pwd)"      # scripts/sh
projectRoot="$scriptDir/../.."                  # 项目根目录
outputDir="$scriptDir/products"                 # 输出 dmg 的目录
backgroundImage="$scriptDir/../installer_background_en.png"

# === 配置 ===
fileNamePrefix=""
appName="titan_fil"

# === 构建 Flutter MacOS Release ===
cd "$projectRoot"
flutter clean
flutter build macos --release

# === 读取版本号 ===
fullVersion=$(grep -i -e "version: " pubspec.yaml)
buildName=$(echo "$fullVersion" | cut -d " " -f 2 | cut -d "+" -f 1)
buildNumber=$(echo "$fullVersion" | cut -d "+" -f 2)
echo "📦 版本号: $buildName, 构建号: $buildNumber"

# === 定位 .app 文件 ===
cd build/macos/Build/Products/Release
appPath=$(find . -type d -name "*.app")
internalAppName=$(basename "$appPath" .app)
echo "🧭 .app 路径: $appPath"

# === 动态设置名称 ===
[ -z "$appName" ] && appName=$internalAppName
[ -z "$fileNamePrefix" ] && fileNamePrefix=$appName

# === 生成文件名 ===
currentDate=$(date +'%Y%m%d')
fileName="${fileNamePrefix}_macos_${buildName}_${buildNumber}_${currentDate}.dmg"

# === 创建临时目录并移动 .app ===
tempDir=$(mktemp -d)
mv "$appPath" "$tempDir/"

# === 创建输出目录 ===
mkdir -p "$outputDir"

# === 删除旧文件（如果存在）===
test -f "$outputDir/$fileName" && rm "$outputDir/$fileName"

# === 打包为 .dmg ===
create-dmg \
  --volname "${appName}" \
  --background "$backgroundImage" \
  --window-pos 200 120 \
  --window-size 800 450 \
  --icon-size 110 \
  --icon "${appName}.app" 185 275 \
  --hide-extension "${appName}.app" \
  --app-drop-link 605 275 \
  "$outputDir/$fileName" \
  "$tempDir"

# === 打开输出目录 ===
open "$outputDir"

# === 清理 ===
rm -rf "$tempDir"

echo "✅ 打包完成：$outputDir/$fileName"
