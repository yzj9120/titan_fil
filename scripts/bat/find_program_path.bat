@echo off
setlocal enabledelayedexpansion

:: 设置 AppId 和程序名（注意加上花括号）
set "AppId={E74359E7-7418-42A4-8A3E-D3DF1D5276B8}"
set "exe_name=titan_fil.exe"

:: 方法1：查 64 位注册表
for /f "tokens=2,*" %%a in (
    'reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\%AppId%_is1" /v "InstallLocation" 2^>nul'
) do (
    set "dir=%%b"
    goto :check
)

:: 方法2：查 32 位注册表
for /f "tokens=2,*" %%a in (
    'reg query "HKLM\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\%AppId%_is1" /v "InstallLocation" 2^>nul'
) do (
    set "dir=%%b"
    goto :check
)

:: 方法3：默认路径
set "dir=C:\titan_fil"

:check
:: 去除尾部反斜杠（如果有）
if "!dir:~-1!"=="\" set "dir=!dir:~0,-1!"

:: 检查程序是否存在，存在则输出路径
if exist "!dir!\%exe_name%" (
    echo !dir!\%exe_name%
    exit /b 0
)

:: 否则返回错误码
exit /b 1
