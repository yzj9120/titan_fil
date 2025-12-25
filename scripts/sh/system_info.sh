#!/bin/bash

# ========== CPU ==========
CPU_PHYSICAL_CORES=$(sysctl -n hw.physicalcpu)
CPU_CORES=$(sysctl -n hw.ncpu)
CPU_MODEL=$(sysctl -n machdep.cpu.brand_string 2>/dev/null || (lscpu | grep 'Model name' | awk -F: '{print $2}' | xargs))
CPU_MODEL=$(echo "$CPU_MODEL" | xargs)  # 去除首尾空白

# ========== 内存 ==========
TOTAL_MEM_BYTES=$(sysctl -n hw.memsize)
TOTAL_MEM_GB=$(awk "BEGIN {printf \"%.1f\", $TOTAL_MEM_BYTES/1024/1024/1024}" | sed 's/\.0$//')

if command -v vm_stat &> /dev/null; then
  PAGE_SIZE=4096
  FREE_PAGES=$(vm_stat | awk '/Pages free/ {print $3}' | tr -d '.')
  INACTIVE_PAGES=$(vm_stat | awk '/Pages inactive/ {print $3}' | tr -d '.')
  FREE_MEM_BYTES=$(( (FREE_PAGES + INACTIVE_PAGES) * PAGE_SIZE ))
  FREE_MEM_GB=$(awk "BEGIN {printf \"%.1f\", $FREE_MEM_BYTES/1024/1024/1024}" | sed 's/\.0$//')
else
  FREE_MEM_GB=$(free -m | awk '/Mem:/ {printf "%.1f", $7/1024}' | sed 's/\.0$//')
fi

# ========== 磁盘 ==========
# ========== 磁盘 ==========
if command -v diskutil &> /dev/null; then
  DISK_TOTAL_BYTES=$(diskutil info / | awk -F': ' '/Container Total Space/ {print $2}' | grep -Eo '[0-9.]+' | head -n 1)
  DISK_AVAILABLE_BYTES=$(diskutil info / | awk -F': ' '/Container Free Space/ {print $2}' | grep -Eo '[0-9.]+' | head -n 1)

  DISK_TOTAL_GB=$(awk "BEGIN {printf \"%.1f\", $DISK_TOTAL_BYTES}" | sed 's/\.0$//')
  DISK_AVAIL_GB=$(awk "BEGIN {printf \"%.1f\", $DISK_AVAILABLE_BYTES}" | sed 's/\.0$//')
  DISK_USED_GB=$(awk "BEGIN {printf \"%.1f\", $DISK_TOTAL_GB - $DISK_AVAIL_GB}" | sed 's/\.0$//')
else
  # Linux 版本
  DISK_TOTAL_KB=$(df -k / | awk 'NR==2 {print $2}')
  DISK_USED_KB=$(df -k / | awk 'NR==2 {print $3}')
  DISK_AVAIL_KB=$(df -k / | awk 'NR==2 {print $4}')

  DISK_TOTAL_GB=$(awk "BEGIN {printf \"%.1f\", $DISK_TOTAL_KB/1024/1024}" | sed 's/\.0$//')
  DISK_USED_GB=$(awk "BEGIN {printf \"%.1f\", $DISK_USED_KB/1024/1024}" | sed 's/\.0$//')
  DISK_AVAIL_GB=$(awk "BEGIN {printf \"%.1f\", $DISK_AVAIL_KB/1024/1024}" | sed 's/\.0$//')
fi


# ========== JSON 输出 ==========
echo "{
  \"cpu\": {
    \"cores\": $CPU_CORES,
    \"physical_cores\": $CPU_PHYSICAL_CORES,
    \"model\": \"$CPU_MODEL\"
  },
  \"memory\": {
    \"total_gb\": $TOTAL_MEM_GB,
    \"free_gb\": $FREE_MEM_GB
  },
  \"disk\": {
    \"total\": \"${DISK_TOTAL_GB}G\",
    \"used\": \"${DISK_USED_GB}G\",
    \"available\": \"${DISK_AVAIL_GB}G\"
  }
}"
