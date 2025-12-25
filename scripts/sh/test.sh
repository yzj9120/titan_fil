#!/bin/bash

proxy_group="GLOBAL"

# 获取当前节点名
current_node=$(curl -s http://127.0.0.1:9090/proxies/$proxy_group | jq -r '.now')
echo "当前代理节点名: $current_node"

# 对节点名进行 URL 编码
encoded_node=$(printf '%s' "$current_node" | jq -sRr @uri)
echo "URL编码后节点名: $encoded_node"

# 通过 URL 编码后的节点名请求节点详情
node_info=$(curl -s "http://127.0.0.1:9090/proxies/$encoded_node")
echo "节点详细信息: $node_info"

# 从 JSON 中提取 server 字段（服务器地址）
server=$(echo "$node_info" | jq -r '.server // empty')

if [ -z "$server" ]; then
    echo "未找到服务器地址字段，可能该节点不支持直接查询"
    exit 1
fi

echo "服务器地址: $server"

# 解析服务器地址 IP
ip=$(dig +short "$server" | head -n 1)

if [ -z "$ip" ]; then
    echo "dig 解析失败，尝试 nslookup"
    ip=$(nslookup "$server" | awk '/^Address: / { print $2; exit }')
fi

if [ -z "$ip" ]; then
    echo "无法解析 IP 地址"
    exit 1
fi

echo "代理节点 IP: $ip"

