@echo off
echo ========================================
echo   运行浏览器优化脚本 v12.2
echo ========================================
echo.

REM 检查管理员权限
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo 错误：需要管理员权限
    echo 请右键点击此文件，选择"以管理员身份运行"
    pause
    exit /b 1
)

echo 正在优化所有浏览器...
echo.

cd /d "%~dp0"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "scripts\deployment\OPTIMIZE_ALL_v12.2.ps1"

echo.
echo 优化完成！
pause
