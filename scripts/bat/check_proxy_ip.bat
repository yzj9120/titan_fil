@echo off
setlocal enabledelayedexpansion
chcp 65001 > nul
title "Fast VPN/Proxy Checker"

:: 初始化变量
set "local_ip=unknown"
set "proxy_ip=unknown"
set "proxy_process=false"
set "proxy_working=false"
set "proxy_type=unknown"
set "vpn_process=unknown"
set "vpn_name=unknown"

:: 快速检测常见VPN/代理进程（使用tasklist替代wmic避免错误）
set "vpn_list=clash v2ray shadowsocks openvpn wireguard nordvpn expressvpn protonvpn"

for %%i in (%vpn_list%) do (
    tasklist /FI "IMAGENAME eq %%i*" 2>nul | findstr /i "%%i" >nul && (
        set "proxy_process=true"
        set "vpn_process=%%i"
    )
)

:: 快速检查网络适配器中的VPN
for /f "tokens=*" %%a in ('netsh interface show interface ^| findstr /i "VPN TAP"') do (
    set "vpn_name=%%a"
    set "proxy_process=true"
)

:: 检查curl是否存在
where curl >nul 2>&1
if errorlevel 1 (
    echo {"error": "curl not found"}
    exit /b
)

:: 获取本地IP（直接执行，不并行）
for /f "tokens=*" %%a in ('curl -s --max-time 3 https://ipinfo.io/ip 2^>nul') do set "local_ip=%%a"

:: 定义常见代理端口
set "proxy_ports=7890 8080 8888 1080 10808"

:: 检测HTTP代理（顺序执行，避免文件冲突）
for %%p in (%proxy_ports%) do (
    if "!proxy_ip!"=="unknown" (
        for /f "tokens=*" %%a in ('curl -s --max-time 3 --proxy http://127.0.0.1:%%p https://ipinfo.io/ip 2^>nul') do (
            set "proxy_ip=%%a"
            set "proxy_type=http:%%p"
        )
    )
)

:: 检测SOCKS5代理（顺序执行，避免文件冲突）
for %%p in (%proxy_ports%) do (
    if "!proxy_ip!"=="unknown" (
        for /f "tokens=*" %%a in ('curl -s --max-time 3 --socks5-hostname 127.0.0.1:%%p https://ipinfo.io/ip 2^>nul') do (
            set "proxy_ip=%%a"
            set "proxy_type=socks5:%%p"
        )
    )
)

:: 检查系统代理设置（快速注册表查询）
reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings" /v ProxyEnable 2>nul | findstr /i "0x1" >nul && (
    set "proxy_process=true"
    if "!proxy_type!"=="unknown" set "proxy_type=system"
)

:: 检查代理是否生效
if not "!proxy_ip!"=="unknown" if not "!local_ip!"=="!proxy_ip!" (
    set "proxy_working=true"
)

:: 输出为标准 JSON
echo {
echo     "proxy_process": "!proxy_process!",
echo     "proxy_working": "!proxy_working!",
echo     "proxy_type": "!proxy_type!",
echo     "local_ip": "!local_ip!",
echo     "proxy_ip": "!proxy_ip!",
echo     "vpn_process": "!vpn_process!",
echo     "vpn_adapter": "!vpn_name!"
echo }