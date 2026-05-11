#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Multi-Browser Anti-Detect Optimization Tool v13.3
.DESCRIPTION
    Automatically detect and optimize 9 browsers with advanced anti-detection configurations.
    Supports: Chrome, Edge, Brave, Opera, Vivaldi, Chromium, Firefox, LibreWolf, Zen Browser
.NOTES
    Author: Kiro (AI Development Environment)
    Version: 13.7 - 修复Opera无效参数、删除Firefox字体配置、增强WebRTC防护、优化Zen语言格式
    Date: 2026-05-08 (Updated)
#>

$ErrorActionPreference = "Continue"
$ProgressPreference = "SilentlyContinue"

# ===== 配置区域 =====
$languageConfig = @{
    "Chrome" = "zh-CN"
    "Edge" = "zh-CN"
    "Brave" = "zh-TW"
    "Opera" = "zh-TW"
    "Vivaldi" = "zh-CN"
    "Chromium" = "zh-TW"
    "Firefox" = "zh-CN"
    "LibreWolf" = "zh-TW"
    "Zen Browser" = "zh-CN"  # 默认使用简体中文
}

# User-Agent 配置（差异化 - 2026年5月版本）
$userAgentConfig = @{
    "Chrome" = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36"
    "Edge" = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36 Edg/125.0.0.0"
    "Brave" = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36"
    "Opera" = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36 OPR/110.0.0.0"
    "Vivaldi" = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36 Vivaldi/6.7.3329.35"
    "Chromium" = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0.0.0 Safari/537.36"
}

# 任务专用浏览器（最大化反检测，牺牲部分功能）
$taskBrowsers = @("Opera")

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
            "$userLocalAppData\Zen-Browser\zen.exe",
            "$userLocalAppData\Zen Browser\zen.exe",
            "C:\Program Files\Zen\zen.exe",
            "C:\Program Files\Zen-Browser\zen.exe"
        )
        Type = "Firefox"
    }
}

# ===== 增强浏览器检测 =====
function Get-InstalledBrowsers {
    Write-Log "开始检测已安装的浏览器..." "HEADER"
    $detected = @{}
    
    foreach ($key in $browsers.Keys) {
        $browser = $browsers[$key]
        $foundPath = $null
        
        # 方法1: 检测预定义路径
        foreach ($path in $browser.Paths) {
            if (Test-Path $path) {
                $foundPath = $path
                Write-Log "$($browser.Name) - 路径检测成功: $path" "SUCCESS"
                break
            }
        }
        
        # 方法2: 注册表 App Paths 检测
        if (-not $foundPath) {
            $exeName = switch ($key) {
                "Chrome" { "chrome.exe" }
                "Edge" { "msedge.exe" }
                "Firefox" { "firefox.exe" }
                "Brave" { "brave.exe" }
                "Opera" { "opera.exe" }
                "Vivaldi" { "vivaldi.exe" }
                "Chromium" { "chrome.exe" }
                "LibreWolf" { "librewolf.exe" }
                "Zen Browser" { "zen.exe" }
            }
            
            $regPaths = @(
                "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\$exeName",
                "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\$exeName"
            )
            
            foreach ($regPath in $regPaths) {
                if (Test-Path $regPath) {
                    $regValue = (Get-ItemProperty -Path $regPath -Name "(Default)" -ErrorAction SilentlyContinue).'(Default)'
                    if ($regValue -and (Test-Path $regValue)) {
                        $foundPath = $regValue
                        Write-Log "$($browser.Name) - 注册表检测成功: $foundPath" "SUCCESS"
                        break
                    }
                }
            }
        }
        
        # 方法3: 通过 Get-Command 检测 PATH 环境变量
        if (-not $foundPath) {
            $exeName = switch ($key) {
                "Chrome" { "chrome" }
                "Edge" { "msedge" }
                "Firefox" { "firefox" }
                "Brave" { "brave" }
                "Opera" { "opera" }
                "Vivaldi" { "vivaldi" }
                "Chromium" { "chrome" }
                "LibreWolf" { "librewolf" }
                "Zen Browser" { "zen" }
            }
            
            $cmd = Get-Command $exeName -ErrorAction SilentlyContinue
            if ($cmd -and $cmd.Source) {
                $foundPath = $cmd.Source
                Write-Log "$($browser.Name) - PATH检测成功: $foundPath" "SUCCESS"
            }
        }
        
        # 方法4: 扫描常见安装目录
        if (-not $foundPath) {
            $searchDirs = @(
                "C:\Program Files",
                "C:\Program Files (x86)",
                "$env:LOCALAPPDATA",
                "$env:APPDATA"
            )
            
            $exeName = switch ($key) {
                "Chrome" { "chrome.exe" }
                "Edge" { "msedge.exe" }
                "Firefox" { "firefox.exe" }
                "Brave" { "brave.exe" }
                "Opera" { "opera.exe" }
                "Vivaldi" { "vivaldi.exe" }
                "Chromium" { "chrome.exe" }
                "LibreWolf" { "librewolf.exe" }
                "Zen Browser" { "zen.exe" }
            }
            
            foreach ($dir in $searchDirs) {
                if (Test-Path $dir) {
                    $found = Get-ChildItem -Path $dir -Filter $exeName -Recurse -ErrorAction SilentlyContinue -Depth 3 | Select-Object -First 1
                    if ($found) {
                        $foundPath = $found.FullName
                        Write-Log "$($browser.Name) - 目录扫描成功: $foundPath" "SUCCESS"
                        break
                    }
                }
            }
        }
        
        # 如果找到了浏览器，添加到检测列表
        if ($foundPath) {
            $detected[$key] = $browser.Clone()
            $detected[$key].ExePath = $foundPath
            $detected[$key].InstallDir = Split-Path $foundPath -Parent
        }
    }
    
    if ($detected.Count -eq 0) {
        Write-Log "未检测到任何支持的浏览器！" "ERROR"
        exit 1
    }
    
    Write-Log "共检测到 $($detected.Count) 个浏览器" "SUCCESS"
    return $detected
}

