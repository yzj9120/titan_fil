#!/bin/bash
# ===================================================
# 脚本说明：
# 给第一个正在运行的 multipass 虚拟机设置上传和下载限速，
# 并在虚拟机内配置限速，带详细执行反馈。
#
# 使用：
# ./limit_multipass_vm.sh [上传限速] [下载限速]
# 例如：
# ./limit_multipass_vm.sh 512kbit 2mbit
# 默认上传/下载限速均为 1mbit
# ===================================================

set -euo pipefail

UPLOAD_LIMIT="${1:-10mbit}"
DOWNLOAD_LIMIT="${2:-10mbit}"

echo "==== 1. 查询第一个正在运行的 multipass 虚拟机 ===="
VM_NAME=$(multipass list --format csv | tail -n +2 | head -n 1 | cut -d ',' -f1 || true)

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
    if sudo apt-get install -y "\$pkg"; then
      echo "✅ 软件包 \$pkg 安装成功"
    else
      echo "❌ 软件包 \$pkg 安装失败"
      exit 1
    fi
  else
    echo "✅ 软件包 \$pkg 已安装"
  fi
}

install_pkg tc

# 加载 ifb 模块
if ! lsmod | grep -q '^ifb'; then
  echo "📦 加载 ifb 模块..."
  if sudo modprobe ifb; then
    echo "✅ ifb 模块加载成功"
  else
    echo "⚠️ 加载 ifb 模块失败（可能已加载或不支持）"
  fi
else
  echo "✅ ifb 模块已加载"
fi

# 创建 ifb0 设备（如果不存在）
if ! ip link show ifb0 &>/dev/null; then
  echo "🔧 创建 ifb0 设备..."
  if sudo ip link add ifb0 type ifb; then
    echo "✅ ifb0 设备创建成功"
  else
    echo "⚠️ ifb0 设备创建失败（可能已存在）"
  fi
else
  echo "✅ ifb0 设备已存在"
fi

if sudo ip link set ifb0 up; then
  echo "✅ ifb0 设备已启用"
else
  echo "❌ ifb0 设备启用失败"
  exit 1
fi

DEV=\$(ip route get 8.8.8.8 2>/dev/null | awk '{print \$5}')
if [[ -z "\$DEV" ]]; then
  echo "❌ 找不到主网卡设备，退出。"
  exit 1
fi
echo "✅ 主网卡接口为：\$DEV"

echo "🧹 清理旧的 tc 限速规则..."
sudo tc qdisc del dev "\$DEV" root 2>/dev/null || echo "✅ 无旧 root qdisc 规则"
sudo tc qdisc del dev "\$DEV" ingress 2>/dev/null || echo "✅ 无旧 ingress 规则"
sudo tc qdisc del dev ifb0 root 2>/dev/null || echo "✅ 无 ifb0 root 规则"

echo "📤 设置上传限速：\$UPLOAD_LIMIT"
if sudo tc qdisc add dev "\$DEV" root handle 1: htb default 12; then
  echo "✅ 上传限速主队列设置成功"
else
  echo "❌ 上传限速主队列设置失败"
  exit 1
fi

if sudo tc class add dev "\$DEV" parent 1: classid 1:1 htb rate "\$UPLOAD_LIMIT"; then
  echo "✅ 上传限速主类设置成功"
else
  echo "❌ 上传限速主类设置失败"
  exit 1
fi

if sudo tc class add dev "\$DEV" parent 1:1 classid 1:12 htb rate "\$UPLOAD_LIMIT"; then
  echo "✅ 上传限速子类设置成功"
else
  echo "❌ 上传限速子类设置失败"
  exit 1
fi

echo "📥 设置下载限速：\$DOWNLOAD_LIMIT"
if sudo tc qdisc add dev "\$DEV" handle ffff: ingress; then
  echo "✅ 下载限速入口队列设置成功"
else
  echo "❌ 下载限速入口队列设置失败"
  exit 1
fi

if sudo tc filter add dev "\$DEV" parent ffff: protocol ip u32 match u32 0 0 action mirred egress redirect dev ifb0; then
  echo "✅ 下载限速过滤器设置成功"
else
  echo "❌ 下载限速过滤器设置失败"
  exit 1
fi

if sudo tc qdisc add dev ifb0 root handle 1: htb default 12; then
  echo "✅ ifb0 根队列设置成功"
else
  echo "❌ ifb0 根队列设置失败"
  exit 1
fi

if sudo tc class add dev ifb0 parent 1: classid 1:1 htb rate "\$DOWNLOAD_LIMIT"; then
  echo "✅ ifb0 主类设置成功"
else
  echo "❌ ifb0 主类设置失败"
  exit 1
fi

if sudo tc class add dev ifb0 parent 1:1 classid 1:12 htb rate "\$DOWNLOAD_LIMIT"; then
  echo "✅ ifb0 子类设置成功"
else
  echo "❌ ifb0 子类设置失败"
  exit 1
fi

echo -e "\\n==== ✅ 限速配置完成 ===="
echo "📤 上传限速：\$UPLOAD_LIMIT"
echo "📥 下载限速：\$DOWNLOAD_LIMIT"

echo -e "\\n==== 当前 tc 配置 ===="
sudo tc qdisc show dev "\$DEV"
sudo tc class show dev "\$DEV"
sudo tc qdisc show dev ifb0
sudo tc class show dev ifb0
EOF

echo "==== 3. 给虚拟机内配置脚本添加执行权限 ===="
multipass exec "$VM_NAME" -- chmod +x "$CONFIG_SCRIPT"
echo "✅ 赋予执行权限完成"

echo "==== 4. 执行虚拟机内限速配置脚本 ===="
multipass exec "$VM_NAME" -- bash "$CONFIG_SCRIPT"
echo "✅ 虚拟机限速配置脚本执行完成"
