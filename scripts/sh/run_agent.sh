#!/bin/bash
# titan_fil Agent 直接运行脚本（控制台输出日志）

# 定义参数
AGENT="/Users/dq/Desktop/titan_fil_agent/agent"
WORK_DIR="/Users/dq/Desktop/titan_fil_agent"
SERVER="https://test4-api.titannet.io"
KEY="sM7BFQRmg1HI"

# 直接运行并在控制台显示输出
echo "=== 启动 titan_fil Agent ==="
echo "工作目录: $WORK_DIR"
echo "服务器: $SERVER"
echo "启动时间: $(date)"
echo "==============================="

"$AGENT" \
  --working-dir="$WORK_DIR" \
  --server-url="$SERVER" \
  --key="$KEY"