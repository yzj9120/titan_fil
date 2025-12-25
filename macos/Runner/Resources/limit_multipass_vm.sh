#!/bin/bash
# ===================================================
# Script description:
# Set upload and download speed limits for the first running multipass VM,
# and configure the speed limits inside the virtual machine, with detailed execution feedback.
#
# Usage:
# ./limit_multipass_vm.sh [upload speed limit] [download speed limit]
# For example:
# ./limit_multipass_vm.sh 512kbit 2mbit
# Default upload/download speed limit is 1mbit
# ===================================================

set -euo pipefail

UPLOAD_LIMIT="${1:-10mbit}"
DOWNLOAD_LIMIT="${2:-10mbit}"

VM_NAME=$(/usr/local/bin/multipass list --format csv | tail -n +2 | head -n 1 | cut -d ',' -f1 || true)

if [[ -z "$VM_NAME" ]]; then
  echo "No running virtual machine found, exiting script."
  exit 1
fi

CONFIG_SCRIPT="/tmp/set_tc_limit.sh"

/usr/local/bin/multipass exec "$VM_NAME" -- bash -c "cat > $CONFIG_SCRIPT" <<EOF
#!/bin/bash
set -euo pipefail

UPLOAD_LIMIT="$UPLOAD_LIMIT"
DOWNLOAD_LIMIT="$DOWNLOAD_LIMIT"

echo "==== Inside VM: Starting speed limit configuration ===="

install_pkg() {
  local pkg="\$1"
  if ! command -v "\$pkg" &> /dev/null; then
    echo "Installing package: \$pkg"
    local tries=0 max_tries=10
    while sudo fuser /var/lib/dpkg/lock >/dev/null 2>&1; do
      ((tries++))
      if (( tries > max_tries )); then
        echo "Exceeded maximum waiting time, dpkg lock not released, installation failed"
        exit 1
      fi
      echo "Waiting for dpkg lock to be released... (Attempt \$tries)"
      sleep 3
    done
    sudo apt-get update -qq
    if sudo apt-get install -y "\$pkg"; then
      echo "Package \$pkg installed successfully"
    else
      echo "Package \$pkg installation failed"
      exit 1
    fi
  else
    echo "Package \$pkg is already installed"
  fi
}

install_pkg tc

# Load ifb module
if ! lsmod | grep -q '^ifb'; then
  echo "Loading ifb module..."
  if sudo modprobe ifb; then
    echo "ifb module loaded successfully"
  else
    echo "Failed to load ifb module (may already be loaded or not supported)"
  fi
else
  echo "ifb module is already loaded"
fi

# Create ifb0 device if not exists
if ! ip link show ifb0 &>/dev/null; then
  echo "Creating ifb0 device..."
  if sudo ip link add ifb0 type ifb; then
    echo "ifb0 device created successfully"
  else
    echo "Failed to create ifb0 device (may already exist)"
  fi
else
  echo "ifb0 device already exists"
fi

if sudo ip link set ifb0 up; then
  echo "ifb0 device is now up"
else
  echo "Failed to bring up ifb0 device"
  exit 1
fi

DEV=\$(ip route get 8.8.8.8 2>/dev/null | awk '{print \$5}')
if [[ -z "\$DEV" ]]; then
  echo "Could not find main network interface, exiting."
  exit 1
fi

echo "🧹 Cleaning up old tc speed limit rules..."
sudo tc qdisc del dev "\$DEV" root 2>/dev/null || echo "No old root qdisc rule"
sudo tc qdisc del dev "\$DEV" ingress 2>/dev/null || echo "No old ingress rule"
sudo tc qdisc del dev ifb0 root 2>/dev/null || echo "No old ifb0 root rule"

echo "📤 Setting upload speed limit: \$UPLOAD_LIMIT"
if sudo tc qdisc add dev "\$DEV" root handle 1: htb default 12; then
  echo "Upload speed limit main queue set successfully"
else
  echo "Failed to set upload speed limit main queue"
  exit 1
fi

if sudo tc class add dev "\$DEV" parent 1: classid 1:1 htb rate "\$UPLOAD_LIMIT"; then
  echo "Upload speed limit main class set successfully"
else
  echo "Failed to set upload speed limit main class"
  exit 1
fi

if sudo tc class add dev "\$DEV" parent 1:1 classid 1:12 htb rate "\$UPLOAD_LIMIT"; then
  echo "Upload speed limit sub-class set successfully"
else
  echo "Failed to set upload speed limit sub-class"
  exit 1
fi

if sudo tc qdisc add dev "\$DEV" handle ffff: ingress; then
  echo "Download speed limit ingress queue set successfully"
else
  echo "Failed to set download speed limit ingress queue"
  exit 1
fi

if sudo tc filter add dev "\$DEV" parent ffff: protocol ip u32 match u32 0 0 action mirred egress redirect dev ifb0; then
  echo "Download speed limit filter set successfully"
else
  echo "Failed to set download speed limit filter"
  exit 1
fi

if sudo tc qdisc add dev ifb0 root handle 1: htb default 12; then
  echo " ifb0 root queue set successfully"
else
  echo "Failed to set ifb0 root queue"
  exit 1
fi

if sudo tc class add dev ifb0 parent 1: classid 1:1 htb rate "\$DOWNLOAD_LIMIT"; then
  echo "ifb0 main class set successfully"
else
  echo "Failed to set ifb0 main class"
  exit 1
fi

if sudo tc class add dev ifb0 parent 1:1 classid 1:12 htb rate "\$DOWNLOAD_LIMIT"; then
  echo "ifb0 sub-class set successfully"
else
  echo "Failed to set ifb0 sub-class"
  exit 1
fi

echo "Upload speed limit: \$UPLOAD_LIMIT"
echo "Download speed limit: \$DOWNLOAD_LIMIT"

echo -e "\\n==== Current tc configuration ===="
sudo tc qdisc show dev "\$DEV"
sudo tc class show dev "\$DEV"
sudo tc qdisc show dev ifb0
sudo tc class show dev ifb0
EOF

/usr/local/bin/multipass exec "$VM_NAME" -- chmod +x "$CONFIG_SCRIPT"
echo "Execute permission granted"

/usr/local/bin/multipass exec "$VM_NAME" -- bash "$CONFIG_SCRIPT"
echo "Speed limit configuration script executed inside the virtual machine"
