@echo off
cd /d "%~1"  REM 切换到指定的工作目录
agent.exe --working-dir="%~1" --server-url="https://test4-api.titannet.io" --key="%~2"
