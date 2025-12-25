@echo off
setlocal enabledelayedexpansion
chcp 65001 >nul

:: ------------------------
:: 1. 计算项目根目录（脚本在 scripts\bat，项目根目录为上上级目录）
set SCRIPT_DIR=%~dp0
if "%SCRIPT_DIR:~-1%"=="\" set SCRIPT_DIR=%SCRIPT_DIR:~0,-1%
for %%a in ("%SCRIPT_DIR%\..\..") do set PROJECT_ROOT=%%~fa
echo PROJECT_ROOT corrected to: %PROJECT_ROOT%

:: ------------------------
:: 2. 设置基本变量
set version=1.1.0_110
set APP_NAME=titan_fil

:: Flutter 可执行文件路径
set FLUTTER_EXE=%PROJECT_ROOT%\build\windows\x64\runner\Release\%APP_NAME%.exe

:: Flutter SDK路径
set FLUTTER_SDK=D:\flutter

:: Inno Setup编译器路径
set INNO_SETUP_PATH="C:\Program Files (x86)\Inno Setup 6\ISCC.exe"

:: Inno Setup脚本路径（项目根目录）
set INNO_SETUP_SCRIPT=%PROJECT_ROOT%\scripts\bat\titan4_run6_3.iss

:: 签名工具路径（请根据实际路径修改）
set SIGNTOOL="C:\Users\Admin\AppData\Local\electron-builder\Cache\winCodeSign\winCodeSign-2.6.0\windows-10\x64\signtool.exe"

:: 输出目录（安装包存放）
set INSTALLER_OUTPUT_DIR=%PROJECT_ROOT%\build

:: 获取当前日期时间，用于版本号命名
for /f "delims=" %%i in ('powershell -Command "(Get-Date).ToString('yyyy-MM-dd_HH-mm-ss')"') do set datetime=%%i
echo Build datetime: %datetime%

:: 添加Flutter到环境变量
set PATH=%FLUTTER_SDK%\bin;%PATH%

:: ------------------------
:: 3. 确保构建目录存在
if not exist "%INSTALLER_OUTPUT_DIR%" (
    mkdir "%INSTALLER_OUTPUT_DIR%"
    if errorlevel 1 (
        echo Failed to create build directory.
        exit /b 1
    )
)

:: ------------------------
:: 4. 清理 Flutter 项目
echo ========================
echo 1. Flutter clean
echo ========================
call flutter clean
if errorlevel 1 (
    echo Flutter clean failed.
    exit /b 1
)

:: ------------------------
:: 5. 构建 Flutter windows release
echo ========================
echo 2. Flutter build windows release
echo ========================
call flutter build windows --release
if errorlevel 1 (
    echo Flutter build failed.
    exit /b 1
)

:: ------------------------
:: 6. 签名 Flutter 生成的 exe
echo ========================
echo 3. Signing Flutter executable: %FLUTTER_EXE%
if not exist "%FLUTTER_EXE%" (
    echo Flutter exe not found for signing: %FLUTTER_EXE%
    pause
    exit /b 1
)

%SIGNTOOL% sign ^
    /tr http://timestamp.sectigo.com ^
    /td sha256 ^
    /fd sha256 ^
    /a "%FLUTTER_EXE%"

if errorlevel 1 (
    echo Signing Flutter executable failed.
    pause
    exit /b 1
)
echo Flutter exe signed successfully.
echo 验证安装包签名...
%SIGNTOOL% verify /pa /v "%FLUTTER_EXE%"

if errorlevel 1 (
    echo 签名验证失败！
    pause
    exit /b 1
) else (
    echo 签名验证成功！
)

:: ------------------------
:: 7. 使用 Inno Setup 编译安装程序
echo ========================
echo 4. Compile Inno Setup installer
echo ========================
call %INNO_SETUP_PATH% %INNO_SETUP_SCRIPT%
if errorlevel 1 (
    echo Inno Setup compilation failed.
    exit /b 1
)

:: ------------------------
:: 8. 计算安装包路径（Inno 编译后默认输出到 build 目录，文件名固定，需根据你的脚本确认）
set GENERATED_EXE_PATH=%PROJECT_ROOT%\scripts\bat\build\%APP_NAME%.exe

if not exist "%GENERATED_EXE_PATH%" (
    echo The generated installer executable %GENERATED_EXE_PATH% does not exist.
    exit /b 1
)

:: ------------------------
:: 9. 重命名安装包
set EXE_NAME=%APP_NAME%_win_%version%_v%datetime%.exe
set DESTINATION_PATH=%INSTALLER_OUTPUT_DIR%\%EXE_NAME%

move /y "%GENERATED_EXE_PATH%" "%DESTINATION_PATH%"
if errorlevel 1 (
    echo Failed to rename or move the generated installer executable.
    echo Source: %GENERATED_EXE_PATH%
    echo Destination: %DESTINATION_PATH%
    exit /b 1
)

:: ------------------------
:: 10. 签名安装包 exe
echo ========================
echo 5. Signing Installer executable: %DESTINATION_PATH%
echo ========================

%SIGNTOOL% sign ^
    /tr http://timestamp.sectigo.com ^
    /td sha256 ^
    /fd sha256 ^
    /a "%DESTINATION_PATH%"

if errorlevel 1 (
    echo Signing installer executable failed.
    pause
    exit /b 1
)
echo Installer exe signed successfully.

echo 验证安装包签名...
%SIGNTOOL% verify /pa /v "%DESTINATION_PATH%"

if errorlevel 1 (
    echo 签名验证失败！
    pause
    exit /b 1
) else (
    echo 签名验证成功！
)

:: ------------------------
:: 11. 构建完成，启动安装包
echo ========================
echo Build, signing, packaging complete!
echo Installer located at: %DESTINATION_PATH%
echo ========================

echo Starting the installer...
start "" "%DESTINATION_PATH%"

endlocal
pause
