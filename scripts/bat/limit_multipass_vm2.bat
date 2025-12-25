@echo off
chcp 65001 > nul
setlocal enabledelayedexpansion

:: ===== 配置部分 =====
set "bandwidth=1mbit"
set "burst=32kbit"
set "latency=400ms"

:: ===== 步骤 1：检测运行中的 Multipass 实例 =====
echo [1/5] 正在检查 Multipass 虚拟机...
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
set "nic_name="

for /f "tokens=2 delims=:" %%i in ('type nic_info.txt ^| findstr /v "lo:" ^| findstr "UP"') do (
    set "nic_name=%%i"
    set "nic_name=!nic_name: =!"
    goto :nic_detected
)
del nic_info.txt

:nic_detected
if "!nic_name!"=="" (
    echo ✗ 未检测到网卡，退出
    exit /b 1
)
echo ✓ 检测到网卡: !nic_name!

:: ===== 步骤 3：删除旧限速规则 =====
echo [3/5] 删除旧的限速规则...
multipass exec %target_vm% -- sudo tc qdisc del dev !nic_name! root > nul 2>&1
multipass exec %target_vm% -- sudo tc qdisc del dev !nic_name! ingress > nul 2>&1

:: ===== 步骤 4：设置上传（出站）限速 =====
echo [4/5] 设置上传限速: %bandwidth%
multipass exec %target_vm% -- sudo tc qdisc add dev !nic_name! root tbf rate %bandwidth% burst %burst% latency %latency%
if errorlevel 1 (
    echo ✗ 上传限速设置失败
    goto :verify
)
echo ✓ 上传限速设置成功

:: ===== 步骤 5：设置下载（入站）限速 =====
echo [5/5] 设置下载限速: %bandwidth%
multipass exec %target_vm% -- sudo tc qdisc add dev !nic_name! ingress
multipass exec %target_vm% -- sudo tc filter add dev !nic_name! parent ffff: protocol ip u32 match u32 0 0 police rate %bandwidth% burst %burst% drop flowid :1
if errorlevel 1 (
    echo ✗ 下载限速设置失败
    goto :verify
)
echo ✓ 下载限速设置成功

:: ===== 步骤 6：验证带宽限制 =====
:verify
echo [6/6] 验证限速规则...
multipass exec %target_vm% -- tc qdisc show dev !nic_name! > tc_out.txt
findstr /i "tbf" tc_out.txt > nul
if errorlevel 1 (
    echo ✗ 未检测到上传限速规则
) else (
    echo ✓ 上传限速规则存在
)

findstr /i "ingress" tc_out.txt > nul
if errorlevel 1 (
    echo ✗ 未检测到下载限速规则
) else (
    echo ✓ 下载限速规则存在
)

:: ===== 清理 =====
del tc_out.txt > nul 2>&1
echo 脚本执行完毕。
pause
