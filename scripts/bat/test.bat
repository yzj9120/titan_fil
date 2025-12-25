@echo off
setlocal enabledelayedexpansion
chcp 65001 > nul
title "Fast VPN/Proxy Checker (Parallel)"

:: 初始化
set "local_ip=unknown"
set "proxy_ip=unknown"
set "proxy_type=unknown"
set "proxy_process=false"
set "proxy_working=false"
set "vpn_process=unknown"
set "vpn_name=unknown"

:: 定义临时文件
set "tmp_dir=%temp%\proxycheck"
if exist "%tmp_dir%" rd /s /q "%tmp_dir%"
mkdir "%tmp_dir%"

:: VPN进程检测
set "vpn_list=clash v2ray shadowsocks openvpn wireguard nordvpn expressvpn protonvpn"
for %%i in (%vpn_list%) do (
    tasklist /FI "IMAGENAME eq %%i*" 2>nul | findstr /i "%%i" >nul && (
        set "proxy_process=true"
        set "vpn_process=%%i"
    )
)

:: 网络适配器检测
for /f "tokens=*" %%a in ('netsh interface show interface ^| findstr /i "VPN TAP"') do (
    set "vpn_name=%%a"
    set "proxy_process=true"
)

:: 检查curl
where curl >nul 2>&1
if errorlevel 1 (
    echo {"error": "curl not found"}
    exit /b
)

:: 获取本地 IP（同步执行）
for /f "tokens=*" %%a in ('curl -s --max-time 3 https://ipinfo.io/ip 2^>nul') do set "local_ip=%%a"

:: 代理端口列表
set "proxy_ports=7890 8080 8888 1080 10808"

:: 并行检测 HTTP 代理
for %%p in (%proxy_ports%) do (
    start /b cmd /c curl -s --max-time 3 --proxy http://127.0.0.1:%%p https://ipinfo.io/ip > "%tmp_dir%\http_%%p.txt"
)

:: 并行检测 SOCKS5 代理
for %%p in (%proxy_ports%) do (
    start /b cmd /c curl -s --max-time 3 --socks5-hostname 127.0.0.1:%%p https://ipinfo.io/ip > "%tmp_dir%\socks5_%%p.txt"
)

:: 等待并发任务完成（最多 5 秒）
timeout /t 5 >nul

:: 读取返回结果
for %%p in (%proxy_ports%) do (
    if exist "%tmp_dir%\http_%%p.txt" (
        set /p out=<"%tmp_dir%\http_%%p.txt"
        if defined out if "!out!" neq "!local_ip!" (
            set "proxy_ip=!out!"
            set "proxy_type=http:%%p"
        )
    )
    if "!proxy_ip!"=="unknown" if exist "%tmp_dir%\socks5_%%p.txt" (
        set /p out=<"%tmp_dir%\socks5_%%p.txt"
        if defined out if "!out!" neq "!local_ip!" (
            set "proxy_ip=!out!"
            set "proxy_type=socks5:%%p"
        )
    )
)

:: 检查系统代理
reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings" /v ProxyEnable 2>nul | findstr /i "0x1" >nul && (
    set "proxy_process=true"
    if "!proxy_type!"=="unknown" set "proxy_type=system"
)

:: 判断是否生效
if not "!proxy_ip!"=="unknown" if not "!local_ip!"=="!proxy_ip!" (
    set "proxy_working=true"
)

:: 输出 JSON
echo {
echo     "proxy_process": "!proxy_process!",
echo     "proxy_working": "!proxy_working!",
echo     "proxy_type": "!proxy_type!",
echo     "local_ip": "!local_ip!",
echo     "proxy_ip": "!proxy_ip!",
echo     "vpn_process": "!vpn_process!",
echo     "vpn_name": "!vpn_name!"
echo }

:: 清理临时文件夹
rd /s /q "%tmp_dir%" >nul 2>&1

