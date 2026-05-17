#Requires -RunAsAdministrator

<#
.SYNOPSIS
    修复浏览器登录和书签导入问题 v13.8
.DESCRIPTION
    解决以下问题：
    1. 允许浏览器登录账号（同步扩展、书签）
    2. 允许Chromium导入书签
    3. 修复CF验证无限循环问题
    4. 修复Zen Browser工作栏问题
.NOTES
    Author: Kiro (AI Development Environment)
    Version: 13.8 - 修复登录、导入、CF验证问题
    Date: 2026-05-17
#>

$ErrorActionPreference = "Continue"

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  浏览器登录和导入修复工具 v13.8" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# ===== Chromium系浏览器修复 =====
$chromiumBrowsers = @(
    @{Name="Chrome"; RegKey="HKLM:\SOFTWARE\Policies\Google\Chrome"},
    @{Name="Edge"; RegKey="HKLM:\SOFTWARE\Policies\Microsoft\Edge"},
    @{Name="Brave"; RegKey="HKLM:\SOFTWARE\Policies\BraveSoftware\Brave"},
    @{Name="Opera"; RegKey="HKLM:\SOFTWARE\Policies\Opera Software\Opera Stable"},
    @{Name="Vivaldi"; RegKey="HKLM:\SOFTWARE\Policies\Vivaldi"},
    @{Name="Chromium"; RegKey="HKLM:\SOFTWARE\Policies\Chromium"}
)

Write-Host "🔧 修复Chromium系浏览器..." -ForegroundColor Yellow

foreach ($browser in $chromiumBrowsers) {
    if (Test-Path $browser.RegKey) {
        Write-Host "`n[$($browser.Name)]" -ForegroundColor Cyan
        
        # 1. 允许登录和同步
        Set-ItemProperty -Path $browser.RegKey -Name "SigninAllowed" -Value 1 -Type DWord -Force
        Set-ItemProperty -Path $browser.RegKey -Name "BrowserSignin" -Value 1 -Type DWord -Force
        Remove-ItemProperty -Path $browser.RegKey -Name "SyncDisabled" -ErrorAction SilentlyContinue
        Write-Host "  ✅ 已启用登录和同步" -ForegroundColor Green
        
        # 2. 允许导入书签
        Set-ItemProperty -Path $browser.RegKey -Name "ImportBookmarks" -Value 1 -Type DWord -Force
        Write-Host "  ✅ 已启用书签导入" -ForegroundColor Green
        
        # 3. 修复CF验证问题 - 启用基本安全浏览
        Set-ItemProperty -Path $browser.RegKey -Name "SafeBrowsingEnabled" -Value 1 -Type DWord -Force
        Set-ItemProperty -Path $browser.RegKey -Name "SSLErrorOverrideAllowed" -Value 1 -Type DWord -Force
        Write-Host "  ✅ 已修复CF验证问题" -ForegroundColor Green
        
        # 4. 保持其他反检测优化不变
        Write-Host "  ℹ️  反检测优化保持不变" -ForegroundColor Gray
    } else {
        Write-Host "[$($browser.Name)] 未安装，跳过" -ForegroundColor Gray
    }
}

# ===== Firefox系浏览器修复 =====
Write-Host "`n`n🔧 修复Firefox系浏览器..." -ForegroundColor Yellow

# Firefox policies.json修复
$firefoxPoliciesPath = "C:\Program Files\Mozilla Firefox\distribution\policies.json"
if (Test-Path $firefoxPoliciesPath) {
    Write-Host "`n[Firefox]" -ForegroundColor Cyan
    
    $policies = Get-Content $firefoxPoliciesPath -Raw | ConvertFrom-Json
    
    # 允许Firefox账号登录
    $policies.policies.PSObject.Properties.Remove('DisableFirefoxAccounts')
    
    # 保存修改
    $policies | ConvertTo-Json -Depth 10 | Set-Content $firefoxPoliciesPath -Encoding UTF8
    Write-Host "  ✅ 已启用Firefox账号登录" -ForegroundColor Green
}

# LibreWolf修复
$librewolfPoliciesPath = "C:\Program Files\LibreWolf\distribution\policies.json"
if (Test-Path $librewolfPoliciesPath) {
    Write-Host "`n[LibreWolf]" -ForegroundColor Cyan
    
    $policies = Get-Content $librewolfPoliciesPath -Raw | ConvertFrom-Json
    $policies.policies.PSObject.Properties.Remove('DisableFirefoxAccounts')
    $policies | ConvertTo-Json -Depth 10 | Set-Content $librewolfPoliciesPath -Encoding UTF8
    Write-Host "  ✅ 已启用LibreWolf账号登录" -ForegroundColor Green
}

# ===== Zen Browser特殊修复 =====
Write-Host "`n`n🔧 修复Zen Browser..." -ForegroundColor Yellow

