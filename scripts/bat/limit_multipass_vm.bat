@echo off
chcp 65001 > nul
setlocal enabledelayedexpansion

:: ===== 配置部分 =====
set "bandwidth=5mbit"   :: 可修改为其他带宽值
set "burst=32kbit"
set "latency=400ms"

:: ===== 步骤 1：检测运行中的 Multipass 实例 =====
echo [1/5] 正在检查 Multipass 虚拟机...
:: 过滤掉表头 + 精确判断第三列是 Running
:: 获取 multipass list 的第一行（跳过表头），第一列就是实例名
for /f "skip=1 tokens=1" %%a in ('multipass list') do (
    set "target_vm=%%a"
    goto :vm_found
)



echo 错误：未找到运行中的 Multipass 虚拟机
exit /b 1

:vm_found
echo ✓ 目标虚拟机: %target_vm%

:: ===== 步骤 2：获取网卡名称 =====
echo [2/5] 正在获取虚拟机网卡信息...
multipass exec %target_vm% -- ip -o link show > nic_info.txt
set "nic_name=eth0"  :: 默认值

for /f "tokens=2 delims=:" %%i in ('type nic_info.txt ^| findstr /v "lo:" ^| findstr "UP"') do (
    set "nic_name=%%i"
    set "nic_name=!nic_name: =!"
    goto :nic_detected
)
del nic_info.txt

:nic_detected
echo ✓ 检测到网卡: !nic_name!

:: ===== 步骤 3：设置带宽限制 =====
echo [3/5] 正在设置带宽限制: %bandwidth%
echo - 尝试删除旧的限速规则...
multipass exec %target_vm% -- sudo tc qdisc del dev !nic_name! root > nul 2>&1

echo - 添加新的限速规则...
multipass exec %target_vm% -- sudo tc qdisc add dev !nic_name! root tbf rate %bandwidth% burst %burst% latency %latency%
if %errorlevel% neq 0 (
    echo ✗ 设置失败！
    goto :verify
)
echo ✓ 限速规则已添加


:: ===== 步骤 4：验证带宽限制是否生效 =====
:verify
echo [4/5] 正在验证设置状态...
multipass exec %target_vm% -- tc qdisc show dev !nic_name! > tc_out.txt

findstr /i "%bandwidth%" tc_out.txt > nul
if %errorlevel% equ 0 (
    echo ✓ 验证成功：已生效
) else (
    echo ✗ 验证失败：未检测到带宽限制
)

:: ===== 步骤 5：清理并退出 =====
echo [5/5] 清理临时文件...
del nic_info.txt > nul 2>&1
del tc_out.txt > nul 2>&1
echo 脚本执行完毕。

endlocal
pause
