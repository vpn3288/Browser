# ========================================
#  Multi-Browser Anti-Detect - 一键安装脚本
# ========================================
#  版本: v13.7
#  作者: Kiro (AI Development Environment)
#  日期: 2026-05-08
# ========================================

param(
    [switch]$SkipLaunchers = $false
)

$ErrorActionPreference = "Stop"

# 颜色输出函数
function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Type = "INFO"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    
    switch ($Type) {
        "SUCCESS" { Write-Host "[$timestamp] [✓] $Message" -ForegroundColor Green }
        "ERROR"   { Write-Host "[$timestamp] [✗] $Message" -ForegroundColor Red }
        "WARNING" { Write-Host "[$timestamp] [!] $Message" -ForegroundColor Yellow }
        "INFO"    { Write-Host "[$timestamp] [i] $Message" -ForegroundColor Cyan }
        "HEADER"  { Write-Host "`n========================================" -ForegroundColor Magenta
                    Write-Host "  $Message" -ForegroundColor Magenta
                    Write-Host "========================================`n" -ForegroundColor Magenta }
        default   { Write-Host "[$timestamp] $Message" }
    }
}

# 检查管理员权限
function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# 检查并安装Git
function Install-GitIfNeeded {
    Write-ColorOutput "检查Git是否已安装..." "INFO"
    
    $git = Get-Command git -ErrorAction SilentlyContinue
    if ($git) {
        Write-ColorOutput "Git已安装: $($git.Version)" "SUCCESS"
        return $true
    }
    
    Write-ColorOutput "Git未安装，正在安装..." "WARNING"
    
    try {
        # 使用winget安装Git
        winget install --id Git.Git -e --source winget --silent --accept-package-agreements --accept-source-agreements
        
        # 刷新环境变量
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
        
        # 验证安装
        $git = Get-Command git -ErrorAction SilentlyContinue
        if ($git) {
            Write-ColorOutput "Git安装成功！" "SUCCESS"
            return $true
        } else {
            Write-ColorOutput "Git安装失败，请手动安装：https://git-scm.com/download/win" "ERROR"
            return $false
        }
    } catch {
        Write-ColorOutput "Git安装失败: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

# 克隆或更新项目
function Get-Project {
    param([string]$InstallPath)
    
    if (Test-Path $InstallPath) {
        Write-ColorOutput "项目目录已存在，正在更新..." "INFO"
        
        Push-Location $InstallPath
        try {
            git pull origin master
            Write-ColorOutput "项目更新成功！" "SUCCESS"
        } catch {
            Write-ColorOutput "项目更新失败: $($_.Exception.Message)" "ERROR"
            Write-ColorOutput "将使用现有版本继续..." "WARNING"
        }
        Pop-Location
    } else {
        Write-ColorOutput "正在克隆项目..." "INFO"
        
        try {
            git clone https://github.com/vpn3288/multi-browser-antidetect.git $InstallPath
            Write-ColorOutput "项目克隆成功！" "SUCCESS"
        } catch {
            Write-ColorOutput "项目克隆失败: $($_.Exception.Message)" "ERROR"
            return $false
        }
    }
    
    return $true
}

# 主函数
function Main {
    Write-ColorOutput "Multi-Browser Anti-Detect - 一键安装" "HEADER"
    
    # 检查管理员权限
    if (-not (Test-Administrator)) {
        Write-ColorOutput "请以管理员身份运行此脚本！" "ERROR"
        Write-ColorOutput "右键点击PowerShell → 以管理员身份运行" "INFO"
        Read-Host "按Enter键退出"
        exit 1
    }
    
    # 安装路径
    $installPath = "C:\multi-browser-antidetect"
    
    # 检查并安装Git
    if (-not (Install-GitIfNeeded)) {
        Write-ColorOutput "无法继续安装，请先安装Git" "ERROR"
        Read-Host "按Enter键退出"
        exit 1
    }
    
    # 克隆或更新项目
    if (-not (Get-Project -InstallPath $installPath)) {
        Write-ColorOutput "无法获取项目文件" "ERROR"
        Read-Host "按Enter键退出"
        exit 1
    }
    
    # 运行优化脚本
    Write-ColorOutput "准备运行优化脚本..." "INFO"
    
    $optimizeScript = Join-Path $installPath "scripts\deployment\OPTIMIZE_ALL_v13.7.ps1"
    
    if (-not (Test-Path $optimizeScript)) {
        Write-ColorOutput "优化脚本不存在: $optimizeScript" "ERROR"
        Read-Host "按Enter键退出"
        exit 1
    }
    
    Write-ColorOutput "启动优化脚本..." "SUCCESS"
    Write-ColorOutput "提示：输入 A 优化全部浏览器，或输入编号优化指定浏览器" "INFO"
    
    # 传递启动器参数
    if ($SkipLaunchers) {
        & $optimizeScript -SkipLaunchers
    } else {
        & $optimizeScript
    }
    
    Write-ColorOutput "安装完成！" "HEADER"
    Write-ColorOutput "启动器位置：桌面或 $installPath\scripts\launch\" "INFO"
    Write-ColorOutput "使用启动器启动浏览器，不要使用原快捷方式！" "WARNING"
}

# 运行主函数
Main
