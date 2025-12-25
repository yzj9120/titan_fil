@echo off
chcp 65001 >nul
setlocal

REM 设置证书路径和密码
set PFX_PATH=C:\Users\Admin\Desktop\agent-windows\certificate.pfx
set PFX_PASSWORD=123456

REM 设置 signtool 路径
set SIGNTOOL=C:\Users\Admin\AppData\Local\electron-builder\Cache\winCodeSign\winCodeSign-2.6.0\windows-6\signtool.exe

REM 设置目标可执行文件路径
set TARGET_EXE=C:\Users\Admin\Desktop\agent-windows\titan_fil_win_2025-05-30_09-49-52_v1.0.0+10.exe

REM 设置时间戳服务器
set TIMESTAMP_URL=http://timestamp.digicert.com

echo 正在签名：%TARGET_EXE%
"%SIGNTOOL%" sign /f "%PFX_PATH%" /p "%PFX_PASSWORD%" /fd sha256 /t "%TIMESTAMP_URL%" "%TARGET_EXE%"

IF %ERRORLEVEL% EQU 0 (
    echo ✅ 签名成功，正在验证签名完整性...
    "%SIGNTOOL%" verify /pa "%TARGET_EXE%"

    IF %ERRORLEVEL% EQU 0 (
        echo 🟢 签名验证成功，证书受信任。
    ) ELSE (
        echo ⚠️ 签名验证失败，可能是根证书未被信任。
    )
) ELSE (
    echo ❌ 签名失败，错误码：%ERRORLEVEL%
)

endlocal
pause
