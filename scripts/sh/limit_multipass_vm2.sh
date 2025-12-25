#!/bin/bash
# ===================================================
# 脚本说明：
# 给第一个正在运行的 multipass 虚拟机设置上传和下载限速，
# 并在虚拟机内启动 bmon 监控网卡流量。
#
# 使用：
# ./limit_multipass_vm.sh [上传限速] [下载限速]
# 示例：
# ./limit_multipass_vm.sh 512kbit 2mbit
# 默认上传/下载限速均为 1mbit
# ===================================================

set -euo pipefail

# --------------------
# 读取参数或使用默认值
UPLOAD_LIMIT="${1:-15mbit}"
DOWNLOAD_LIMIT="${2:-15mbit}"

echo "==== 1. 查询第一个正在运行的 multipass 虚拟机 ===="
VM_NAME=$(multipass list --format csv | grep Running | head -n 1 | cut -d ',' -f1 || true)

if [[ -z "$VM_NAME" ]]; then
  echo "❌ 没有找到正在运行的虚拟机，脚本退出。"
  exit 1
fi

echo "✅ 选择虚拟机名称: $VM_NAME"

CONFIG_SCRIPT="/tmp/set_tc_limit.sh"

echo "==== 2. 生成虚拟机内部限速配置脚本 ===="
multipass exec "$VM_NAME" -- bash -c "cat > $CONFIG_SCRIPT" <<EOF
#!/bin/bash
set -euo pipefail

UPLOAD_LIMIT="$UPLOAD_LIMIT"
DOWNLOAD_LIMIT="$DOWNLOAD_LIMIT"
BURST="15k"
CBURST="15k"
CEIL_UPLOAD="\$UPLOAD_LIMIT"
CEIL_DOWNLOAD="\$DOWNLOAD_LIMIT"

echo "==== 虚拟机内：开始限速配置 ===="

install_pkg() {
  local pkg="\$1"
  if ! command -v "\$pkg" &> /dev/null; then
    echo "🛠 安装软件包：\$pkg"
    local tries=0 max_tries=10
    while sudo fuser /var/lib/dpkg/lock >/dev/null 2>&1; do
      ((tries++))
      if (( tries > max_tries )); then
        echo "❌ 超过最大等待时间，dpkg锁未释放，安装失败"
        exit 1
      fi
      echo "等待 dpkg 锁释放中... (尝试第 \$tries 次)"
      sleep 3
    done
    sudo apt-get update -qq
    sudo apt-get install -y "\$pkg"
  else
    echo "✅ 软件包 \$pkg 已安装"
  fi
}

install_pkg tc
install_pkg bmon

# 加载 ifb 模块
if ! lsmod | grep -q '^ifb'; then
  echo "📦 加载 ifb 模块..."
  sudo modprobe ifb || echo "⚠️ 加载 ifb 模块失败（可能已加载或不支持）"
else
  echo "✅ ifb 模块已加载"
fi

# 创建 ifb0 设备（如果不存在）
if ! ip link show ifb0 &>/dev/null; then
  echo "🔧 创建 ifb0 设备..."
  sudo ip link add ifb0 type ifb || echo "⚠️ ifb0 设备创建失败（可能已存在）"
else
  echo "✅ ifb0 设备已存在"
fi
sudo ip link set ifb0 up

# 查找主网卡接口名（默认通过路由到 8.8.8.8）
DEV=\$(ip route get 8.8.8.8 2>/dev/null | awk '{print \$5}')
if [[ -z "\$DEV" ]]; then
  echo "❌ 找不到主网卡设备，退出。"
  exit 1
fi
echo "✅ 主网卡接口为：\$DEV"

# 清理旧规则
echo "🧹 清理旧的 tc 限速规则..."
sudo tc qdisc del dev "\$DEV" root 2>/dev/null || true
sudo tc qdisc del dev "\$DEV" ingress 2>/dev/null || true
sudo tc qdisc del dev ifb0 root 2>/dev/null || true

# ===== 上传限速配置 =====
echo "📤 设置上传限速：\$UPLOAD_LIMIT"
sudo tc qdisc add dev "\$DEV" root handle 1: htb default 12
sudo tc class add dev "\$DEV" parent 1: classid 1:1 htb rate "\$UPLOAD_LIMIT" ceil "\$CEIL_UPLOAD" burst "\$BURST" cburst "\$CBURST"
sudo tc class add dev "\$DEV" parent 1:1 classid 1:12 htb rate "\$UPLOAD_LIMIT" ceil "\$CEIL_UPLOAD" burst "\$BURST" cburst "\$CBURST"

# ===== 下载限速配置（ifb0） =====
echo "📥 设置下载限速：\$DOWNLOAD_LIMIT"
sudo tc qdisc add dev "\$DEV" handle ffff: ingress
sudo tc filter add dev "\$DEV" parent ffff: protocol ip u32 match u32 0 0 action mirred egress redirect dev ifb0
sudo tc qdisc add dev ifb0 root handle 1: htb default 12
sudo tc class add dev ifb0 parent 1: classid 1:1 htb rate "\$DOWNLOAD_LIMIT" ceil "\$CEIL_DOWNLOAD" burst "\$BURST" cburst "\$CBURST"
sudo tc class add dev ifb0 parent 1:1 classid 1:12 htb rate "\$DOWNLOAD_LIMIT" ceil "\$CEIL_DOWNLOAD" burst "\$BURST" cburst "\$CBURST"

echo -e "\\n==== ✅ 限速配置完成 ===="
echo "📤 上传限速：\$UPLOAD_LIMIT"
echo "📥 下载限速：\$DOWNLOAD_LIMIT"

echo -e "\\n==== 当前 tc 配置 ===="
sudo tc qdisc show dev "\$DEV"
sudo tc class show dev "\$DEV"
sudo tc qdisc show dev ifb0
sudo tc class show dev ifb0

# 启动 bmon（可取消注释以实时监控）
# echo -e "\\n🎉 启动 bmon 进行实时带宽监控（按 Ctrl+C 退出）"
# exec bmon -p "\$DEV"
EOF

# --------------------
# 添加执行权限并执行脚本
multipass exec "$VM_NAME" -- chmod +x "$CONFIG_SCRIPT"
echo "==== 3. 执行虚拟机内限速配置脚本 ===="
multipass exec "$VM_NAME" -- bash "$CONFIG_SCRIPT"
