#!/bin/bash

ZH_FILE="/Users/dq/Desktop/hz/code/titan_fil/assets/l10n/zh.json"
EN_FILE="/Users/dq/Desktop/hz/code/titan_fil/assets/l10n/en.json"
TMP_FILE="/tmp/en_translated.json"

echo "🚀 Starting translation script..."
echo "📄 Original file: $ZH_FILE"
echo "📁 Output file: $EN_FILE"

# Initialize the target file
echo "{" > $TMP_FILE

echo "🔍 Extracting original JSON and translating line by line..."

# Get the existing keys in EN_FILE (to avoid re-translating)
existing_keys=$(jq -r 'keys[]' "$EN_FILE")

# Use jq to parse the JSON file and get each key-value pair
jq -r 'to_entries | .[] | "\(.key)=\(.value)"' "$ZH_FILE" | while read -r line; do
  key=$(echo "$line" | cut -d'=' -f1)
  value=$(echo "$line" | cut -d'=' -f2-)

  # If EN_FILE already contains this key, skip translation
  if echo "$existing_keys" | grep -q "^$key$"; then
    echo "🔁 Skipping translation: \"$key\" already exists"
    # Directly copy the existing translation from EN_FILE
    translation=$(jq -r --arg key "$key" '.[$key]' "$EN_FILE")
  else
    # Call the translation API
    echo "🌐 Translating: \"$key\" => \"$value\""

    # Call the new translation API
    translation=$(curl -s -X POST https://test-microsoft-client.bdnft.com/api/tranRecord/tranText \
      -H "Content-Type: application/json" \
      -d "{
        \"speechType\": \"zh-CN\",
        \"tranType\": \"en-US\",
        \"tranText\": \"$value\"
      }")

    # Extract translation from the response (assuming response contains 'result' field)
    translation=$(echo "$translation" | jq -r '.result')

    # Check if the result is empty
    if [[ -z "$translation" ]]; then
      echo "❌ Translation failed: \"$key\" result is empty"
      translation="(Translation Failed)"
    else
      echo "✅ Translation complete: \"$key\" => \"$translation\""
    fi
  fi

  # Write to the temporary file
  echo "  \"$key\": \"$translation\"," >> $TMP_FILE
done

echo "🧹 Cleaning up the last comma..."
# Remove the last comma
sed -i '' '$ s/,$//' $TMP_FILE

echo "✅ Closing the JSON structure..."
echo "}" >> $TMP_FILE

echo "🚚 Writing to the final file..."
mv $TMP_FILE $EN_FILE

echo "🎉 All translations completed! Output file generated: $EN_FILE"
