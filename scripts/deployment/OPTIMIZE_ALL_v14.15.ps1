#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Multi-Browser Anti-Detect Optimization Tool v14.15
.DESCRIPTION
    Automatically detect and optimize 9 browsers with advanced anti-detection configurations.
    Supports: Chrome, Edge, Brave, Opera, Vivaldi, Chromium, Firefox, LibreWolf, Zen Browser
.NOTES
    Author: Kiro (AI Development Environment)
    Version: 14.15 - 修复4个BUG（Edge WebRTC策略、Firefox AI策略、日期不一致、Edge Chrome-only策略）
    Date: 2026-05-18
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
    "Zen Browser" = "zh-CN"  # v14.9: 修正为单个locale
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
        
        # v14.12: Chrome/Chromium互相区分 - 用ProductName验证
        if ($foundPath -and ($key -eq "Chrome" -or $key -eq "Chromium")) {
            try {
                $versionInfo = (Get-Item $foundPath).VersionInfo
                $productName = $versionInfo.ProductName
                
                if ($key -eq "Chrome" -and $productName -notlike "*Google Chrome*") {
                    Write-Log "$($browser.Name) - ProductName不匹配（$productName），跳过" "WARNING"
                    $foundPath = $null
                } elseif ($key -eq "Chromium" -and $productName -notlike "*Chromium*") {
                    Write-Log "$($browser.Name) - ProductName不匹配（$productName），跳过" "WARNING"
                    $foundPath = $null
                }
            } catch {
                # 如果无法读取VersionInfo，用路径判断
                if ($key -eq "Chromium" -and $foundPath -notlike "*\Chromium\*") {
                    Write-Log "$($browser.Name) - 路径不包含Chromium，跳过（可能是Chrome）" "WARNING"
                    $foundPath = $null
                } elseif ($key -eq "Chrome" -and $foundPath -like "*\Chromium\*") {
                    Write-Log "$($browser.Name) - 路径包含Chromium，跳过（可能是Chromium）" "WARNING"
                    $foundPath = $null
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
    
    # v14.3: 删除清理Session文件逻辑（不必要，且可能影响网页状态）
    
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
        # v14.12: 删除SafeBrowsingEnabled - Edge不使用此策略，用SmartScreenEnabled
        # v14.15: SigninAllowed和BrowserSignin - Edge只用BrowserSignin
        "PasswordManagerEnabled" = 1
        "AutofillAddressEnabled" = 1  # v14.1: 启用自动填充
        "AutofillCreditCardEnabled" = 1  # v14.1: 启用自动填充
        
        # 反检测核心
        # v14.9: 删除 - 虚假优化，暴露浏览器被修改
        # v14.9: 删除 - 虚假优化，暴露浏览器被修改
        # v14.9: WebRTC策略 - Edge使用专用策略名
        "WebRtcEventLogCollectionAllowed" = 0
        "QuicAllowed" = 0  # v14.9: 禁用QUIC（所有Chromium系）
        "EnableMediaRouter" = 0  # v14.11: 禁用Cast/媒体路由（所有Chromium系）
        
        # DNS-over-HTTPS
        "DnsOverHttpsMode" = "automatic"  # v14.2: automatic模式（有fallback，更稳定）
        "DnsOverHttpsTemplates" = "https://cloudflare-dns.com/dns-query"
        
        # 安全
        # "SSLErrorOverrideAllowed" = 1  # v14.3: 删除，不应允许绕过SSL警告
        "BlockThirdPartyCookies" = 1
        "DefaultCookiesSetting" = 1
        "DefaultNotificationsSetting" = 2
        "DefaultGeolocationSetting" = 2
        
        # UI/UX
        # v14.15: BookmarkBarEnabled - Edge不支持，用FavoritesBarEnabled
        "ShowHomeButton" = 1  # v14.9: 保留主页按钮
        "HomepageLocation" = "about:blank"
        "HomepageIsNewTabPage" = 1  # 主页就是新标签页
        "RestoreOnStartup" = 5  # v14.1: 5 = 打开新标签页（空白页）
        "NewTabPageLocation" = "about:blank"
        "BackgroundModeEnabled" = 0
        # v14.15: HideWebStoreIcon - Edge不支持
        "UserFeedbackAllowed" = 0
        "DefaultBrowserSettingEnabled" = 0
        
        # 高级反检测
        # v14.15: UrlKeyedAnonymizedDataCollectionEnabled - Edge不支持
        # v14.9: 删除 - 负优化，牺牲速度
        # v14.9: 删除 - 与DoH冲突
        "PaymentMethodQueryEnabled" = 0
        "SignedHTTPExchangeEnabled" = 0
        "ImportAutofillFormData" = 1  # v14.1: 允许导入
        "ImportBookmarks" = 1  # v14.1: 允许导入书签
        "ImportHistory" = 1  # v14.1: 允许导入历史
        "ImportSavedPasswords" = 1  # v14.1: 允许导入密码
        
        # 隐私沙盒
        # v14.15: PrivacySandbox* - Edge不支持
        
        # 性能
        "HardwareAccelerationModeEnabled" = 1
    }
    
    # v14.15: Chrome-only策略（Edge不支持）
    if ($BrowserKey -ne "Edge") {
        $policies["SigninAllowed"] = 1  # v14.1: 允许登录
        $policies["BrowserSignin"] = 1  # v14.1: 允许浏览器登录
        $policies["BookmarkBarEnabled"] = 1
        $policies["HideWebStoreIcon"] = 1
        $policies["PromotionalTabsEnabled"] = 0
        $policies["PromotionsEnabled"] = 0  # v14.14: 补充新版促销策略
        $policies["UrlKeyedAnonymizedDataCollectionEnabled"] = 0
        $policies["PrivacySandboxAdMeasurementEnabled"] = 0
        $policies["PrivacySandboxAdTopicsEnabled"] = 0
        $policies["PrivacySandboxSiteEnabledAdsEnabled"] = 0
        $policies["PrivacySandboxPromptEnabled"] = 0
    }
    
    # 语言设置（差异化）
    $lang = $languageConfig[$BrowserKey]
    $policies["ApplicationLocaleValue"] = $lang
    # v14.9: 删除 - 已禁用拼写检查，此项冗余
    
    # v14.12: 删除通用WebRTC配置块 - 移到浏览器特定块
    
    # 浏览器特定策略
    if ($BrowserKey -eq "Brave") {
        # v14.12: Brave专用WebRTC策略
        $policies["WebRtcIPHandling"] = "disable_non_proxied_udp"
        
        # Brave特定功能禁用
        $policies["BraveRewardsDisabled"] = 1
        $policies["BraveWalletDisabled"] = 1
        $policies["TorDisabled"] = 1  # v14.2: 1 = 禁用Tor（0是启用）
        $policies["TranslateEnabled"] = 0  # v12.7
        $policies["BraveVPNDisabled"] = 1  # v14.2: 修正策略名
        $policies["IPFSEnabled"] = 0  # v12.7
        $policies["BraveNewsDisabled"] = 1  # v14.3: 修正策略名
        $policies["BraveAIChatEnabled"] = 0  # v14.3: 禁用AI Chat
        $policies["BraveTalkDisabled"] = 1  # v14.3: 禁用Talk
        # v14.9: 补充Brave官方隐私策略
        $policies["BraveP3AEnabled"] = 0
        $policies["BraveStatsPingEnabled"] = 0
        $policies["BraveWebDiscoveryEnabled"] = 0
    }
    
    if ($BrowserKey -eq "Edge") {
        # v14.15: Edge专用WebRTC策略（删除无效的WebRtcIPHandling，补充WebRtcIPHandlingUrl）
        $policies["WebRtcLocalhostIpHandling"] = "disable_non_proxied_udp"
        $policies["WebRtcIPHandlingUrl"] = '[{"url":"*","handling":"disable_non_proxied_udp"}]'  # v14.15: Edge 135+官方策略
        $policies["SmartScreenEnabled"] = 1  # v14.12: Edge使用SmartScreen而非SafeBrowsing
        
        # v14.13: Edge专用书签栏策略
        $policies["FavoritesBarEnabled"] = 1  # v14.13: Edge使用FavoritesBar而非BookmarkBar
        
        # v14.15: Edge专用策略（删除Chrome-only策略）
        $policies["BrowserSignin"] = 1  # Edge使用BrowserSignin而非SigninAllowed
        $policies["TrackingPrevention"] = 2  # v14.15: Edge追踪防护（2=平衡，不用3=严格）
        $policies["ShowMicrosoftRewards"] = 0  # v14.15: 禁用Microsoft Rewards
        $policies["MicrosoftEdgeInsiderPromotionEnabled"] = 0  # v14.15: 禁用Insider推广
        $policies["VisualSearchEnabled"] = 0  # v14.15: 禁用视觉搜索
        
        # Edge特定功能禁用
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
        $policies["StartupBoostEnabled"] = 0  # v14.1: 禁用启动加速
        $policies["DefaultBrowserSettingsCampaignEnabled"] = 0  # v14.1: 禁用默认浏览器推广
        $policies["EdgeDiscoverEnabled"] = 0  # v14.2: 禁用Discover/Copilot侧边栏
        # v14.10: 删除冗余WebRTC配置（已在通用配置块设置）
        # v14.8: 补充Edge新闻内容专用策略
        $policies["NewTabPageContentEnabled"] = 0
        $policies["NewTabPageQuickLinksEnabled"] = 0
    }
    
    if ($BrowserKey -eq "Opera") {
        # v14.12: Opera专用WebRTC和安全浏览策略
        $policies["WebRtcIPHandling"] = "disable_non_proxied_udp"
        $policies["SafeBrowsingProtectionLevel"] = 1  # v14.12: 标准保护（修复CF验证）
        
        # Opera 特定：禁用新闻、广告、搜索引擎
        $policies["DefaultSearchProviderEnabled"] = 1
        $policies["DefaultSearchProviderName"] = "Google"
        $policies["DefaultSearchProviderSearchURL"] = "https://www.google.com/search?q={searchTerms}"
        $policies["TranslateEnabled"] = 0  # v12.8
        # 注意：Opera VPN、News、Turbo 等功能无法通过策略禁用，需要手动配置
    }
    
    if ($BrowserKey -eq "Chrome") {
        # v14.12: Chrome专用WebRTC和安全浏览策略
        $policies["WebRtcIPHandling"] = "disable_non_proxied_udp"
        $policies["SafeBrowsingProtectionLevel"] = 1  # v14.12: 标准保护（修复CF验证）
        
        # v14.11: 删除MediaRouterEnabled - 虚假优化（策略名错误，正确的是EnableMediaRouter）
        $policies["TranslateEnabled"] = 0  # v12.5
    }
    
    if ($BrowserKey -eq "Vivaldi") {
        # v14.12: Vivaldi专用WebRTC和安全浏览策略
        $policies["WebRtcIPHandling"] = "disable_non_proxied_udp"
        $policies["SafeBrowsingProtectionLevel"] = 1  # v14.12: 标准保护（修复CF验证）
        
        # Vivaldi 特定：禁用独特功能
        # 注意：Vivaldi 的侧边栏、笔记等功能可能需要手动配置
        $policies["TranslateEnabled"] = 0
    }
    

    if ($BrowserKey -eq "Chromium") {
        # v14.12: Chromium专用WebRTC和安全浏览策略
        $policies["WebRtcIPHandling"] = "disable_non_proxied_udp"
        $policies["SafeBrowsingProtectionLevel"] = 1  # v14.12: 标准保护（修复CF验证）
        
        # Chromium 特定：纯净开源版本
        $policies["TranslateEnabled"] = 0  # v13.0
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
            DontCheckDefaultBrowser = $true  # v14.8: 修正格式
            ShowHomeButton = $true  # v14.8: 显示主页按钮
            DisableDefaultBrowserAgent = $true  # v14.10: 禁用后台默认浏览器Agent
            BackgroundAppUpdate = $false  # v14.14: 禁用后台更新（不禁用手动更新）
            RequestedLocales = $lang  # v14.11: 补充官方语言策略
            # DisableFirefoxAccounts = $true  # v14.1: 删除此项，允许登录
            DisableFormHistory = $false  # v14.1: 允许表单历史
            OfferToSaveLogins = $true
            PasswordManagerEnabled = $true
            FirefoxHome = @{
                Search = $false
                TopSites = $false
                SponsoredTopSites = $false  # v14.10: 禁用赞助的常用网站
                Highlights = $false
                Pocket = $false
                SponsoredPocket = $false  # v14.10: 禁用赞助的Pocket
                Stories = $false  # v14.10: 禁用Stories
                SponsoredStories = $false  # v14.10: 禁用赞助的Stories
                Snippets = $false
                Locked = $true  # v14.10: 锁定配置
            }
            FirefoxSuggest = @{  # v14.10: 禁用Firefox Suggest赞助建议
                WebSuggestions = $false
                SponsoredSuggestions = $false
                ImproveSuggest = $false
                Locked = $true
            }
            UserMessaging = @{
                WhatsNew = $false
                ExtensionRecommendations = $false
                FeatureRecommendations = $false
                UrlbarInterventions = $false
                SkipOnboarding = $true
                MoreFromMozilla = $false  # v14.13: 补充Mozilla推广内容
                FirefoxLabs = $false  # v14.13: 补充Firefox实验功能推广
            }
            GenerativeAI = @{  # v14.15: 补充官方GenerativeAI策略
                Enabled = $false
                Chatbot = $false
                LinkPreviews = $false
                TabGroups = $false
                Locked = $true
            }
            VisualSearchEnabled = $false  # v14.15: 补充官方视觉搜索策略
            Preferences = @{
                "browser.ml.chat.enabled" = @{ Value = $false; Status = "locked" }  # v14.14: 禁用AI聊天功能
                "browser.ml.chat.sidebar" = @{ Value = $false; Status = "locked" }  # v14.14: 禁用AI聊天侧边栏
                "browser.urlbar.suggest.mdn" = @{ Value = $false; Status = "locked" }  # v14.14: 禁用MDN建议
                "browser.urlbar.trending.featureGate" = @{ Value = $false; Status = "locked" }  # v14.14: 禁用趋势搜索
                "browser.urlbar.weather.featureGate" = @{ Value = $false; Status = "locked" }  # v14.14: 禁用天气建议
                "browser.urlbar.addons.featureGate" = @{ Value = $false; Status = "locked" }  # v14.14: 禁用扩展建议
                "browser.urlbar.pocket.featureGate" = @{ Value = $false; Status = "locked" }  # v14.14: 禁用Pocket建议
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
    
    # v14.12: 添加Profiles目录不存在的警告
    if (-not (Test-Path $profilesDir)) {
        Write-Log "未找到 $BrowserKey 配置目录（$profilesDir），需要先启动一次浏览器后重新运行脚本" "WARNING"
        return
    }
    
    if (Test-Path $profilesDir) {
        $profiles = Get-ChildItem -Path $profilesDir -Directory -ErrorAction SilentlyContinue
        
        if ($profiles.Count -eq 0) {
            Write-Log "未找到 $BrowserKey 配置文件，需要先启动一次浏览器后重新运行脚本" "WARNING"
        }
        
        foreach ($profile in $profiles) {
            $userJsPath = Join-Path $profile.FullName "user.js"
            
            # Zen Browser 使用更自然的语言格式（带 q 值）
            $langConfig = if ($BrowserKey -eq "Zen Browser") {
                "user_pref(`"intl.accept_languages`", `"$lang,en-US;q=0.9,en;q=0.8`");"
            } else {
                "user_pref(`"intl.accept_languages`", `"$lang, en-US, en`");"
            }
            
            $userJsContent = @"
// ===== v14.3 实用版反检测配置 =====

// ===== 温和的指纹保护 =====
user_pref("privacy.trackingprotection.fingerprinting.enabled", true);
user_pref("privacy.trackingprotection.enabled", true);
user_pref("privacy.trackingprotection.pbmode.enabled", true);
user_pref("privacy.trackingprotection.socialtracking.enabled", true);

// ===== WebRTC IP防护（不完全禁用）=====
user_pref("media.peerconnection.enabled", true); 
user_pref("media.peerconnection.ice.default_address_only", true);  // 但防止IP泄露
user_pref("media.peerconnection.ice.no_host", true);
user_pref("media.peerconnection.ice.proxy_only_if_behind_proxy", true);

// ===== 书签在新标签页打开 =====
user_pref("browser.tabs.loadBookmarksInTabs", true); 
user_pref("browser.tabs.loadBookmarksInBackground", false); 

// ===== 地理位置和传感器（不完全禁用）=====
// geo.enabled 和 device.sensors.enabled 不设置，让网站可以请求权限
// v14.9: 删除 - 负优化，破坏地理位置功能
user_pref("media.navigator.enabled", true);

// ===== Cookie 策略 =====
user_pref("network.cookie.cookieBehavior", 5);
user_pref("network.cookie.lifetimePolicy", 0);
// v14.11: 删除 browser.cache.offline.enable - 虚假优化（Firefox 130+已移除）
user_pref("privacy.clearOnShutdown.cookies", false);
user_pref("privacy.clearOnShutdown.cache", false);
user_pref("privacy.clearOnShutdown.sessions", false);
user_pref("privacy.clearOnShutdown.offlineApps", false);

// ===== Referer 控制 =====
// v14.9: 已删除 XOriginTrimmingPolicy - 负优化，破坏登录/支付/SSO

// ===== DNS-over-HTTPS =====
user_pref("network.trr.mode", 2); 
user_pref("network.trr.uri", "https://cloudflare-dns.com/dns-query");

// ===== 语言设置 =====
$langConfig
user_pref("intl.locale.requested", "$lang");
user_pref("intl.locale.matchOS", false);
user_pref("general.useragent.locale", "$lang");

// ===== 电池 API =====
// v14.11: 删除 dom.battery.enabled - 虚假优化（Firefox 131+已移除）

// ===== 遥测 =====
user_pref("toolkit.telemetry.enabled", false);
user_pref("toolkit.telemetry.unified", false);
user_pref("datareporting.healthreport.uploadEnabled", false);

// ===== 内容拦截和隐私增强 (v13.1) =====
user_pref("browser.contentblocking.category", "strict");
user_pref("privacy.donottrackheader.enabled", true);

"@
            
            try {
                [System.IO.File]::WriteAllText($userJsPath, $userJsContent, [System.Text.Encoding]::UTF8)
                Write-Log "创建 user.js: $($profile.Name)" "SUCCESS"
                # v14.9: 添加重启提示
                $prefsPath = Join-Path $profile.FullName "prefs.js"
                if (Test-Path $prefsPath) {
                    Write-Log "检测到已有配置文件，user.js 需要重启浏览器后生效" "WARNING"
                }
            } catch {
                Write-Log "创建 user.js 失败: $_" "WARNING"
            }
        }
    }
}

# ===== 生成启动脚本 =====
# v14.3: 删除启动脚本生成功能（用户要求不使用启动器）


# ===== 主流程 =====
Write-Host "`n========================================" -ForegroundColor Green
Write-Host "  多浏览器反检测优化工具 v14.15" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host "  作者: Kiro (AI Development Environment)" -ForegroundColor Cyan
Write-Host "  日期: 2026-05-18" -ForegroundColor Cyan
Write-Host "  更新: 修复4个BUG（Edge WebRTC策略、Firefox GenerativeAI策略、日期不一致、Edge Chrome-only策略）" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Green

Write-Log "优化日志保存至: $logFile" "INFO"

# 检测浏览器
$detectedBrowsers = Get-InstalledBrowsers

# 显示选择菜单
Write-Host "`n检测到以下浏览器:" -ForegroundColor Cyan
$browserList = @($detectedBrowsers.Keys | Sort-Object)  # v14.9: 固定顺序
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
# v14.3: 删除启动脚本生成调用

# 完成
Write-Host "`n========================================" -ForegroundColor Green
Write-Host "  优化完成！" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Log "成功优化 $($selectedBrowsers.Count) 个浏览器" "SUCCESS"
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

