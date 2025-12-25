#!/bin/bash

# 获取 CPU 信息
CPU_PHYSICAL_CORES=$(sysctl -n hw.physicalcpu)
CPU_CORES=$(sysctl -n hw.ncpu)
CPU_MODEL=$(sysctl -n machdep.cpu.brand_string 2>/dev/null || (lscpu | grep 'Model name' | awk -F: '{print $2}' | xargs))
CPU_MODEL=$(echo "$CPU_MODEL" | xargs)  # 去除首尾空白

# 获取总内存（字节转GB，保留2位小数）
TOTAL_MEM_BYTES=$(sysctl -n hw.memsize)
TOTAL_MEM_GB=$(awk "BEGIN {printf \"%.2f\", $TOTAL_MEM_BYTES/1024/1024/1024}")

# 获取可用内存（字节转GB，保留2位小数）
if command -v vm_stat &> /dev/null; then
  PAGE_SIZE=4096  # macOS一般固定4KB页面大小
  FREE_PAGES=$(vm_stat | awk '/Pages free/ {print $3}' | tr -d '.')
  INACTIVE_PAGES=$(vm_stat | awk '/Pages inactive/ {print $3}' | tr -d '.')
  FREE_MEM_BYTES=$(( (FREE_PAGES + INACTIVE_PAGES) * PAGE_SIZE ))
  FREE_MEM_GB=$(awk "BEGIN {printf \"%.2f\", $FREE_MEM_BYTES/1024/1024/1024}")
else
  # 兼容Linux
  FREE_MEM_GB=$(free -m | awk '/Mem:/ {printf "%.2f", $7/1024}')
fi

# 获取磁盘信息（用 df -k 读取KB数，转换为GB）
DISK_TOTAL_KB=$(df -k / | awk 'NR==2 {print $2}')
DISK_USED_KB=$(df -k / | awk 'NR==2 {print $3}')
DISK_AVAIL_KB=$(df -k / | awk 'NR==2 {print $4}')

DISK_TOTAL_GB=$(awk "BEGIN {printf \"%.2f\", $DISK_TOTAL_KB/1024/1024}")
DISK_USED_GB=$(awk "BEGIN {printf \"%.2f\", $DISK_USED_KB/1024/1024}")
DISK_AVAIL_GB=$(awk "BEGIN {printf \"%.2f\", $DISK_AVAIL_KB/1024/1024}")

# 输出为 JSON 格式，新增 physical_cores 字段
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
    \"total\": \"${DISK_TOTAL_GB}\",
    \"used\": \"${DISK_USED_GB}\",
    \"available\": \"${DISK_AVAIL_GB}\"
  }
}"