# ===== Chromium 高级反检测配置 =====
function Set-ChromiumAdvancedConfig {
    param(
        [string]$BrowserKey,
        [hashtable]$BrowserInfo
    )
    
    $regPath = $BrowserInfo.RegKey
    $browserName = $BrowserInfo.Name
    
    Write-Log "优化 $browserName..." "HEADER"
    
    # 清理Session文件（防止恢复旧标签页）
    $userDataPath = $BrowserInfo.UserDataPath
    if ($userDataPath -and (Test-Path $userDataPath)) {
        $sessionPaths = @(
            "$userDataPath\Default\Sessions",
            "$userDataPath\Default\Session Storage"
        )
        foreach ($sessionPath in $sessionPaths) {
            if (Test-Path $sessionPath) {
                try {
                    Remove-Item -Path "$sessionPath\*" -Recurse -Force -ErrorAction SilentlyContinue
                    Write-Log "清理Session文件: $sessionPath" "SUCCESS"
                } catch {
                    Write-Log "清理Session文件失败: $_" "WARNING"
                }
            }
        }
    }
    
    # 创建注册表键
    if (-not (Test-Path $regPath)) {
        try {
            New-Item -Path $regPath -Force | Out-Null
            Write-Log "创建注册表键: $regPath" "SUCCESS"
        } catch {
            Write-Log "创建注册表键失败: $_" "ERROR"
            return
        }
    }
    
    # 核心策略
    $policies = @{
        # 隐私保护
        "MetricsReportingEnabled" = 0
        "SpellcheckEnabled" = 0
        "SearchSuggestEnabled" = 0
        "AlternateErrorPagesEnabled" = 0
        "SafeBrowsingEnabled" = 0
        "SigninAllowed" = 0
        "SyncDisabled" = 1
        "BrowserSignin" = 0
        "PasswordManagerEnabled" = 1
        "AutofillAddressEnabled" = 0
        "AutofillCreditCardEnabled" = 0
        
        # 反检测核心
        "UserAgentClientHintsEnabled" = 0
        "UserAgentClientHintsGREASEUpdateEnabled" = 0
        "WebRtcIPHandlingPolicy" = "disable_non_proxied_udp"
        "WebRtcEventLogCollectionAllowed" = 0
        
        # DNS-over-HTTPS
        "DnsOverHttpsMode" = "secure"
        "DnsOverHttpsTemplates" = "https://cloudflare-dns.com/dns-query"
        
        # 安全
        "SSLErrorOverrideAllowed" = 0
        "ThirdPartyBlockingEnabled" = 1
        "BlockThirdPartyCookies" = 1
        "DefaultCookiesSetting" = 1
        "DefaultNotificationsSetting" = 2
        "DefaultGeolocationSetting" = 2
        
        # UI/UX
        "BookmarkBarEnabled" = 1
        "ShowHomeButton" = 0
        "HomepageLocation" = "about:blank"
        "HomepageIsNewTabPage" = 1  # 主页就是新标签页
        "RestoreOnStartup" = 1  # 1 = 打开新标签页（空白页）
        "NewTabPageLocation" = "about:blank"
        "BackgroundModeEnabled" = 0
        "HideWebStoreIcon" = 1
        "PromotionalTabsEnabled" = 0
        "UserFeedbackAllowed" = 0
        "DefaultBrowserSettingEnabled" = 0
        
        # 高级反检测
        "UrlKeyedAnonymizedDataCollectionEnabled" = 0
        "NetworkPredictionOptions" = 2
        "BuiltInDnsClientEnabled" = 0
        "PaymentMethodQueryEnabled" = 0
        "SignedHTTPExchangeEnabled" = 0
        "ImportAutofillFormData" = 0
        "ImportBookmarks" = 0
        "ImportHistory" = 0
        "ImportSavedPasswords" = 0
        
        # 隐私沙盒
        "PrivacySandboxAdMeasurementEnabled" = 0
        "PrivacySandboxAdTopicsEnabled" = 0
        "PrivacySandboxSiteEnabledAdsEnabled" = 0
        "PrivacySandboxPromptEnabled" = 0
        
        # 性能
        "HardwareAccelerationModeEnabled" = 1
    }
    
    # 语言设置（差异化）
    $lang = $languageConfig[$BrowserKey]
    $policies["ApplicationLocaleValue"] = $lang
    $policies["SpellcheckLanguage"] = $lang
    
    # 浏览器特定策略
    if ($BrowserKey -eq "Brave") {
        $policies["BraveRewardsDisabled"] = 1
        $policies["BraveWalletDisabled"] = 1
        $policies["BraveAdsEnabled"] = 0
        $policies["TorDisabled"] = 0
        $policies["TranslateEnabled"] = 0  # v12.7
        $policies["BraveVPNEnabled"] = 0  # v12.7
        $policies["IPFSEnabled"] = 0  # v12.7
    }
    
    if ($BrowserKey -eq "Edge") {
        $policies["EdgeShoppingAssistantEnabled"] = 0
        $policies["EdgeCollectionsEnabled"] = 0
        $policies["ShowRecommendationsEnabled"] = 0
        $policies["ConfigureDoNotTrack"] = 1
        $policies["EdgeEnhanceImagesEnabled"] = 0
        $policies["EdgeFollowEnabled"] = 0
        $policies["TranslateEnabled"] = 0  # v12.6
        $policies["EdgeWorkspacesEnabled"] = 0  # v12.6
        $policies["HubsSidebarEnabled"] = 0  # v12.6
        $policies["EdgeWalletEnabled"] = 0  # v12.6
    }
    
    if ($BrowserKey -eq "Opera") {
        # Opera 特定：禁用新闻、广告、搜索引擎
        $policies["DefaultSearchProviderEnabled"] = 1
        $policies["DefaultSearchProviderName"] = "Google"
        $policies["DefaultSearchProviderSearchURL"] = "https://www.google.com/search?q={searchTerms}"
        $policies["TranslateEnabled"] = 0  # v12.8
        # 注意：Opera VPN、News、Turbo 等功能无法通过策略禁用，需要手动配置
    }
    
    if ($BrowserKey -eq "Chrome") {
        # Chrome 特定：禁用 Google 服务集成
        $policies["ChromeCleanupEnabled"] = 0
        $policies["ChromeCleanupReportingEnabled"] = 0
        $policies["MediaRouterEnabled"] = 0  # 禁用 Chromecast
        $policies["CloudPrintSubmitEnabled"] = 0
        $policies["TranslateEnabled"] = 0  # v12.5
        $policies["QuicAllowed"] = 1  # v12.5
    }
    
    if ($BrowserKey -eq "Vivaldi") {
        # Vivaldi 特定：禁用独特功能
        # 注意：Vivaldi 的侧边栏、笔记等功能可能需要手动配置
        $policies["TranslateEnabled"] = 0
        $policies["QuicAllowed"] = 1  # v12.9
    }
    

    if ($BrowserKey -eq "Chromium") {
        # Chromium 特定：纯净开源版本
        $policies["TranslateEnabled"] = 0  # v13.0
        $policies["QuicAllowed"] = 1  # v13.0
    }
    # 应用策略
    $successCount = 0
    $failCount = 0
    
    foreach ($name in $policies.Keys) {
        try {
            $value = $policies[$name]
            if ($value -is [string]) {
                Set-ItemProperty -Path $regPath -Name $name -Value $value -Type String -Force -ErrorAction Stop
            } else {
                Set-ItemProperty -Path $regPath -Name $name -Value $value -Type DWord -Force -ErrorAction Stop
            }
            $successCount++
        } catch {
            $failCount++
            Write-Log "设置策略失败 [$name]: $_" "WARNING"
        }
    }
    
    # 删除旧版本遗留的配置（v13.4之前）
    $legacyKeys = @("RestoreOnStartupURLs")
    foreach ($key in $legacyKeys) {
        try {
            if (Get-ItemProperty -Path $regPath -Name $key -ErrorAction SilentlyContinue) {
                Remove-ItemProperty -Path $regPath -Name $key -Force -ErrorAction Stop
                Write-Log "删除旧配置: $key" "SUCCESS"
            }
        } catch {
            Write-Log "删除旧配置失败 [$key]: $_" "WARNING"
        }
    }
    
    Write-Log "成功应用 $successCount 个策略 ($failCount 失败)" "SUCCESS"
}