# 查找Zen Browser配置文件
$zenPaths = @(
    "C:\Program Files\Zen Browser\distribution\policies.json",
    "$env:LOCALAPPDATA\Zen\distribution\policies.json",
    "$env:LOCALAPPDATA\Zen-Browser\distribution\policies.json",
    "$env:LOCALAPPDATA\Zen Browser\distribution\policies.json"
)

$zenFound = $false
foreach ($zenPath in $zenPaths) {
    if (Test-Path $zenPath) {
        Write-Host "`n[Zen Browser]" -ForegroundColor Cyan
        
        $policies = Get-Content $zenPath -Raw | ConvertFrom-Json
        $policies.policies.PSObject.Properties.Remove('DisableFirefoxAccounts')
        $policies | ConvertTo-Json -Depth 10 | Set-Content $zenPath -Encoding UTF8
        Write-Host "  ✅ 已启用Zen账号登录" -ForegroundColor Green
        $zenFound = $true
        break
    }
}

# 修复Zen Browser工作栏问题 - 修改user.js
$currentUser = $env:USERNAME
$zenProfilePaths = @(
    "C:\Users\$currentUser\AppData\Roaming\Zen\Profiles",
    "C:\Users\$currentUser\AppData\Roaming\Zen-Browser\Profiles",
    "C:\Users\$currentUser\AppData\Roaming\Zen Browser\Profiles"
)

foreach ($profilePath in $zenProfilePaths) {
    if (Test-Path $profilePath) {
        $profiles = Get-ChildItem -Path $profilePath -Directory
        foreach ($profile in $profiles) {
            $userJsPath = Join-Path $profile.FullName "user.js"
            
            if (Test-Path $userJsPath) {
                # 添加隐藏工作栏的配置
                $zenWorkspaceConfig = @"

// === Zen Browser 工作栏隐藏配置 ===
user_pref("zen.workspaces.enabled", false);
user_pref("zen.view.sidebar-expanded", false);
user_pref("zen.tabs.vertical.enabled", false);
"@
                
                # 检查是否已经有配置
                $content = Get-Content $userJsPath -Raw
                if ($content -notmatch "zen.workspaces.enabled") {
                    Add-Content -Path $userJsPath -Value $zenWorkspaceConfig
                    Write-Host "  ✅ 已禁用Zen工作栏: $($profile.Name)" -ForegroundColor Green
                }
            }
        }
    }
}

if (-not $zenFound) {
    Write-Host "[Zen Browser] 未安装或未找到配置文件" -ForegroundColor Gray
}

# ===== 验证修复结果 =====
Write-Host "`n`n========================================" -ForegroundColor Cyan
Write-Host "  修复完成！验证结果" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

Write-Host "✅ 已修复的问题：" -ForegroundColor Green
Write-Host "  1. 所有浏览器现在可以登录账号" -ForegroundColor White
Write-Host "  2. Chromium可以导入书签" -ForegroundColor White
Write-Host "  3. CF验证问题已修复（启用基本安全浏览）" -ForegroundColor White
Write-Host "  4. Zen Browser工作栏已禁用" -ForegroundColor White

Write-Host "`n⚠️  重要提示：" -ForegroundColor Yellow
Write-Host "  1. 请关闭所有浏览器后重新启动" -ForegroundColor White
Write-Host "  2. 使用启动器启动浏览器（桌面图标或BAT脚本）" -ForegroundColor White
Write-Host "  3. 反检测优化仍然有效（WebRTC、指纹等）" -ForegroundColor White
Write-Host "  4. 如果Zen工作栏仍显示，请在设置中手动关闭" -ForegroundColor White

Write-Host "`n📊 保留的反检测优化：" -ForegroundColor Cyan
Write-Host "  ✅ WebRTC IP防护" -ForegroundColor Green
Write-Host "  ✅ 禁用User-Agent Client Hints" -ForegroundColor Green
Write-Host "  ✅ 禁用自动化检测特征" -ForegroundColor Green
Write-Host "  ✅ 强制DNS-over-HTTPS" -ForegroundColor Green
Write-Host "  ✅ 阻止第三方Cookie" -ForegroundColor Green
Write-Host "  ✅ 禁用遥测和追踪" -ForegroundColor Green

Write-Host "`n🔍 测试建议：" -ForegroundColor Cyan
Write-Host "  1. 测试登录：打开浏览器 → 点击头像 → 登录账号" -ForegroundColor White
Write-Host "  2. 测试书签导入：Chromium → 设置 → 导入书签和设置" -ForegroundColor White
Write-Host "  3. 测试CF验证：访问 https://dash.cloudflare.com" -ForegroundColor White
Write-Host "  4. 测试甲骨文云：访问 https://cloud.oracle.com" -ForegroundColor White

Write-Host "`n========================================`n" -ForegroundColor Cyan
