#Requires -RunAsAdministrator

<#
.SYNOPSIS
    实用版浏览器反检测优化 v14.0
.DESCRIPTION
    砍掉影响使用的过度优化，保留真正有用的反检测功能
    - ✅ 允许登录账号（同步扩展、书签）
    - ✅ 允许导入书签
    - ✅ 启用基本安全功能（SafeBrowsing）
    - ✅ 保留核心反检测（WebRTC、指纹、自动化特征）
    - ❌ 删除影响使用的限制
.NOTES
    Author: Kiro (AI Development Environment)
    Version: 14.0 - 实用优先，体验优先
    Date: 2026-05-17
#>

$ErrorActionPreference = "Continue"
$ProgressPreference = "SilentlyContinue"

# ===== 配置区域 =====
$languageConfig = @{
    "Chrome" = "zh-CN"
    "Edge" = "zh-CN"
    "Brave" = "zh-CN"
    "Opera" = "zh-CN"
    "Vivaldi" = "zh-CN"
    "Chromium" = "zh-CN"
    "Firefox" = "zh-CN"
    "LibreWolf" = "zh-CN"
    "Zen Browser" = "zh-CN"
}

# User-Agent 配置（差异化）
$userAgentConfig = @{
    "Chrome" = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36"
    "Edge" = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36 Edg/125.0.0.0"
    "Brave" = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36"
    "Opera" = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36 OPR/110.0.0.0"
    "Vivaldi" = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36 Vivaldi/6.7.3329.35"
    "Chromium" = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0.0.0 Safari/537.36"
}

# ===== 日志系统 =====
$logFile = "$PSScriptRoot\optimization_log_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"

