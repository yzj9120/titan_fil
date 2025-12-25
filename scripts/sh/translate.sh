#!/bin/bash

# 设置文件路径
ZH_FILE="/Users/dq/Desktop/hz/code/titan_fil/assets/l10n/zh.json"
EN_FILE="/Users/dq/Desktop/hz/code/titan_fil/assets/l10n/en.json"
TMP_FILE="/tmp/en_translated.json"

# 设置翻译接口标志，选择使用哪个翻译API
# 可选择 'microsoft' 或 '39'
TRANSLATION_API="microsoft"

echo "🚀 Starting translation script..."
echo "📄 Original file: $ZH_FILE"
echo "📁 Output file: $EN_FILE"

# 初始化目标文件
echo "{" > $TMP_FILE

echo "🔍 Extracting original JSON and translating line by line..."

# 获取 EN_FILE 中已存在的键，避免重复翻译
existing_keys=$(jq -r 'keys[]' "$EN_FILE")

# 使用 jq 解析 JSON 文件并逐行翻译
jq -r 'to_entries | .[] | "\(.key)=\(.value)"' "$ZH_FILE" | while read -r line; do
  key=$(echo "$line" | cut -d'=' -f1)
  value=$(echo "$line" | cut -d'=' -f2-)

  # 如果 EN_FILE 已经包含此键，跳过翻译
  if echo "$existing_keys" | grep -q "^$key$"; then
    echo "🔁 Skipping translation: \"$key\" already exists"
    # 直接从 EN_FILE 中复制现有翻译
    translation=$(jq -r --arg key "$key" '.[$key]' "$EN_FILE")
  else
    # 根据选择的翻译 API 进行翻译
    if [ "$TRANSLATION_API" == "microsoft" ]; then
      # 使用 Microsoft 翻译 API
      echo "🌐 Microsoft API: Translating \"$key\" => \"$value\""

      translation=$(curl -s -X POST https://test-microsoft-client.bdnft.com/api/tranRecord/tranText \
        -H "Content-Type: application/json" \
        -d "{
          \"speechType\": \"zh-CN\",
          \"tranType\": \"en-US\",
          \"tranText\": \"$value\"
        }")

      # 从响应中提取翻译结果
      translation=$(echo "$translation" | jq -r '.result')
    elif [ "$TRANSLATION_API" == "39" ]; then
      # 使用 39 翻译 API
      echo "🌐 39 API: Translating \"$key\" => \"$value\""

      translation=$(curl -s -X POST http://39.108.75.131:8006/trans/text \
        -H "Content-Type: application/json" \
        -d "{
          \"text\": \"$value\",
          \"model\": \"gpt-4o\",
          \"ori_lang\": \"zh-CN\",
          \"tar_lang\": \"en-US\"
        }")

      # 清理翻译结果（去除引号）
      translation=$(echo "$translation" | sed 's/^"//;s/"$//')
    fi

    # 检查翻译结果是否为空
    if [[ -z "$translation" ]]; then
      echo "❌ Translation failed: \"$key\" result is empty"
      translation="(Translation Failed)"
    else
      echo "✅ Translation complete: \"$key\" => \"$translation\""
    fi
  fi

  # 写入临时文件
  echo "  \"$key\": \"$translation\"," >> $TMP_FILE
done

echo "🧹 Cleaning up the last comma..."
# 去掉最后一个逗号
sed -i '' '$ s/,$//' $TMP_FILE

echo "✅ Closing the JSON structure..."
echo "}" >> $TMP_FILE

echo "🚚 Writing to the final file..."
mv $TMP_FILE $EN_FILE

echo "🎉 All translations completed! Output file generated: $EN_FILE"
