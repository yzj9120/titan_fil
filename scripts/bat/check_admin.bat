@echo off
setlocal

:: 调用 PowerShell 检查管理员权限
for /f "usebackq tokens=*" %%A in (`powershell -NoProfile -Command "[bool]([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)"`) do (
    set "isAdmin=%%A"
)

:: 输出结果
if /i "%isAdmin%"=="True" (
    echo 当前为管理员权限运行
    exit /b 0
) else (
    echo 当前不是管理员权限运行，请右键以管理员身份运行
    exit /b 1
)

endlocal