function Write-Log {
    param(
        [string]$Message,
        [string]$Level = "INFO"
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"
    
    switch ($Level) {
        "SUCCESS" { Write-Host $logMessage -ForegroundColor Green }
        "ERROR"   { Write-Host $logMessage -ForegroundColor Red }
        "WARNING" { Write-Host $logMessage -ForegroundColor Yellow }
        "HEADER"  { Write-Host "`n$logMessage" -ForegroundColor Cyan }
        default   { Write-Host $logMessage -ForegroundColor White }
    }
    
    Add-Content -Path $logFile -Value $logMessage -ErrorAction SilentlyContinue
}

# ===== 浏览器配置 =====
$currentUser = $env:USERNAME
$userLocalAppData = "C:\Users\$currentUser\AppData\Local"

$browsers = @{
    "Chrome" = @{
        Name = "Google Chrome"
        Paths = @(
            "C:\Program Files\Google\Chrome\Application\chrome.exe",
            "C:\Program Files (x86)\Google\Chrome\Application\chrome.exe"
        )
        RegKey = "HKLM:\SOFTWARE\Policies\Google\Chrome"
        UserDataPath = "$userLocalAppData\Google\Chrome\User Data"
        Type = "Chromium"
    }
    "Edge" = @{
        Name = "Microsoft Edge"
        Paths = @(
            "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe",
            "C:\Program Files\Microsoft\Edge\Application\msedge.exe"
        )
        RegKey = "HKLM:\SOFTWARE\Policies\Microsoft\Edge"
        UserDataPath = "$userLocalAppData\Microsoft\Edge\User Data"
        Type = "Chromium"
    }
    "Brave" = @{
        Name = "Brave Browser"
        Paths = @(
            "$userLocalAppData\BraveSoftware\Brave-Browser\Application\brave.exe"
        )
        RegKey = "HKLM:\SOFTWARE\Policies\BraveSoftware\Brave"
        UserDataPath = "$userLocalAppData\BraveSoftware\Brave-Browser\User Data"
        Type = "Chromium"
    }
    "Opera" = @{
        Name = "Opera"
        Paths = @(
            "$userLocalAppData\Programs\Opera\opera.exe"
        )
        RegKey = "HKLM:\SOFTWARE\Policies\Opera Software\Opera Stable"
        UserDataPath = "$env:APPDATA\Opera Software\Opera Stable"
        Type = "Chromium"
    }
    "Vivaldi" = @{
        Name = "Vivaldi"
        Paths = @(
            "$userLocalAppData\Vivaldi\Application\vivaldi.exe"
        )
        RegKey = "HKLM:\SOFTWARE\Policies\Vivaldi"
        UserDataPath = "$userLocalAppData\Vivaldi\User Data"
        Type = "Chromium"
    }
    "Chromium" = @{
        Name = "Chromium"
        Paths = @(
            "$userLocalAppData\Chromium\Application\chrome.exe"
        )
        RegKey = "HKLM:\SOFTWARE\Policies\Chromium"
        UserDataPath = "$userLocalAppData\Chromium\User Data"
        Type = "Chromium"
    }
    "Firefox" = @{
        Name = "Mozilla Firefox"
        Paths = @(
            "C:\Program Files\Mozilla Firefox\firefox.exe",
            "C:\Program Files (x86)\Mozilla Firefox\firefox.exe"
        )
        Type = "Firefox"
    }
    "LibreWolf" = @{
        Name = "LibreWolf"
        Paths = @(
            "C:\Program Files\LibreWolf\librewolf.exe"
        )
        Type = "Firefox"
    }
    "Zen Browser" = @{
        Name = "Zen Browser"
        Paths = @(
            "C:\Program Files\Zen Browser\zen.exe",
            "$userLocalAppData\Zen\zen.exe",
            "$userLocalAppData\Zen-Browser\zen.exe"
        )
        Type = "Firefox"
    }
}

# ===== 核心反检测策略（实用版）=====
function Set-ChromiumPolicies {
    param(
        [string]$RegKey,
        [string]$BrowserName,
        [string]$Language,
        [string]$UserAgent
    )
    
    Write-Log "正在优化 $BrowserName..." "HEADER"
    
    if (-not (Test-Path $RegKey)) {
        New-Item -Path $RegKey -Force | Out-Null
    }
    
    # ===== 核心反检测（保留）=====
    
    # 1. 禁用自动化检测特征
    Set-ItemProperty -Path $RegKey -Name "UserAgentClientHintsEnabled" -Value 0 -Type DWord -Force
    Set-ItemProperty -Path $RegKey -Name "UserAgentClientHintsGREASEUpdateEnabled" -Value 0 -Type DWord -Force
    Write-Log "✅ 禁用User-Agent Client Hints" "SUCCESS"
    
    # 2. WebRTC IP防护
    Set-ItemProperty -Path $RegKey -Name "WebRtcIPHandlingPolicy" -Value "disable_non_proxied_udp" -Type String -Force
    Set-ItemProperty -Path $RegKey -Name "WebRtcEventLogCollectionAllowed" -Value 0 -Type DWord -Force
    Write-Log "✅ WebRTC IP防护" "SUCCESS"
    
    # 3. DNS-over-HTTPS
    Set-ItemProperty -Path $RegKey -Name "DnsOverHttpsMode" -Value "secure" -Type String -Force
    Set-ItemProperty -Path $RegKey -Name "DnsOverHttpsTemplates" -Value "https://cloudflare-dns.com/dns-query" -Type String -Force
    Set-ItemProperty -Path $RegKey -Name "BuiltInDnsClientEnabled" -Value 0 -Type DWord -Force
    Write-Log "✅ 强制DNS-over-HTTPS" "SUCCESS"
    
    # 4. 隐私保护
    Set-ItemProperty -Path $RegKey -Name "BlockThirdPartyCookies" -Value 1 -Type DWord -Force
    Set-ItemProperty -Path $RegKey -Name "ThirdPartyBlockingEnabled" -Value 1 -Type DWord -Force
    Set-ItemProperty -Path $RegKey -Name "DefaultGeolocationSetting" -Value 2 -Type DWord -Force
    Set-ItemProperty -Path $RegKey -Name "DefaultNotificationsSetting" -Value 2 -Type DWord -Force
    Write-Log "✅ 隐私保护（Cookie、地理位置）" "SUCCESS"
    
    # 5. 禁用遥测
    Set-ItemProperty -Path $RegKey -Name "MetricsReportingEnabled" -Value 0 -Type DWord -Force
    Set-ItemProperty -Path $RegKey -Name "ChromeCleanupEnabled" -Value 0 -Type DWord -Force
    Set-ItemProperty -Path $RegKey -Name "ChromeCleanupReportingEnabled" -Value 0 -Type DWord -Force
    Set-ItemProperty -Path $RegKey -Name "UserFeedbackAllowed" -Value 0 -Type DWord -Force
    Set-ItemProperty -Path $RegKey -Name "UrlKeyedAnonymizedDataCollectionEnabled" -Value 0 -Type DWord -Force
    Write-Log "✅ 禁用遥测和数据收集" "SUCCESS"
    
    # 6. 语言设置
    Set-ItemProperty -Path $RegKey -Name "ApplicationLocaleValue" -Value $Language -Type String -Force
    Set-ItemProperty -Path $RegKey -Name "SpellcheckLanguage" -Value $Language -Type String -Force
    Write-Log "✅ 语言设置: $Language" "SUCCESS"
    
    # ===== 实用功能（启用）=====
    
    # 1. 允许登录和同步
    Set-ItemProperty -Path $RegKey -Name "SigninAllowed" -Value 1 -Type DWord -Force
    Set-ItemProperty -Path $RegKey -Name "BrowserSignin" -Value 1 -Type DWord -Force
    Remove-ItemProperty -Path $RegKey -Name "SyncDisabled" -ErrorAction SilentlyContinue
    Write-Log "✅ 允许登录和同步" "SUCCESS"
    
    # 2. 允许导入
    Set-ItemProperty -Path $RegKey -Name "ImportBookmarks" -Value 1 -Type DWord -Force
    Set-ItemProperty -Path $RegKey -Name "ImportHistory" -Value 1 -Type DWord -Force
    Set-ItemProperty -Path $RegKey -Name "ImportSavedPasswords" -Value 1 -Type DWord -Force
    Set-ItemProperty -Path $RegKey -Name "ImportAutofillFormData" -Value 1 -Type DWord -Force
    Write-Log "✅ 允许导入书签、历史、密码" "SUCCESS"
    
    # 3. 启用安全功能
    Set-ItemProperty -Path $RegKey -Name "SafeBrowsingEnabled" -Value 1 -Type DWord -Force
    Set-ItemProperty -Path $RegKey -Name "SSLErrorOverrideAllowed" -Value 1 -Type DWord -Force
    Write-Log "✅ 启用安全浏览（修复CF验证）" "SUCCESS"
    
    # 4. 密码管理器
    Set-ItemProperty -Path $RegKey -Name "PasswordManagerEnabled" -Value 1 -Type DWord -Force
    Write-Log "✅ 启用密码管理器" "SUCCESS"
    
    # 5. 自动填充
    Set-ItemProperty -Path $RegKey -Name "AutofillAddressEnabled" -Value 1 -Type DWord -Force
    Set-ItemProperty -Path $RegKey -Name "AutofillCreditCardEnabled" -Value 1 -Type DWord -Force
    Write-Log "✅ 启用自动填充" "SUCCESS"
    
    # 6. 搜索建议（可选，提升体验）
    Set-ItemProperty -Path $RegKey -Name "SearchSuggestEnabled" -Value 1 -Type DWord -Force
    Write-Log "✅ 启用搜索建议" "SUCCESS"
    
    # 7. 翻译功能
    Set-ItemProperty -Path $RegKey -Name "TranslateEnabled" -Value 1 -Type DWord -Force
    Write-Log "✅ 启用翻译功能" "SUCCESS"
    
    # ===== 删除过度限制 =====
    
    # 删除网络预测限制
    Remove-ItemProperty -Path $RegKey -Name "NetworkPredictionOptions" -ErrorAction SilentlyContinue
    
    # 删除后台模式限制
    Remove-ItemProperty -Path $RegKey -Name "BackgroundModeEnabled" -ErrorAction SilentlyContinue
    
    # 删除默认浏览器检查限制
    Remove-ItemProperty -Path $RegKey -Name "DefaultBrowserSettingEnabled" -ErrorAction SilentlyContinue
    
    Write-Log "✅ 删除过度限制" "SUCCESS"
    
    # ===== UI设置 =====
    Set-ItemProperty -Path $RegKey -Name "BookmarkBarEnabled" -Value 1 -Type DWord -Force
    Set-ItemProperty -Path $RegKey -Name "ShowHomeButton" -Value 1 -Type DWord -Force
    Set-ItemProperty -Path $RegKey -Name "HomepageLocation" -Value "about:blank" -Type String -Force
    Set-ItemProperty -Path $RegKey -Name "RestoreOnStartup" -Value 1 -Type DWord -Force
    Set-ItemProperty -Path $RegKey -Name "HomepageIsNewTabPage" -Value 1 -Type DWord -Force
    Write-Log "✅ UI设置完成" "SUCCESS"
    
    # ===== 硬件加速 =====
    Set-ItemProperty -Path $RegKey -Name "HardwareAccelerationModeEnabled" -Value 1 -Type DWord -Force
    Write-Log "✅ 启用硬件加速" "SUCCESS"
    
    Write-Log "$BrowserName 优化完成！" "SUCCESS"
}

# ===== Firefox系优化（实用版）=====
function Set-FirefoxPolicies {
    param(
        [string]$BrowserName,
        [string]$PoliciesPath
    )
    
    Write-Log "正在优化 $BrowserName..." "HEADER"
    
    $distributionDir = Split-Path $PoliciesPath -Parent
    if (-not (Test-Path $distributionDir)) {
        New-Item -Path $distributionDir -ItemType Directory -Force | Out-Null
    }
    
    $policies = @{
        policies = @{
            # DNS-over-HTTPS
            DNSOverHTTPS = @{
                ProviderURL = "https://cloudflare-dns.com/dns-query"
                Enabled = $true
            }
            
            # 追踪保护
            EnableTrackingProtection = @{
                Locked = $true
                Value = $true
                Fingerprinting = $true
                Cryptomining = $true
            }
            
            # Cookie设置
            Cookies = @{
                Behavior = "reject-tracker-and-partition-foreign"
                BehaviorPrivateBrowsing = "reject-tracker-and-partition-foreign"
            }
            
            # 禁用遥测
            DisableTelemetry = $true
            DisableFirefoxStudies = $true
            DisablePocket = $true
            
            # 用户消息
            UserMessaging = @{
                FeatureRecommendations = $false
                WhatsNew = $false
                UrlbarInterventions = $false
                ExtensionRecommendations = $false
                SkipOnboarding = $true
            }
            
            # 主页设置
            Homepage = @{
                Locked = $false
                StartPage = "none"
                URL = "about:blank"
            }
            
            # UI设置
            DisplayBookmarksToolbar = "always"
            NewTabPage = $false
            
            # ===== 实用功能（启用）=====
            
            # 允许Firefox账号登录
            # DisableFirefoxAccounts = $false  # 不设置此项即为允许
            
            # 密码管理器
            PasswordManagerEnabled = $true
            OfferToSaveLogins = $true
            
            # 表单历史
            DisableFormHistory = $false
            
            # 硬件加速
            HardwareAcceleration = $true
        }
    }
    
    $policies | ConvertTo-Json -Depth 10 | Set-Content $PoliciesPath -Encoding UTF8
    Write-Log "✅ $BrowserName policies.json 已创建" "SUCCESS"
}

function Set-FirefoxUserJS {
    param(
        [string]$ProfilePath,
        [string]$BrowserName
    )
    
    $userJsContent = @"
// ===== $BrowserName 实用版反检测配置 v14.0 =====
// 核心反检测 + 实用功能

// === 核心反检测（保留）===
user_pref("privacy.resistFingerprinting", true);
user_pref("privacy.resistFingerprinting.letterboxing", true);
user_pref("webgl.disabled", false);  // 不禁用WebGL，避免影响网站功能
user_pref("privacy.trackingprotection.enabled", true);
user_pref("privacy.trackingprotection.fingerprinting.enabled", true);
user_pref("privacy.trackingprotection.cryptomining.enabled", true);

// === WebRTC防护 ===
user_pref("media.peerconnection.enabled", true);  // 启用WebRTC（某些网站需要）
user_pref("media.peerconnection.ice.default_address_only", true);  // 但防止IP泄露
user_pref("media.peerconnection.ice.no_host", true);
user_pref("media.peerconnection.ice.proxy_only_if_behind_proxy", true);

// === 语言设置 ===
user_pref("intl.accept_languages", "zh-CN, en-US, en");
user_pref("javascript.use_us_english_locale", false);

// === DNS-over-HTTPS ===
user_pref("network.trr.mode", 2);
user_pref("network.trr.uri", "https://cloudflare-dns.com/dns-query");

// === 禁用遥测 ===
user_pref("datareporting.healthreport.uploadEnabled", false);
user_pref("datareporting.policy.dataSubmissionEnabled", false);
user_pref("toolkit.telemetry.enabled", false);
user_pref("toolkit.telemetry.unified", false);
user_pref("toolkit.telemetry.archive.enabled", false);

// === 实用功能（启用）===
user_pref("browser.search.suggest.enabled", true);  // 搜索建议
user_pref("browser.urlbar.suggest.searches", true);
user_pref("browser.formfill.enable", true);  // 表单自动填充
user_pref("signon.rememberSignons", true);  // 记住密码
user_pref("signon.autofillForms", true);  // 自动填充密码

// === 删除过度限制 ===
// 不禁用地理位置API（网站可能需要）
// 不禁用传感器API
// 不禁用通知API

// === UI优化 ===
user_pref("browser.toolbars.bookmarks.visibility", "always");
user_pref("browser.startup.page", 1);  // 启动时恢复上次会话
"@
    
    $userJsPath = Join-Path $ProfilePath "user.js"
    $userJsContent | Set-Content $userJsPath -Encoding UTF8
    Write-Log "✅ user.js 已创建: $ProfilePath" "SUCCESS"
}

# ===== 主程序 =====
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  实用版浏览器反检测优化 v14.0" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

Write-Host "📋 优化策略：" -ForegroundColor Yellow
Write-Host "  ✅ 保留：WebRTC防护、指纹保护、禁用遥测" -ForegroundColor Green
Write-Host "  ✅ 启用：登录、同步、导入、安全浏览" -ForegroundColor Green
Write-Host "  ✅ 启用：密码管理、自动填充、搜索建议" -ForegroundColor Green
Write-Host "  ❌ 删除：过度限制、影响使用的优化`n" -ForegroundColor Red

# 检测已安装的浏览器
$installedBrowsers = @()
foreach ($key in $browsers.Keys) {
    $browser = $browsers[$key]
    foreach ($path in $browser.Paths) {
        if (Test-Path $path) {
            $installedBrowsers += $key
            break
        }
    }
}

if ($installedBrowsers.Count -eq 0) {
    Write-Log "未检测到任何浏览器！" "ERROR"
    exit 1
}

Write-Host "检测到 $($installedBrowsers.Count) 个浏览器：" -ForegroundColor Cyan
$installedBrowsers | ForEach-Object { Write-Host "  - $($browsers[$_].Name)" -ForegroundColor White }

Write-Host "`n是否优化所有浏览器？(Y/N): " -ForegroundColor Yellow -NoNewline
$choice = Read-Host

if ($choice -ne "Y" -and $choice -ne "y") {
    Write-Host "已取消优化" -ForegroundColor Yellow
    exit 0
}

# 优化Chromium系浏览器
foreach ($browserKey in $installedBrowsers) {
    $browser = $browsers[$browserKey]
    
    if ($browser.Type -eq "Chromium") {
        $lang = $languageConfig[$browserKey]
        $ua = $userAgentConfig[$browserKey]
        Set-ChromiumPolicies -RegKey $browser.RegKey -BrowserName $browser.Name -Language $lang -UserAgent $ua
    }
}

# 优化Firefox系浏览器
foreach ($browserKey in $installedBrowsers) {
    $browser = $browsers[$browserKey]
    
    if ($browser.Type -eq "Firefox") {
        # 创建policies.json
        $policiesPath = ""
        if ($browserKey -eq "Firefox") {
            $policiesPath = "C:\Program Files\Mozilla Firefox\distribution\policies.json"
        } elseif ($browserKey -eq "LibreWolf") {
            $policiesPath = "C:\Program Files\LibreWolf\distribution\policies.json"
        } elseif ($browserKey -eq "Zen Browser") {
            $policiesPath = "C:\Program Files\Zen Browser\distribution\policies.json"
        }
        
        if ($policiesPath) {
            Set-FirefoxPolicies -BrowserName $browser.Name -PoliciesPath $policiesPath
        }
        
        # 创建user.js（查找所有配置文件）
        $profileBasePaths = @()
        if ($browserKey -eq "Firefox") {
            $profileBasePaths += "$env:APPDATA\Mozilla\Firefox\Profiles"
        } elseif ($browserKey -eq "LibreWolf") {
            $profileBasePaths += "$env:APPDATA\LibreWolf\Profiles"
        } elseif ($browserKey -eq "Zen Browser") {
            $profileBasePaths += "$env:APPDATA\Zen\Profiles"
            $profileBasePaths += "$env:APPDATA\Zen-Browser\Profiles"
        }
        
        foreach ($basePath in $profileBasePaths) {
            if (Test-Path $basePath) {
                $profiles = Get-ChildItem -Path $basePath -Directory
                foreach ($profile in $profiles) {
                    Set-FirefoxUserJS -ProfilePath $profile.FullName -BrowserName $browser.Name
                }
            }
        }
    }
}

# ===== 完成 =====
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  优化完成！" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

Write-Host "✅ 已完成的优化：" -ForegroundColor Green
Write-Host "  1. 核心反检测：WebRTC防护、指纹保护" -ForegroundColor White
Write-Host "  2. 隐私保护：禁用遥测、阻止追踪" -ForegroundColor White
Write-Host "  3. 实用功能：登录、同步、导入、安全浏览" -ForegroundColor White
Write-Host "  4. 便利功能：密码管理、自动填充、搜索建议" -ForegroundColor White

Write-Host "`n⚠️  重要提示：" -ForegroundColor Yellow
Write-Host "  1. 请关闭所有浏览器后重新启动" -ForegroundColor White
Write-Host "  2. 现在可以正常登录账号、导入书签" -ForegroundColor White
Write-Host "  3. CF验证和甲骨文云应该可以正常访问" -ForegroundColor White
Write-Host "  4. Zen Browser工作栏需要手动关闭（设置中）" -ForegroundColor White

Write-Host "`n📝 日志文件：$logFile`n" -ForegroundColor Cyan