# ===== Firefox 高级反检测配置 =====
function Set-FirefoxAdvancedConfig {
    param(
        [string]$BrowserKey,
        [hashtable]$BrowserInfo
    )
    
    $browserName = $BrowserInfo.Name
    $installDir = $BrowserInfo.InstallDir
    
    # 检测浏览器类型
    
    Write-Log "优化 $browserName..." "HEADER"
    
    if (-not $installDir -or -not (Test-Path $installDir)) {
        Write-Log "未找到安装目录" "ERROR"
        return
    }
    
    # 创建 distribution 目录
    $distDir = Join-Path $installDir "distribution"
    if (-not (Test-Path $distDir)) {
        try {
            New-Item -Path $distDir -ItemType Directory -Force | Out-Null
            Write-Log "创建目录: $distDir" "SUCCESS"
        } catch {
            Write-Log "创建目录失败: $_" "ERROR"
            return
        }
    }
    
    # policies.json
    $policiesPath = Join-Path $distDir "policies.json"
    $lang = $languageConfig[$BrowserKey]
    
    $policiesContent = @{
        policies = @{
            DisplayBookmarksToolbar = "always"
            Homepage = @{
                URL = "about:blank"
                Locked = $true
                StartPage = "none"
            }
            NewTabPage = $false
            DisableTelemetry = $true
            DisablePocket = $true
            DisableFirefoxStudies = $true
            DisableFirefoxAccounts = $true
            DisableFormHistory = $true
            OfferToSaveLogins = $true
            PasswordManagerEnabled = $true
            FirefoxHome = @{
                Search = $false
                TopSites = $false
                Highlights = $false
                Pocket = $false
                Snippets = $false
            }
            UserMessaging = @{
                WhatsNew = $false
                ExtensionRecommendations = $false
                FeatureRecommendations = $false
                UrlbarInterventions = $false
                SkipOnboarding = $true
            }
            Cookies = @{
                Behavior = "reject-tracker-and-partition-foreign"
                BehaviorPrivateBrowsing = "reject-tracker-and-partition-foreign"
            }
            EnableTrackingProtection = @{
                Value = $true
                Locked = $true
                Cryptomining = $true
                Fingerprinting = $true
            }
            DNSOverHTTPS = @{
                Enabled = $true
                ProviderURL = "https://cloudflare-dns.com/dns-query"
            }
            HardwareAcceleration = $true
        }
    }
    
    try {
        $json = $policiesContent | ConvertTo-Json -Depth 10
        [System.IO.File]::WriteAllText($policiesPath, $json, [System.Text.Encoding]::UTF8)
        Write-Log "创建 policies.json" "SUCCESS"
    } catch {
        Write-Log "创建 policies.json 失败: $_" "ERROR"
    }
    
    # user.js（高级配置）
    $profilesDir = "$env:APPDATA\Mozilla\Firefox\Profiles"
    if ($BrowserKey -eq "LibreWolf") {
        $profilesDir = "$env:APPDATA\LibreWolf\Profiles"
    } elseif ($BrowserKey -eq "Zen Browser") {
        $profilesDir = "$env:APPDATA\zen\Profiles"
    }
    
    if (Test-Path $profilesDir) {
        $profiles = Get-ChildItem -Path $profilesDir -Directory -ErrorAction SilentlyContinue
        
        foreach ($profile in $profiles) {
            $userJsPath = Join-Path $profile.FullName "user.js"
            
            # Zen Browser 使用更自然的语言格式（带 q 值）
            $langConfig = if ($BrowserKey -eq "Zen Browser") {
                "user_pref(`"intl.accept_languages`", `"$lang,en-US;q=0.9,en;q=0.8`");"
            } else {
                "user_pref(`"intl.accept_languages`", `"$lang, en-US, en`");"
            }
            
            $userJsContent = @"
// ===== 核心反指纹 =====
user_pref("privacy.resistFingerprinting", true);
user_pref("privacy.resistFingerprinting.letterboxing", true);

// ===== WebRTC 完全禁用 =====
user_pref("media.peerconnection.enabled", false);
user_pref("media.peerconnection.ice.default_address_only", true);
user_pref("media.peerconnection.ice.no_host", true);
user_pref("media.peerconnection.ice.proxy_only_if_behind_proxy", true);

// ===== 地理位置和传感器 =====
user_pref("geo.enabled", false);
user_pref("geo.provider.network.url", "");
user_pref("device.sensors.enabled", false);
user_pref("media.navigator.enabled", true);

// ===== 第一方隔离（已删除，resistFingerprinting 提供足够保护）=====
// user_pref("privacy.firstparty.isolate", true);
// user_pref("privacy.firstparty.isolate.restrict_opener_access", true);

// ===== Cookie 策略 =====
user_pref("network.cookie.cookieBehavior", 5);
user_pref("network.cookie.lifetimePolicy", 0);
user_pref("browser.cache.offline.enable", false);
user_pref("privacy.clearOnShutdown.cookies", false);
user_pref("privacy.clearOnShutdown.cache", false);
user_pref("privacy.clearOnShutdown.sessions", false);
user_pref("privacy.clearOnShutdown.offlineApps", false);

// ===== 追踪保护 =====
user_pref("privacy.trackingprotection.enabled", true);
user_pref("privacy.trackingprotection.pbmode.enabled", true);
user_pref("privacy.trackingprotection.socialtracking.enabled", true);

// ===== Referer 控制 =====
user_pref("network.http.referer.XOriginPolicy", 2);
user_pref("network.http.referer.XOriginTrimmingPolicy", 2);

// ===== DNS-over-HTTPS =====
user_pref("network.trr.mode", 3);
user_pref("network.trr.uri", "https://cloudflare-dns.com/dns-query");

// ===== 语言设置 =====
$langConfig
user_pref("intl.locale.requested", "$lang");
user_pref("intl.locale.matchOS", false);
user_pref("general.useragent.locale", "$lang");

// ===== 电池 API =====
user_pref("dom.battery.enabled", false);

// ===== 遥测 =====
user_pref("toolkit.telemetry.enabled", false);
user_pref("toolkit.telemetry.unified", false);
user_pref("datareporting.healthreport.uploadEnabled", false);

// ===== 内容拦截和隐私增强 (v13.1) =====
user_pref("browser.contentblocking.category", "strict");
user_pref("privacy.donottrackheader.enabled", true);

// ===== 书签新标签页打开并跳转 =====
user_pref("browser.tabs.loadBookmarksInTabs", true);
user_pref("browser.tabs.loadBookmarksInBackground", false);
"@
            
            try {
                [System.IO.File]::WriteAllText($userJsPath, $userJsContent, [System.Text.Encoding]::UTF8)
                Write-Log "创建 user.js: $($profile.Name)" "SUCCESS"
            } catch {
                Write-Log "创建 user.js 失败: $_" "WARNING"
            }
        }
    }
}

