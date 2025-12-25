@echo off
setlocal

:: 设置版本号
set version=1.0.8_108

:: 设置程序名称
set APP_NAME=titan_fil

:: 动态获取项目根目录
set PROJECT_ROOT=%~dp0
if %PROJECT_ROOT:~-1%==\ set PROJECT_ROOT=%PROJECT_ROOT:~0,-1%
echo PROJECT_ROOT: %PROJECT_ROOT%

:: 设置Flutter SDK的路径
set FLUTTER_SDK=D:\flutter

:: 设置应用程序的主文件
set FLUTTER_APP=%PROJECT_ROOT%\lib\main.dart

:: 设置应用程序的名称
set FLUTTER_APPNAME=MyFlutterApp

:: 设置编译的模式，可以是debug或release
set FLUTTER_BUILDMODE=release

:: 添加Flutter到环境变量
set PATH=%FLUTTER_SDK%\bin;%PATH%

:: 设置Inno Setup的路径
set INNO_SETUP_PATH="C:\Program Files (x86)\Inno Setup 6\ISCC.exe"

:: 动态设置Inno Setup脚本的路径（假设脚本位于项目根目录）
set INNO_SETUP_SCRIPT=%PROJECT_ROOT%\titan4_run6_3.iss

:: 获取当前日期和时间（使用 PowerShell）
for /f "delims=" %%i in ('powershell -Command "(Get-Date).ToString('yyyy-MM-dd_HH-mm-ss')"') do set datetime=%%i

:: 打印获取的日期时间
echo datetime: %datetime%

:: 检查并创建构建目录
if not exist "%PROJECT_ROOT%\build" (
    mkdir "%PROJECT_ROOT%\build"
    if errorlevel 1 (
        echo Failed to create build directory.
        exit /b 1
    )
)

:: 清理先前的构建
call flutter clean
if errorlevel 1 (
    echo Flutter clean failed.
    exit /b 1
)

:: 构建应用程序
call flutter build windows --%FLUTTER_BUILDMODE%
if errorlevel 1 (
    echo Build failed.
    exit /b 1
)

:: 执行Inno Setup脚本打包安装程序
call %INNO_SETUP_PATH% %INNO_SETUP_SCRIPT%
if errorlevel 1 (
    echo Inno Setup compilation failed.
    exit /b 1
)

:: 检查生成的安装程序是否存在
set GENERATED_EXE_PATH=%PROJECT_ROOT%\build\%APP_NAME%.exe
for %%A in ("%GENERATED_EXE_PATH%") do set GENERATED_EXE_PATH=%%~fA

if not exist "%GENERATED_EXE_PATH%" (
    echo The generated executable %GENERATED_EXE_PATH% does not exist.
    exit /b 1
)

:: 重命名并移动生成的安装程序文件 datetime
set EXE_NAME=%APP_NAME%_win_%version%_v%datetime%.exe
set DESTINATION_PATH=%PROJECT_ROOT%\build\%EXE_NAME%

:: 确保目标目录存在
if not exist "%PROJECT_ROOT%\build" (
    mkdir "%PROJECT_ROOT%\build"
    if errorlevel 1 (
        echo Failed to create build directory.
        exit /b 1
    )
)

:: 移动文件
move /y "%GENERATED_EXE_PATH%" "%DESTINATION_PATH%"
if errorlevel 1 (
    echo Failed to rename or move the generated executable.
    echo Source: %GENERATED_EXE_PATH%
    echo Destination: %DESTINATION_PATH%
    exit /b 1
)

:: 打印构建完成的信息
echo Build completed. The installer is located at %DESTINATION_PATH%.

:: 自动启动安装程序
echo Starting the installer...
start "" "%DESTINATION_PATH%"

endlocal