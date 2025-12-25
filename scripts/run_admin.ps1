$flutterPath = "D:\flutter\bin\flutter.bat"
$projectPath = $PSScriptRoot  # 自动获取当前脚本所在目录

Start-Process -FilePath "powershell" -ArgumentList "-NoExit -NoProfile -ExecutionPolicy Bypass -Command `"cd '$projectPath'; & '$flutterPath' run -d windows`"" -Verb RunAs