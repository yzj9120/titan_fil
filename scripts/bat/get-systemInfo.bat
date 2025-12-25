@echo off
setlocal enabledelayedexpansion

:: 设置默认磁盘为C，如果用户提供了参数则使用参数
set DEFAULT_DRIVE=C
set DRIVE_LETTER=%DEFAULT_DRIVE%
if not "%1"=="" set DRIVE_LETTER=%1

:: 获取设备名称
for /f "tokens=* delims=" %%a in ('wmic computersystem get name /value ^| find "="') do set DEVICE_NAME=%%a
set DEVICE_NAME=%DEVICE_NAME:Name=%

:: 获取 CPU 信息
for /f "tokens=2 delims==" %%a in ('wmic cpu get NumberOfCores /value ^| find "="') do set CPU_CORES=%%a
for /f "tokens=2 delims==" %%a in ('wmic cpu get NumberOfLogicalProcessors /value ^| find "="') do set CPU_THREADS=%%a
for /f "skip=1 delims=" %%a in ('wmic cpu get Name') do if not defined CPU_NAME set "CPU_NAME=%%a"
for /f "tokens=2 delims==" %%a in ('wmic cpu get MaxClockSpeed /value ^| find "="') do set CPU_MAX_SPEED=%%a
set /a CPU_MAX_SPEED_GHZ=%CPU_MAX_SPEED%/1000

:: 获取内存信息（精确）
for /f %%a in ('powershell -nologo -command "[math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB, 1)"') do set MEM_TOTAL_GB=%%a
for /f %%a in ('powershell -nologo -command "[math]::Round(((Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory * 1KB) / 1GB, 1)"') do set MEM_FREE_GB=%%a
for /f %%a in ('powershell -nologo -command "[math]::Round(((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory - (Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory * 1KB) / 1GB, 1)"') do set MEM_USED_GB=%%a

:: 获取磁盘信息（使用DRIVE_LETTER变量）
for /f %%a in ('powershell -nologo -command "Get-CimInstance Win32_LogicalDisk -Filter 'DeviceID=''%DRIVE_LETTER%:''' | ForEach-Object { [math]::Round($_.Size / 1GB, 1) }"') do set DISK_TOTAL_GB=%%a
for /f %%a in ('powershell -nologo -command "Get-CimInstance Win32_LogicalDisk -Filter 'DeviceID=''%DRIVE_LETTER%:''' | ForEach-Object { [math]::Round($_.FreeSpace / 1GB, 1) }"') do set DISK_FREE_GB=%%a

for /f %%a in ('powershell -command "[math]::Round(%DISK_TOTAL_GB% - %DISK_FREE_GB%, 1)"') do (
    set DISK_USED_GB=%%a
)
:: 获取系统类型
for /f "tokens=* delims=" %%a in ('wmic os get OSArchitecture /value ^| find "="') do set OS_ARCH=%%a
set OS_ARCH=%OS_ARCH:OSArchitecture=%

:: 获取设备ID和产品ID
for /f "tokens=2 delims==" %%a in ('wmic csproduct get uuid /value ^| find "="') do set DEVICE_ID=%%a
for /f "tokens=2 delims==" %%a in ('wmic os get serialnumber /value ^| find "="') do set PRODUCT_ID=%%a

:: 输出 JSON 格式
echo {
echo   "device": {
echo     "name": "%DEVICE_NAME%",
echo     "id": "%DEVICE_ID%",
echo     "product_id": "%PRODUCT_ID%"
echo   },
echo   "cpu": {
echo     "model": "%CPU_NAME%",
echo     "cores": %CPU_CORES%,
echo     "physical_cores": %CPU_THREADS%,
echo     "max_speed_ghz": %CPU_MAX_SPEED_GHZ%
echo   },
echo   "memory": {
echo     "total_gb": %MEM_TOTAL_GB%,
echo     "used_gb": %MEM_USED_GB%,
echo     "free_gb": %MEM_FREE_GB%
echo   },
echo   "disk": {
echo     "drive": "%DRIVE_LETTER%:",
echo     "total": %DISK_TOTAL_GB%,
echo     "used": %DISK_USED_GB%,
echo     "available": %DISK_FREE_GB%
echo   },
echo   "system": {
echo     "type": "%OS_ARCH%",
echo     "touch_support": "null"
echo   }
echo }

endlocal