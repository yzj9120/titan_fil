@echo off
REM 切换 UTF-8 编码，防止中文乱码
chcp 65001 >nul

REM 1. signtool.exe 路径
set SIGNTOOL="C:\Users\Admin\AppData\Local\electron-builder\Cache\winCodeSign\winCodeSign-2.6.0\windows-10\x64\signtool.exe"

REM 2. 要签名的文件路径
set FILE="E:\hz\t4\titan_fil\build\windows\x64\runner\Release\titan_fil.exe"

echo 正在对文件签名: %FILE%
%SIGNTOOL% sign ^
  /tr http://timestamp.sectigo.com ^
  /td sha256 ^
  /fd sha256 ^
  /a %FILE%

if %ERRORLEVEL% NEQ 0 (
    echo 签名失败，请检查证书或参数设置
    pause
    exit /b
)

echo.
echo 签名完成，正在验证签名有效性...
%SIGNTOOL% verify /pa /v %FILE%

if %ERRORLEVEL% EQU 0 (
    echo.
    echo =========================
    echo 签名验证成功！
    echo =========================
) else (
    echo.
    echo =========================
    echo 签名验证失败！
    echo =========================
)

pause
