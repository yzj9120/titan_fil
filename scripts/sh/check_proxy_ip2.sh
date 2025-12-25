#!/bin/bash

# 设置初始变量
local_ip="unknown"
proxy_ip="unknown"
proxy_process=false
proxy_working=false
proxy_type="unknown"
vpn_process="unknown"
vpn_name="unknown"

# 常见VPN/代理进程列表
vpn_list=("clash" "v2ray" "shadowsocks" "openvpn" "wireguard" "nordvpn" "expressvpn" "protonvpn")

# 检测VPN/代理进程是否存在
for vpn in "${vpn_list[@]}"; do
    if pgrep -fi "$vpn" > /dev/null 2>&1; then
        proxy_process=true
        vpn_process=$vpn
        break
    fi
done

# 检测网络适配器名称包含 VPN 或 TAP （macOS和Linux差异，macOS用ifconfig，Linux用ip link）
# 这里用 ifconfig，过滤包含 VPN/TAP 的网卡名称
if ifconfig | grep -Ei "vpn|tap" > /dev/null 2>&1; then
    vpn_name=$(ifconfig | grep -Ei "vpn|tap" | head -n 1 | awk '{print $1}')
    proxy_process=true
fi

# 检查 curl 是否安装
if ! command -v curl &>/dev/null; then
    echo '{"error": "curl not found"}'
    exit 1
fi

# 获取本地IP（无代理）
local_ip=$(curl -s --max-time 3 https://ipinfo.io/ip)
if [[ -z "$local_ip" ]]; then local_ip="unknown"; fi

# 代理端口列表
proxy_ports=(7890 8080 8888 1080 10808)

# 检测HTTP代理
for port in "${proxy_ports[@]}"; do
    if [[ "$proxy_ip" == "unknown" ]]; then
        test_ip=$(curl -s --max-time 3 --proxy http://127.0.0.1:$port https://ipinfo.io/ip)
        if [[ -n "$test_ip" && "$test_ip" != "$local_ip" ]]; then
            proxy_ip=$test_ip
            proxy_type="http:$port"
            break
        fi
    fi
done

# 检测SOCKS5代理
for port in "${proxy_ports[@]}"; do
    if [[ "$proxy_ip" == "unknown" ]]; then
        test_ip=$(curl -s --max-time 3 --socks5-hostname 127.0.0.1:$port https://ipinfo.io/ip)
        if [[ -n "$test_ip" && "$test_ip" != "$local_ip" ]]; then
            proxy_ip=$test_ip
            proxy_type="socks5:$port"
            break
        fi
    fi
done

# macOS/Linux没注册表，这里检测系统代理环境变量（http_proxy / https_proxy）
if [[ -n "$http_proxy" || -n "$https_proxy" ]]; then
    proxy_process=true
    if [[ "$proxy_type" == "unknown" ]]; then
        proxy_type="system"
    fi
fi

# 判断代理是否生效
if [[ "$proxy_ip" != "unknown" && "$proxy_ip" != "$local_ip" ]]; then
    proxy_working=true
fi

# 输出 JSON
cat <<EOF
{
    "proxy_process": $proxy_process,
    "proxy_working": $proxy_working,
    "proxy_type": "$proxy_type",
    "local_ip": "$local_ip",
    "proxy_ip": "$proxy_ip",
    "vpn_process": "$vpn_process",
    "vpn_adapter": "$vpn_name"
}
EOF