# ===== 生成启动脚本 =====
function Generate-LaunchScripts {
    param([hashtable]$Browsers)
    
    Write-Log "生成启动脚本..." "HEADER"
    
    $scriptDir = Join-Path $PSScriptRoot "..\..\scripts\launch"
    if (-not (Test-Path $scriptDir)) {
        New-Item -Path $scriptDir -ItemType Directory -Force | Out-Null
    }
    
    foreach ($key in $Browsers.Keys) {
        $browser = $Browsers[$key]
        $exePath = $browser.ExePath
        $lang = $languageConfig[$key]
        
        $launchScript = "@echo off`r`n"
        $launchScript += "REM $($browser.Name) 启动脚本 - 反检测配置`r`n`r`n"
        
        if ($browser.Type -eq "Chromium") {
            $acceptLang = "$lang,$($lang.Split('-')[0]);q=0.9,en-US;q=0.8,en;q=0.7"
            $userAgent = $userAgentConfig[$key]
            
            $launchScript += "start `"`" `"$exePath`" ^`r`n"
            $launchScript += "--lang=$lang ^`r`n"
            $launchScript += "--accept-lang=`"$acceptLang`" ^`r`n"
            
            # User-Agent 差异化
            if ($userAgent) {
                $launchScript += "--user-agent=`"$userAgent`" ^`r`n"
            }
            
            $launchScript += "--disable-blink-features=AutomationControlled ^`r`n"
            $launchScript += "--exclude-switches=enable-automation ^`r`n"
            $launchScript += "--disable-features=UserAgentClientHints,PrivacySandboxSettings4,FederatedCredentialManagement,AutofillServerCommunication,WebRtcHideLocalIpsWithMdns ^`r`n"
            $launchScript += "--disable-client-side-phishing-detection ^`r`n"
            $launchScript += "--disable-sync ^`r`n"
            $launchScript += "--disable-background-networking ^`r`n"
            $launchScript += "--disable-default-apps ^`r`n"
            $launchScript += "--disable-component-extensions-with-background-pages ^`r`n"
            $launchScript += "--disable-breakpad ^`r`n"
            $launchScript += "--disable-crash-reporter ^`r`n"
            $launchScript += "--metrics-recording-only ^`r`n"
            $launchScript += "--no-first-run ^`r`n"
            $launchScript += "--no-default-browser-check ^`r`n"
            $launchScript += "--no-service-autorun ^`r`n"
            $launchScript += "--force-webrtc-ip-handling-policy=disable_non_proxied_udp`r`n"
            $launchScript += "`r`n"
            
            # 任务专用浏览器：最大化反检测（牺牲部分功能）
            if ($key -in $taskBrowsers) {
                $launchScript += "--disable-reading-from-canvas ^`r`n"
                $launchScript += "--disable-webgl ^`r`n"
                $launchScript += "--disable-webgl2 ^`r`n"
            }
            
            # Brave 专属参数（游戏浏览器，保留功能）
            if ($key -eq "Brave") {
                $launchScript += "--fingerprinting-canvas-image-data-noise ^`r`n"
                $launchScript += "--fingerprinting-canvas-measuretext-noise ^`r`n"
                $launchScript += "--fingerprinting-client-rects-noise ^`r`n"
            }
            
            # Opera 专属：注意事项
            # Opera 的 VPN/News/Turbo 无法通过启动参数禁用，需要手动配置
            # 启动后访问 opera://settings 手动关闭这些功能
            
            $launchScript += "`r`necho $($browser.Name) 已启动`r`n"
            if ($key -in $taskBrowsers) {
                $launchScript += "echo [任务模式] Canvas/WebGL 已禁用`r`n"
            } else {
                $launchScript += "echo [游戏模式] 完整功能`r`n"
            }
            $launchScript += "`r`n"
        } else {
            # Firefox 系
            $launchScript += "start `"`" `"$exePath`" -no-remote`r`n"
            $launchScript += "`r`necho $($browser.Name) 已启动`r`n"
        }
        
        $scriptFile = Join-Path $scriptDir "Launch_$key.bat"
        [System.IO.File]::WriteAllText($scriptFile, $launchScript, [System.Text.Encoding]::ASCII)
        Write-Log "生成启动脚本: Launch_$key.bat" "SUCCESS"
    }
    
    # 生成 Launch_All.bat
    $allScript = "@echo off`r`n"
    $allScript += "echo 正在启动所有浏览器...`r`n`r`n"
    foreach ($key in $Browsers.Keys) {
        $allScript += "call `"%~dp0Launch_$key.bat`"`r`n"
        $allScript += "timeout /t 2 /nobreak >nul`r`n"
    }
    $allScript += "`r`necho 所有浏览器已启动`r`n"
    $allScript += "pause`r`n"
    
    $allScriptPath = Join-Path $scriptDir "Launch_All.bat"
    [System.IO.File]::WriteAllText($allScriptPath, $allScript, [System.Text.Encoding]::ASCII)
    Write-Log "生成批量启动脚本: Launch_All.bat" "SUCCESS"
}

# ===== 主流程 =====
Write-Host "`n========================================" -ForegroundColor Green
Write-Host "  多浏览器反检测优化工具 v13.7" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host "  作者: Kiro (AI Development Environment)" -ForegroundColor Cyan
Write-Host "  日期: 2026-05-07" -ForegroundColor Cyan
Write-Host "  更新: 修复Opera无效参数、删除Firefox字体配置、增强WebRTC防护" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Green

Write-Log "优化日志保存至: $logFile" "INFO"

# 检测浏览器
$detectedBrowsers = Get-InstalledBrowsers

# 显示选择菜单
Write-Host "`n检测到以下浏览器:" -ForegroundColor Cyan
$browserList = @($detectedBrowsers.Keys)
for ($i = 0; $i -lt $browserList.Count; $i++) {
    $key = $browserList[$i]
    Write-Host "  [$i] $($detectedBrowsers[$key].Name)" -ForegroundColor Yellow
}
Write-Host "  [A] 优化全部浏览器" -ForegroundColor Green

$choice = Read-Host "`n请选择要优化的浏览器（输入编号，多个用逗号分隔，或输入 A 优化全部）"

# 处理选择
$selectedBrowsers = @{}
if ($choice -eq "A" -or $choice -eq "a") {
    $selectedBrowsers = $detectedBrowsers
    Write-Log "用户选择: 优化全部浏览器" "INFO"
} else {
    $indices = $choice -split ',' | ForEach-Object { $_.Trim() }
    foreach ($index in $indices) {
        if ($index -match '^\d+$' -and [int]$index -lt $browserList.Count) {
            $key = $browserList[[int]$index]
            $selectedBrowsers[$key] = $detectedBrowsers[$key]
        }
    }
    Write-Log "用户选择: $($selectedBrowsers.Count) 个浏览器" "INFO"
}

if ($selectedBrowsers.Count -eq 0) {
    Write-Log "未选择任何浏览器，退出" "ERROR"
    exit 1
}

# 优化浏览器
foreach ($key in $selectedBrowsers.Keys) {
    $browser = $selectedBrowsers[$key]
    
    if ($browser.Type -eq "Chromium") {
        Set-ChromiumAdvancedConfig -BrowserKey $key -BrowserInfo $browser
    } elseif ($browser.Type -eq "Firefox") {
        Set-FirefoxAdvancedConfig -BrowserKey $key -BrowserInfo $browser
    }
}

# 生成启动脚本
Generate-LaunchScripts -Browsers $selectedBrowsers

# 完成
Write-Host "`n========================================" -ForegroundColor Green
Write-Host "  优化完成！" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Log "成功优化 $($selectedBrowsers.Count) 个浏览器" "SUCCESS"
Write-Log "启动脚本位置: scripts\launch\" "INFO"
Write-Log "日志文件: $logFile" "INFO"

# Opera 特别提示
if ($selectedBrowsers.ContainsKey("Opera")) {
    Write-Host "`n⚠️  Opera 用户必读：" -ForegroundColor Yellow
    Write-Host "   Opera 的 VPN/News/Turbo 无法通过启动参数禁用，必须手动配置：" -ForegroundColor Yellow
    Write-Host "" -ForegroundColor Yellow
    Write-Host "   1. 启动 Opera 后，访问 opera://settings" -ForegroundColor Cyan
    Write-Host "   2. 隐私和安全 → 关闭 '启用 VPN'" -ForegroundColor Cyan
    Write-Host "   3. 启动页 → 关闭 '在启动页显示新闻'" -ForegroundColor Cyan
    Write-Host "   4. 高级 → 关闭 'Opera Turbo'" -ForegroundColor Cyan
    Write-Host "   5. 搜索 → 将默认搜索引擎改为 Google" -ForegroundColor Cyan
    Write-Host "" -ForegroundColor Yellow
    Write-Host "   验证策略：访问 opera://policy/ 确认策略已生效" -ForegroundColor Yellow
    Write-Host "   扩展安装：Opera 扩展需要从 addons.opera.com 安装（不兼容 Chrome 商店）" -ForegroundColor Yellow
}

# ===== 创建桌面启动器 =====
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  创建桌面启动器" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "是否为优化后的浏览器创建桌面启动器？" -ForegroundColor Yellow
Write-Host "- 启动器将使用浏览器原生图标" -ForegroundColor White
Write-Host "- 启动器会自动加载反检测参数" -ForegroundColor White
Write-Host "- 名称格式：'浏览器名 (Anti-Detect)'" -ForegroundColor White
Write-Host "" -ForegroundColor White
$createLaunchers = Read-Host "创建桌面启动器？(Y/N)"

if ($createLaunchers -eq "Y" -or $createLaunchers -eq "y") {
    Write-Host "`n正在创建桌面启动器..." -ForegroundColor Cyan
    
    $desktopPath = [Environment]::GetFolderPath("Desktop")
    $launchScriptsDir = Join-Path $PSScriptRoot "..\..\scripts\launch"
    $WScriptShell = New-Object -ComObject WScript.Shell
    
    $launcherCount = 0
    
    foreach ($key in $selectedBrowsers.Keys) {
        $browser = $selectedBrowsers[$key]
        $browserName = $browser.Name
        
        # 确定图标路径（使用浏览器原生图标）
        $iconPath = $browser.ExePath
        
        # 确定启动脚本路径
        $launchScriptName = "Launch_$key.bat"
        $launchScriptPath = Join-Path $launchScriptsDir $launchScriptName
        
        if (-not (Test-Path $launchScriptPath)) {
            Write-Host "  跳过: $browserName - 启动脚本不存在" -ForegroundColor Yellow
            continue
        }
        
        # 创建快捷方式
        $shortcutName = "$browserName (Anti-Detect).lnk"
        $shortcutPath = Join-Path $desktopPath $shortcutName
        
        try {
            $shortcut = $WScriptShell.CreateShortcut($shortcutPath)
            $shortcut.TargetPath = $launchScriptPath
            $shortcut.WorkingDirectory = $launchScriptsDir
            $shortcut.Description = "Launch $browserName with anti-detection optimizations"
            $shortcut.IconLocation = "$iconPath,0"
            $shortcut.Save()
            
            Write-Host "  ✅ 已创建: $shortcutName" -ForegroundColor Green
            $launcherCount++
        } catch {
            Write-Host "  ❌ 创建失败: $shortcutName - $_" -ForegroundColor Red
        }
    }
    
    Write-Host "`n========================================" -ForegroundColor Green
    Write-Host "  启动器创建完成！" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "成功创建 $launcherCount 个桌面启动器" -ForegroundColor Cyan
    Write-Host "位置: $desktopPath" -ForegroundColor Cyan
    Write-Host "" -ForegroundColor White
    Write-Host "⚠️  重要提示：" -ForegroundColor Yellow
    Write-Host "- 请使用新创建的启动器启动浏览器" -ForegroundColor Yellow
    Write-Host "- 不要使用原浏览器的快捷方式" -ForegroundColor Yellow
    Write-Host "- 启动器会自动加载反检测参数" -ForegroundColor Yellow
} else {
    Write-Host "`n已跳过创建桌面启动器" -ForegroundColor Yellow
    Write-Host "提示: 请使用 scripts\launch\ 目录下的启动脚本启动浏览器" -ForegroundColor Cyan
}

Write-Host "`n按任意键退出..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
