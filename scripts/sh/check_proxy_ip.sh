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

# 检测 VPN/TAP 适配器（macOS 用 ifconfig）
if ifconfig | grep -Ei "vpn|tap|utun" > /dev/null 2>&1; then
    vpn_name=$(ifconfig | grep -Ei "vpn|tap|utun" | head -n 1 | awk '{print $1}')
    proxy_process=true
fi

# 检查 curl 是否安装
if ! command -v curl &>/dev/null; then
    echo '{"error": "curl not found"}'
    exit 1
fi

# 获取公网 IP（强制不使用代理）
local_ip=$(env -u http_proxy -u https_proxy -u all_proxy curl -s --noproxy '*' --max-time 3 https://ip.qnnp.me)
#local_ip=$(env -u http_proxy -u https_proxy -u all_proxy curl -s --noproxy '*' --max-time 3 https://api.ipify.org)
if [[ -z "$local_ip" ]]; then local_ip="unknown"; fi

# 检测本地代理端口
proxy_ports=(7890 8080 8888 1080 10808)

# 检测 HTTP 代理
for port in "${proxy_ports[@]}"; do
    if [[ "$proxy_ip" == "unknown" ]]; then
        test_ip=$(curl -s --max-time 3 --proxy http://127.0.0.1:$port https://api.ipify.org)
        if [[ -n "$test_ip" && "$test_ip" != "$local_ip" ]]; then
            proxy_ip=$test_ip
            proxy_type="http:$port"
            break
        fi
    fi
done

# 检测 SOCKS5 代理
for port in "${proxy_ports[@]}"; do
    if [[ "$proxy_ip" == "unknown" ]]; then
        test_ip=$(curl -s --max-time 3 --socks5-hostname 127.0.0.1:$port https://api.ipify.org)
        if [[ -n "$test_ip" && "$test_ip" != "$local_ip" ]]; then
            proxy_ip=$test_ip
            proxy_type="socks5:$port"
            break
        fi
    fi
done

# 检测系统代理变量
if [[ -n "$http_proxy" || -n "$https_proxy" ]]; then
    proxy_process=true
    if [[ "$proxy_type" == "unknown" ]]; then
        proxy_type="system"
    fi
fi

# 如果没有检测到本地代理，但 VPN 开启，并且 local_ip 是公网 IP
if [[ "$proxy_ip" == "unknown" && "$vpn_process" != "unknown" && "$local_ip" != "unknown" ]]; then
    proxy_ip=$local_ip
    proxy_type="vpn"
fi

# 判断代理是否在工作
if [[ "$proxy_ip" != "unknown" && "$proxy_ip" != "$local_ip" ]]; then
    proxy_working=true
elif [[ "$proxy_type" == "vpn" ]]; then
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