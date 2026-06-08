<#
.SYNOPSIS
    Multi-browser clean, privacy, and stability optimizer for Windows.
.DESCRIPTION
    Applies official browser policies and profile preferences for Chrome, Chromium,
    Edge, Brave, Opera, Vivaldi, Firefox, LibreWolf, and Zen Browser.

    This script intentionally avoids traffic-evasion or fake fingerprint behavior.
    It focuses on clean UI, privacy, extension policy correctness, blank home/start
    pages, disabled background mode, and reduced promotional/telemetry surfaces.
#>

[CmdletBinding()]
param(
    [switch]$DryRun,
    [switch]$Machine,
    [switch]$UserOnly,
    [bool]$ApplyProfilePreferences = $true,
    [string]$ExtensionConfigPath,
    [switch]$OnlyInstalled
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$RepoRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent

if ([string]::IsNullOrWhiteSpace($ExtensionConfigPath)) {
    $ExtensionConfigPath = Join-Path $RepoRoot 'config\extensions.json'
}

$Script:Changes = New-Object System.Collections.Generic.List[string]
$Script:Warnings = New-Object System.Collections.Generic.List[string]
$Script:DeniedRegistryPaths = @{}

function Write-Info {
    param([string]$Message)
    Write-Host "[INFO] $Message"
}

function Write-Change {
    param([string]$Message)
    $Script:Changes.Add($Message) | Out-Null
    Write-Host "[CHANGE] $Message"
}

function Write-Warn {
    param([string]$Message)
    $Script:Warnings.Add($Message) | Out-Null
    Write-Warning $Message
}

function Test-IsAdmin {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function New-BackupRoot {
    $root = Join-Path $RepoRoot 'backups'
    $stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
    $path = Join-Path $root $stamp
    if (-not $DryRun) {
        New-Item -ItemType Directory -Path $path -Force | Out-Null
    }
    return $path
}

$BackupRoot = New-BackupRoot
$IsAdmin = Test-IsAdmin
$ApplyMachinePolicies = (-not $UserOnly) -and ($IsAdmin -or $Machine)

if ($ApplyMachinePolicies -and -not $IsAdmin) {
    Write-Warn "Machine-level policy writes were requested, but this PowerShell is not elevated. HKLM writes will be skipped."
    $ApplyMachinePolicies = $false
}
elseif ((-not $UserOnly) -and (-not $IsAdmin)) {
    Write-Warn "Current PowerShell is not elevated. HKLM machine policies will be skipped; HKCU policies and user profile preferences can still be written."
}

function Backup-File {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) {
        return
    }
    $safeName = ($Path -replace '[:\\\/]', '_')
    $dest = Join-Path $BackupRoot $safeName
    if (-not $DryRun) {
        Copy-Item -LiteralPath $Path -Destination $dest -Force
    }
}

function Set-RegistryPolicyValue {
    param(
        [string]$Hive,
        [string]$SubPath,
        [string]$Name,
        [ValidateSet('DWord', 'String')]
        [string]$Type,
        [object]$Value
    )

    $path = "Registry::$Hive\$SubPath"
    if ($DryRun) {
        Write-Change "Would set $Hive\$SubPath $Name=$Value ($Type)"
        return
    }

    try {
        if (-not (Test-Path -Path $path)) {
            New-Item -Path $path -Force | Out-Null
        }
        $existing = Get-ItemProperty -Path $path -Name $Name -ErrorAction SilentlyContinue
        if ($Type -eq 'DWord') {
            New-ItemProperty -Path $path -Name $Name -PropertyType DWord -Value ([int]$Value) -Force | Out-Null
        }
        else {
            New-ItemProperty -Path $path -Name $Name -PropertyType String -Value ([string]$Value) -Force | Out-Null
        }
        $existingNames = if ($null -ne $existing) { @($existing.PSObject.Properties | ForEach-Object { $_.Name }) } else { @() }
        $existingValue = if ($existingNames -contains $Name) { $existing.$Name } else { $null }
        if ($null -eq $existing -or $existingValue -ne $Value) {
            Write-Change "Set $Hive\$SubPath $Name=$Value"
        }
    }
    catch {
        $key = "$Hive\$SubPath"
        if (-not $Script:DeniedRegistryPaths.ContainsKey($key)) {
            $Script:DeniedRegistryPaths[$key] = $true
            Write-Warn "Cannot write registry policy path ${key}: $($_.Exception.Message)"
        }
    }
}

function Set-RegistryStringList {
    param(
        [string]$Hive,
        [string]$SubPath,
        [string]$ListName,
        [string[]]$Values
    )

    $normalizedValues = @($Values)
    if ($null -eq $Values -or $normalizedValues.Count -eq 0) {
        $path = "Registry::$Hive\$SubPath\$ListName"
        if ($DryRun) {
            Write-Change "Would clear $Hive\$SubPath\$ListName"
            return
        }
        try {
            if (Test-Path -Path $path) {
                Remove-Item -Path $path -Recurse -Force
                Write-Change "Cleared $Hive\$SubPath\$ListName"
            }
        }
        catch {
            $key = "$Hive\$SubPath\$ListName"
            if (-not $Script:DeniedRegistryPaths.ContainsKey($key)) {
                $Script:DeniedRegistryPaths[$key] = $true
                Write-Warn "Cannot clear registry policy list ${key}: $($_.Exception.Message)"
            }
        }
        return
    }

    $path = "Registry::$Hive\$SubPath\$ListName"
    if ($DryRun) {
        Write-Change "Would write $($normalizedValues.Count) values to $Hive\$SubPath\$ListName"
        return
    }

    try {
        if (-not (Test-Path -Path $path)) {
            New-Item -Path $path -Force | Out-Null
        }
        $current = Get-ItemProperty -Path $path -ErrorAction SilentlyContinue
        if ($null -ne $current) {
            foreach ($prop in $current.PSObject.Properties) {
                if ($prop.Name -match '^\d+$') {
                    Remove-ItemProperty -Path $path -Name $prop.Name -ErrorAction SilentlyContinue
                }
            }
        }

        for ($i = 0; $i -lt $normalizedValues.Count; $i++) {
            New-ItemProperty -Path $path -Name ([string]($i + 1)) -PropertyType String -Value $normalizedValues[$i] -Force | Out-Null
        }
        Write-Change "Wrote $($normalizedValues.Count) values to $Hive\$SubPath\$ListName"
    }
    catch {
        $key = "$Hive\$SubPath\$ListName"
        if (-not $Script:DeniedRegistryPaths.ContainsKey($key)) {
            $Script:DeniedRegistryPaths[$key] = $true
            Write-Warn "Cannot write registry policy list ${key}: $($_.Exception.Message)"
        }
    }
}

function Merge-PolicyLists {
    param([array[]]$Lists)
    $result = New-Object System.Collections.Generic.List[object]
    foreach ($list in $Lists) {
        foreach ($item in $list) {
            $result.Add($item) | Out-Null
        }
    }
    return $result.ToArray()
}

function Convert-JsonNodeToPowerShellObject {
    param([object]$Value)

    if ($null -eq $Value) {
        return $null
    }

    if ($Value -is [System.Collections.IDictionary]) {
        $object = [pscustomobject]@{}
        foreach ($key in $Value.Keys) {
            $object | Add-Member -MemberType NoteProperty -Name ([string]$key) -Value (Convert-JsonNodeToPowerShellObject -Value $Value[$key]) -Force
        }
        return $object
    }

    if ($Value -is [System.Collections.IEnumerable] -and -not ($Value -is [string])) {
        $items = New-Object System.Collections.ArrayList
        foreach ($item in $Value) {
            [void]$items.Add((Convert-JsonNodeToPowerShellObject -Value $item))
        }
        return $items.ToArray()
    }

    return $Value
}

function ConvertFrom-BrowserJsonText {
    param([string]$Raw)

    try {
        return $Raw | ConvertFrom-Json -ErrorAction Stop
    }
    catch {
        $primaryReason = ($_.Exception.Message -split "(`r`n|`n|`r)")[0]
        try {
            Add-Type -AssemblyName System.Web.Extensions -ErrorAction Stop
            $serializer = New-Object System.Web.Script.Serialization.JavaScriptSerializer
            $serializer.MaxJsonLength = [int]::MaxValue
            $parsed = $serializer.DeserializeObject($Raw)
            return Convert-JsonNodeToPowerShellObject -Value $parsed
        }
        catch {
            $fallbackReason = ($_.Exception.Message -split "(`r`n|`n|`r)")[0]
            throw "ConvertFrom-Json failed: $primaryReason; JavaScriptSerializer fallback failed: $fallbackReason"
        }
    }
}

function New-Policy {
    param(
        [string]$Name,
        [ValidateSet('DWord', 'String')]
        [string]$Type,
        [object]$Value
    )
    return [pscustomobject]@{
        Name = $Name
        Type = $Type
        Value = $Value
    }
}

$ChromiumCommonPolicies = @(
    (New-Policy 'BookmarkBarEnabled' 'DWord' 1),
    (New-Policy 'ShowHomeButton' 'DWord' 1),
    (New-Policy 'HomepageIsNewTabPage' 'DWord' 0),
    (New-Policy 'HomepageLocation' 'String' 'about:blank'),
    (New-Policy 'NewTabPageLocation' 'String' 'about:blank'),
    (New-Policy 'RestoreOnStartup' 'DWord' 4),
    (New-Policy 'DefaultBrowserSettingEnabled' 'DWord' 0),
    (New-Policy 'BackgroundModeEnabled' 'DWord' 0),
    (New-Policy 'HardwareAccelerationModeEnabled' 'DWord' 1),
    (New-Policy 'MetricsReportingEnabled' 'DWord' 0),
    (New-Policy 'UserFeedbackAllowed' 'DWord' 0),
    (New-Policy 'UrlKeyedAnonymizedDataCollectionEnabled' 'DWord' 0),
    (New-Policy 'AlternateErrorPagesEnabled' 'DWord' 0),
    (New-Policy 'SearchSuggestEnabled' 'DWord' 0),
    (New-Policy 'PromotionalTabsEnabled' 'DWord' 0),
    (New-Policy 'PrivacySandboxAdMeasurementEnabled' 'DWord' 0),
    (New-Policy 'PrivacySandboxAdTopicsEnabled' 'DWord' 0),
    (New-Policy 'PrivacySandboxSiteEnabledAdsEnabled' 'DWord' 0),
    (New-Policy 'PrivacySandboxPromptEnabled' 'DWord' 0),
    (New-Policy 'QuicAllowed' 'DWord' 0),
    (New-Policy 'DnsOverHttpsMode' 'String' 'off'),
    (New-Policy 'WebRtcIPHandling' 'String' 'disable_non_proxied_udp'),
    (New-Policy 'DefaultGeolocationSetting' 'DWord' 2),
    (New-Policy 'DefaultNotificationsSetting' 'DWord' 2),
    (New-Policy 'PaymentMethodQueryEnabled' 'DWord' 0),
    (New-Policy 'SafeBrowsingProtectionLevel' 'DWord' 1),
    (New-Policy 'DefaultCookiesSetting' 'DWord' 1),
    (New-Policy 'BlockThirdPartyCookies' 'DWord' 1),
    (New-Policy 'PasswordManagerEnabled' 'DWord' 1),
    (New-Policy 'AutofillAddressEnabled' 'DWord' 1),
    (New-Policy 'AutofillCreditCardEnabled' 'DWord' 1),
    (New-Policy 'BrowserSignin' 'DWord' 1),
    (New-Policy 'SigninAllowed' 'DWord' 1)
)

$EdgePolicies = @(
    (New-Policy 'FavoritesBarEnabled' 'DWord' 1),
    (New-Policy 'StartupBoostEnabled' 'DWord' 0),
    (New-Policy 'HideFirstRunExperience' 'DWord' 1),
    (New-Policy 'ShowRecommendationsEnabled' 'DWord' 0),
    (New-Policy 'DefaultBrowserSettingsCampaignEnabled' 'DWord' 0),
    (New-Policy 'PersonalizationReportingEnabled' 'DWord' 0),
    (New-Policy 'NewTabPageContentEnabled' 'DWord' 0),
    (New-Policy 'NewTabPageQuickLinksEnabled' 'DWord' 0),
    (New-Policy 'HubsSidebarEnabled' 'DWord' 0),
    (New-Policy 'EdgeShoppingAssistantEnabled' 'DWord' 0),
    (New-Policy 'EdgeWalletCheckoutEnabled' 'DWord' 0),
    (New-Policy 'ShowMicrosoftRewards' 'DWord' 0),
    (New-Policy 'EdgeCollectionsEnabled' 'DWord' 0),
    (New-Policy 'EdgeWorkspacesEnabled' 'DWord' 0),
    (New-Policy 'MicrosoftEdgeInsiderPromotionEnabled' 'DWord' 0),
    (New-Policy 'VisualSearchEnabled' 'DWord' 0),
    (New-Policy 'ConfigureDoNotTrack' 'DWord' 1),
    (New-Policy 'TrackingPrevention' 'DWord' 2),
    (New-Policy 'SmartScreenEnabled' 'DWord' 1),
    (New-Policy 'WebRtcLocalhostIpHandling' 'String' 'DisableNonProxiedUdp')
)

$BravePolicies = @(
    (New-Policy 'BraveNewsDisabled' 'DWord' 1),
    (New-Policy 'BraveRewardsDisabled' 'DWord' 1),
    (New-Policy 'BraveWalletDisabled' 'DWord' 1),
    (New-Policy 'BraveVPNDisabled' 'DWord' 1),
    (New-Policy 'BraveTalkDisabled' 'DWord' 1),
    (New-Policy 'BraveAIChatEnabled' 'DWord' 0),
    (New-Policy 'BraveP3AEnabled' 'DWord' 0),
    (New-Policy 'BraveStatsPingEnabled' 'DWord' 0),
    (New-Policy 'BraveWebDiscoveryEnabled' 'DWord' 0),
    (New-Policy 'TorDisabled' 'DWord' 1),
    (New-Policy 'IPFSEnabled' 'DWord' 0)
)

$ChromiumBrowsers = @(
    [pscustomobject]@{
        Name = 'Chrome'
        PolicySubPath = 'SOFTWARE\Policies\Google\Chrome'
        UserDataRoot = Join-Path $env:LOCALAPPDATA 'Google\Chrome\User Data'
        ProcessNames = @('chrome')
        ExecutableNames = @('chrome.exe')
        CandidatePaths = @(
            (Join-Path $env:ProgramFiles 'Google\Chrome\Application\chrome.exe'),
            (Join-Path ${env:ProgramFiles(x86)} 'Google\Chrome\Application\chrome.exe')
        )
        Policies = $ChromiumCommonPolicies
        UsesEdgeStore = $false
    },
    [pscustomobject]@{
        Name = 'Chromium'
        PolicySubPath = 'SOFTWARE\Policies\Chromium'
        UserDataRoot = Join-Path $env:LOCALAPPDATA 'Chromium\User Data'
        ProcessNames = @('chrome')
        ExecutableNames = @('chrome.exe')
        CandidatePaths = @(
            (Join-Path $env:LOCALAPPDATA 'Chromium\Application\chrome.exe'),
            (Join-Path $env:ProgramFiles 'Chromium\Application\chrome.exe'),
            (Join-Path ${env:ProgramFiles(x86)} 'Chromium\Application\chrome.exe')
        )
        Policies = $ChromiumCommonPolicies
        UsesEdgeStore = $false
    },
    [pscustomobject]@{
        Name = 'Edge'
        PolicySubPath = 'SOFTWARE\Policies\Microsoft\Edge'
        UserDataRoot = Join-Path $env:LOCALAPPDATA 'Microsoft\Edge\User Data'
        ProcessNames = @('msedge')
        ExecutableNames = @('msedge.exe')
        CandidatePaths = @(
            (Join-Path ${env:ProgramFiles(x86)} 'Microsoft\Edge\Application\msedge.exe'),
            (Join-Path $env:ProgramFiles 'Microsoft\Edge\Application\msedge.exe')
        )
        Policies = Merge-PolicyLists $ChromiumCommonPolicies, $EdgePolicies
        UsesEdgeStore = $true
    },
    [pscustomobject]@{
        Name = 'Brave'
        PolicySubPath = 'SOFTWARE\Policies\BraveSoftware\Brave'
        UserDataRoot = Join-Path $env:LOCALAPPDATA 'BraveSoftware\Brave-Browser\User Data'
        ProcessNames = @('brave')
        ExecutableNames = @('brave.exe')
        CandidatePaths = @(
            (Join-Path $env:ProgramFiles 'BraveSoftware\Brave-Browser\Application\brave.exe'),
            (Join-Path ${env:ProgramFiles(x86)} 'BraveSoftware\Brave-Browser\Application\brave.exe'),
            (Join-Path $env:LOCALAPPDATA 'BraveSoftware\Brave-Browser\Application\brave.exe')
        )
        Policies = Merge-PolicyLists $ChromiumCommonPolicies, $BravePolicies
        UsesEdgeStore = $false
    },
    [pscustomobject]@{
        Name = 'Vivaldi'
        PolicySubPath = 'SOFTWARE\Policies\Vivaldi'
        UserDataRoot = Join-Path $env:LOCALAPPDATA 'Vivaldi\User Data'
        ProcessNames = @('vivaldi')
        ExecutableNames = @('vivaldi.exe')
        CandidatePaths = @(
            (Join-Path $env:LOCALAPPDATA 'Vivaldi\Application\vivaldi.exe'),
            (Join-Path $env:ProgramFiles 'Vivaldi\Application\vivaldi.exe'),
            (Join-Path ${env:ProgramFiles(x86)} 'Vivaldi\Application\vivaldi.exe')
        )
        Policies = $ChromiumCommonPolicies
        UsesEdgeStore = $false
    }
)

$Opera = [pscustomobject]@{
    Name = 'Opera'
    UserDataRoot = Join-Path $env:APPDATA 'Opera Software\Opera Stable'
    ProcessNames = @('opera')
    ExecutableNames = @('opera.exe')
    CandidatePaths = @(
        (Join-Path $env:LOCALAPPDATA 'Programs\Opera\opera.exe'),
        (Join-Path $env:ProgramFiles 'Opera\opera.exe'),
        (Join-Path ${env:ProgramFiles(x86)} 'Opera\opera.exe')
    )
}

$FirefoxBrowsers = @(
    [pscustomobject]@{
        Name = 'Firefox'
        InstallRoot = Join-Path $env:ProgramFiles 'Mozilla Firefox'
        ProfileRoot = Join-Path $env:APPDATA 'Mozilla\Firefox\Profiles'
        ProcessNames = @('firefox')
        ExecutableNames = @('firefox.exe')
        CandidatePaths = @(
            (Join-Path $env:ProgramFiles 'Mozilla Firefox\firefox.exe'),
            (Join-Path ${env:ProgramFiles(x86)} 'Mozilla Firefox\firefox.exe')
        )
        Locale = 'zh-CN'
    },
    [pscustomobject]@{
        Name = 'LibreWolf'
        InstallRoot = Join-Path $env:ProgramFiles 'LibreWolf'
        ProfileRoot = Join-Path $env:APPDATA 'LibreWolf\Profiles'
        ProcessNames = @('librewolf')
        ExecutableNames = @('librewolf.exe')
        CandidatePaths = @(
            (Join-Path $env:ProgramFiles 'LibreWolf\librewolf.exe'),
            (Join-Path ${env:ProgramFiles(x86)} 'LibreWolf\librewolf.exe')
        )
        Locale = 'zh-CN'
    },
    [pscustomobject]@{
        Name = 'Zen'
        InstallRoot = Join-Path $env:ProgramFiles 'Zen Browser'
        ProfileRoot = Join-Path $env:APPDATA 'zen\Profiles'
        ProcessNames = @('zen')
        ExecutableNames = @('zen.exe')
        CandidatePaths = @(
            (Join-Path $env:ProgramFiles 'Zen Browser\zen.exe'),
            (Join-Path $env:ProgramFiles 'Zen\zen.exe'),
            (Join-Path $env:ProgramFiles 'Zen-Browser\zen.exe'),
            (Join-Path $env:LOCALAPPDATA 'Zen\zen.exe'),
            (Join-Path $env:LOCALAPPDATA 'Zen-Browser\zen.exe'),
            (Join-Path $env:LOCALAPPDATA 'Zen Browser\zen.exe')
        )
        Locale = 'zh-CN'
    }
)

function Get-ObjectPropertyNames {
    param([object]$Object)
    if ($null -eq $Object) {
        return @()
    }
    return @($Object.PSObject.Properties | ForEach-Object { $_.Name })
}

function Get-FirstExistingPath {
    param([string[]]$Paths)
    foreach ($path in @($Paths)) {
        if (-not [string]::IsNullOrWhiteSpace($path) -and (Test-Path -LiteralPath $path)) {
            return (Resolve-Path -LiteralPath $path).Path
        }
    }
    return $null
}

function Get-AppPathExecutable {
    param([object]$Browser)

    if ($Browser.Name -eq 'Chromium') {
        return $null
    }

    foreach ($exe in @($Browser.ExecutableNames)) {
        $regPaths = @(
            "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\$exe",
            "Registry::HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\$exe"
        )
        foreach ($regPath in $regPaths) {
            try {
                $item = Get-ItemProperty -Path $regPath -ErrorAction SilentlyContinue
                $value = if ($null -ne $item) { $item.'(Default)' } else { $null }
                if (-not [string]::IsNullOrWhiteSpace($value) -and (Test-Path -LiteralPath $value)) {
                    return (Resolve-Path -LiteralPath $value).Path
                }
            }
            catch {
                continue
            }
        }
    }
    return $null
}

function Get-CommandExecutable {
    param([object]$Browser)

    if ($Browser.Name -eq 'Chromium') {
        return $null
    }

    foreach ($exe in @($Browser.ExecutableNames)) {
        $commandName = [IO.Path]::GetFileNameWithoutExtension($exe)
        $command = Get-Command $commandName -ErrorAction SilentlyContinue
        if ($command -and $command.Source -and (Test-Path -LiteralPath $command.Source)) {
            return (Resolve-Path -LiteralPath $command.Source).Path
        }
    }
    return $null
}

function Resolve-BrowserExecutable {
    param([object]$Browser)

    $candidate = Get-FirstExistingPath -Paths $Browser.CandidatePaths
    if ($candidate) {
        return $candidate
    }

    $appPath = Get-AppPathExecutable -Browser $Browser
    if ($appPath) {
        return $appPath
    }

    return Get-CommandExecutable -Browser $Browser
}

function Get-ExecutableVersion {
    param([string]$Path)

    if ([string]::IsNullOrWhiteSpace($Path) -or -not (Test-Path -LiteralPath $Path)) {
        return $null
    }

    try {
        return [Diagnostics.FileVersionInfo]::GetVersionInfo($Path).ProductVersion
    }
    catch {
        return $null
    }
}

function Set-BrowserRuntimeInfo {
    param([object[]]$Browsers)

    foreach ($browser in @($Browsers)) {
        $exePath = Resolve-BrowserExecutable -Browser $browser
        $installed = -not [string]::IsNullOrWhiteSpace($exePath)
        $version = if ($installed) { Get-ExecutableVersion -Path $exePath } else { $null }

        $browser | Add-Member -MemberType NoteProperty -Name ExePath -Value $exePath -Force
        $browser | Add-Member -MemberType NoteProperty -Name Installed -Value $installed -Force
        $browser | Add-Member -MemberType NoteProperty -Name Version -Value $version -Force

        if ($installed -and ((Get-ObjectPropertyNames -Object $browser) -contains 'InstallRoot')) {
            $browser.InstallRoot = Split-Path $exePath -Parent
        }
    }
}

function Initialize-BrowserDetection {
    $all = @($ChromiumBrowsers) + @($Opera) + @($FirefoxBrowsers)
    Set-BrowserRuntimeInfo -Browsers $all

    Write-Info "Detected browser installations:"
    foreach ($browser in $all) {
        if ($browser.Installed) {
            $versionText = if ([string]::IsNullOrWhiteSpace($browser.Version)) { 'version unknown' } else { $browser.Version }
            Write-Info "  $($browser.Name): $versionText - $($browser.ExePath)"
        }
        else {
            Write-Info "  $($browser.Name): not detected"
        }
    }
}

function Get-EnabledExtensionConfig {
    param([string]$Path)

    $result = [ordered]@{
        chromium_web_store = @()
        edge_addons = @()
        firefox_addons = @()
    }

    if (-not (Test-Path -LiteralPath $Path)) {
        Write-Warn "Extension config not found at $Path. Extension policy writes skipped."
        return $result
    }

    $config = ConvertFrom-BrowserJsonText -Raw (Get-Content -LiteralPath $Path -Raw -Encoding UTF8)
    foreach ($section in @($result.Keys)) {
        if ($config.PSObject.Properties.Name -contains $section) {
            $result[$section] = @($config.$section | Where-Object { $_.enabled -eq $true })
        }
    }
    return $result
}

$ExtensionConfig = Get-EnabledExtensionConfig -Path $ExtensionConfigPath

function Get-ChromiumForceList {
    param([string]$BrowserName, [bool]$UsesEdgeStore)

    $items = New-Object System.Collections.Generic.List[string]
    $source = if ($UsesEdgeStore) { $ExtensionConfig.edge_addons } else { $ExtensionConfig.chromium_web_store }
    foreach ($ext in $source) {
        if ($ext.browsers -contains $BrowserName) {
            $id = [string]$ext.id
            $url = if ($UsesEdgeStore) { [string]$ext.update_url } else { [string]$ext.update_url }
            if ($id -match '^[a-p]{32}$' -and $url -match '^https://') {
                $items.Add("$id;$url") | Out-Null
            }
            else {
                Write-Warn "Skipping invalid extension entry '$($ext.name)' for $BrowserName."
            }
        }
    }
    return $items.ToArray()
}

function Set-ChromiumPolicies {
    param([object]$Browser)

    $hives = @('HKEY_CURRENT_USER')
    if ($ApplyMachinePolicies) {
        $hives += 'HKEY_LOCAL_MACHINE'
    }

    foreach ($hive in $hives) {
        foreach ($policy in $Browser.Policies) {
            Set-RegistryPolicyValue -Hive $hive -SubPath $Browser.PolicySubPath -Name $policy.Name -Type $policy.Type -Value $policy.Value
        }

        $forceList = @(Get-ChromiumForceList -BrowserName $Browser.Name -UsesEdgeStore $Browser.UsesEdgeStore)
        Set-RegistryStringList -Hive $hive -SubPath $Browser.PolicySubPath -ListName 'ExtensionInstallForcelist' -Values $forceList
        Set-RegistryStringList -Hive $hive -SubPath $Browser.PolicySubPath -ListName 'RestoreOnStartupURLs' -Values @('about:blank')
    }
}

function Test-BrowserRunning {
    param([string[]]$ProcessNames)
    foreach ($name in $ProcessNames) {
        if (Get-Process -Name $name -ErrorAction SilentlyContinue) {
            return $true
        }
    }
    return $false
}

function Ensure-JsonObjectProperty {
    param([object]$Object, [string]$Name)

    $propertyNames = @($Object.PSObject.Properties | ForEach-Object { $_.Name })
    if (-not ($propertyNames -contains $Name) -or $null -eq $Object.$Name) {
        $Object | Add-Member -MemberType NoteProperty -Name $Name -Value ([pscustomobject]@{}) -Force
    }
    return $Object.$Name
}

function Set-JsonPathValue {
    param([object]$Object, [string]$Path, [object]$Value)

    $parts = $Path -split '\.'
    $cursor = $Object
    for ($i = 0; $i -lt $parts.Count - 1; $i++) {
        $cursor = Ensure-JsonObjectProperty -Object $cursor -Name $parts[$i]
    }
    $leaf = $parts[-1]
    $cursor | Add-Member -MemberType NoteProperty -Name $leaf -Value $Value -Force
}

function Set-Utf8NoBomFile {
    param([string]$Path, [object]$Value)

    if ($Value -is [array]) {
        $text = ($Value -join [Environment]::NewLine) + [Environment]::NewLine
    }
    else {
        $text = [string]$Value
    }

    $encoding = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($Path, $text, $encoding)
}

function Save-JsonFile {
    param([string]$Path, [object]$Object)

    $json = $Object | ConvertTo-Json -Depth 100
    if (-not $DryRun) {
        Set-Utf8NoBomFile -Path $Path -Value $json
    }
}

function Read-JsonObjectFile {
    param([string]$Path)

    if (-not (Test-Path -LiteralPath $Path)) {
        return [pscustomobject]@{}
    }

    try {
        $raw = Get-Content -LiteralPath $Path -Raw -Encoding UTF8
        if ([string]::IsNullOrWhiteSpace($raw)) {
            return [pscustomobject]@{}
        }
        $parsed = ConvertFrom-BrowserJsonText -Raw $raw
        if ($null -eq $parsed) {
            return [pscustomobject]@{}
        }
        return $parsed
    }
    catch {
        $reason = ($_.Exception.Message -split "(`r`n|`n|`r)")[0]
        if ($reason.Length -gt 180) {
            $reason = $reason.Substring(0, 180) + '...'
        }
        Write-Warn "Cannot parse JSON file $Path. Edits are skipped to avoid overwriting existing browser state. $reason"
        return $null
    }
}

function Get-ChromiumPreferenceFiles {
    param([string]$UserDataRoot)

    if (-not (Test-Path -LiteralPath $UserDataRoot)) {
        return @()
    }

    return @(Get-ChildItem -LiteralPath $UserDataRoot -Directory -ErrorAction SilentlyContinue |
        Where-Object {
            Test-Path -LiteralPath (Join-Path $_.FullName 'Preferences')
        } |
        ForEach-Object {
            Join-Path $_.FullName 'Preferences'
        })
}

function Initialize-PreferenceFile {
    param([string]$UserDataRoot, [string]$BrowserName)

    $defaultProfile = Join-Path $UserDataRoot 'Default'
    $prefsPath = Join-Path $defaultProfile 'Preferences'
    $localState = Join-Path $UserDataRoot 'Local State'

    if ($DryRun) {
        if (-not (Test-Path -LiteralPath $prefsPath)) {
            Write-Change "Would create $prefsPath"
        }
        if (-not (Test-Path -LiteralPath $localState)) {
            Write-Change "Would create $localState"
        }
        return
    }

    New-Item -ItemType Directory -Path $defaultProfile -Force | Out-Null
    if (-not (Test-Path -LiteralPath $prefsPath)) {
        Set-Utf8NoBomFile -Path $prefsPath -Value ([pscustomobject]@{} | ConvertTo-Json -Depth 10)
        Write-Change "Created $prefsPath"
    }
    if (-not (Test-Path -LiteralPath $localState)) {
        Set-Utf8NoBomFile -Path $localState -Value ([pscustomobject]@{} | ConvertTo-Json -Depth 10)
        Write-Change "Created $localState"
    }
}

function Set-ChromiumProfilePreferences {
    param([object]$Browser)

    if (-not $ApplyProfilePreferences) {
        return
    }

    $propertyNames = Get-ObjectPropertyNames -Object $Browser
    $isInstalled = ($propertyNames -contains 'Installed') -and $Browser.Installed
    if ((-not (Test-Path -LiteralPath $Browser.UserDataRoot)) -and (-not $isInstalled)) {
        Write-Info "$($Browser.Name) user data root not found; profile preference edits skipped."
        return
    }

    Initialize-PreferenceFile -UserDataRoot $Browser.UserDataRoot -BrowserName $Browser.Name

    if (Test-BrowserRunning -ProcessNames $Browser.ProcessNames) {
        Write-Warn "$($Browser.Name) is running. Profile preference edits skipped; close it and run again for profile cleanup."
        return
    }

    $localState = Join-Path $Browser.UserDataRoot 'Local State'
    if (Test-Path -LiteralPath $localState) {
        Backup-File -Path $localState
        $state = Read-JsonObjectFile -Path $localState
        if ($null -ne $state) {
            Set-JsonPathValue -Object $state -Path 'background_mode.enabled' -Value $false
            if ($Browser.Name -eq 'Opera') {
                Set-JsonPathValue -Object $state -Path 'browser.remote_flags' -Value ''
            }
            if ($DryRun) {
                Write-Change "Would update $localState"
            }
            else {
                Save-JsonFile -Path $localState -Object $state
                Write-Change "Updated $localState"
            }
        }
    }

    foreach ($prefsPath in Get-ChromiumPreferenceFiles -UserDataRoot $Browser.UserDataRoot) {
        Backup-File -Path $prefsPath
        $prefs = Read-JsonObjectFile -Path $prefsPath
        if ($null -eq $prefs) {
            continue
        }

        Set-JsonPathValue -Object $prefs -Path 'bookmark_bar.show_on_all_tabs' -Value $true
        Set-JsonPathValue -Object $prefs -Path 'browser.check_default_browser' -Value $false
        Set-JsonPathValue -Object $prefs -Path 'homepage' -Value 'about:blank'
        Set-JsonPathValue -Object $prefs -Path 'homepage_is_newtabpage' -Value $false
        Set-JsonPathValue -Object $prefs -Path 'session.restore_on_startup' -Value 4
        Set-JsonPathValue -Object $prefs -Path 'session.startup_urls' -Value @('about:blank')
        Set-JsonPathValue -Object $prefs -Path 'profile.default_content_setting_values.geolocation' -Value 2
        Set-JsonPathValue -Object $prefs -Path 'profile.default_content_setting_values.notifications' -Value 2
        Set-JsonPathValue -Object $prefs -Path 'privacy_sandbox.apis_enabled' -Value $false
        Set-JsonPathValue -Object $prefs -Path 'privacy_sandbox.m1.topics_enabled' -Value $false
        Set-JsonPathValue -Object $prefs -Path 'privacy_sandbox.m1.fledge_enabled' -Value $false
        Set-JsonPathValue -Object $prefs -Path 'privacy_sandbox.m1.ad_measurement_enabled' -Value $false

        if ($Browser.Name -eq 'Vivaldi') {
            Set-JsonPathValue -Object $prefs -Path 'vivaldi.bookmarks.bar.visible' -Value $true
            Set-JsonPathValue -Object $prefs -Path 'vivaldi.homepage' -Value 'about:blank'
            Set-JsonPathValue -Object $prefs -Path 'vivaldi.startup.check_is_default' -Value $false
            Set-JsonPathValue -Object $prefs -Path 'vivaldi.workspaces.enabled' -Value $false
            Set-JsonPathValue -Object $prefs -Path 'vivaldi.translate.enabled' -Value $true
        }

        if ($Browser.Name -eq 'Opera') {
            Set-JsonPathValue -Object $prefs -Path 'bookmark_bar.auto_visibility' -Value $false
            Set-JsonPathValue -Object $prefs -Path 'consent_flow.consent_given' -Value $true
            Set-JsonPathValue -Object $prefs -Path 'consent_flow.option.data_general_interests' -Value $false
            Set-JsonPathValue -Object $prefs -Path 'consent_flow.option.data_general_location' -Value $false
            Set-JsonPathValue -Object $prefs -Path 'consent_flow.option.usage_personalized_ad' -Value $false
            Set-JsonPathValue -Object $prefs -Path 'consent_flow.option.usage_personalized_content' -Value $false
        }

        if ($DryRun) {
            Write-Change "Would update $prefsPath"
        }
        else {
            Save-JsonFile -Path $prefsPath -Object $prefs
            Write-Change "Updated $prefsPath"
        }
    }
}

function New-FirefoxPolicies {
    param([string]$Locale)

    return [ordered]@{
        policies = [ordered]@{
            DisableTelemetry = $true
            DisableFirefoxStudies = $true
            DisablePocket = $true
            DisableDefaultBrowserAgent = $true
            DontCheckDefaultBrowser = $true
            BackgroundAppUpdate = $false
            DisplayBookmarksToolbar = 'always'
            ShowHomeButton = $true
            NewTabPage = $false
            HardwareAcceleration = $true
            PasswordManagerEnabled = $true
            OfferToSaveLogins = $true
            DisableFormHistory = $false
            RequestedLocales = @($Locale)
            Homepage = [ordered]@{
                URL = 'about:blank'
                StartPage = 'none'
                Locked = $true
            }
            FirefoxHome = [ordered]@{
                Search = $false
                TopSites = $false
                SponsoredTopSites = $false
                Highlights = $false
                Pocket = $false
                SponsoredPocket = $false
                Stories = $false
                SponsoredStories = $false
                Snippets = $false
                Locked = $true
            }
            UserMessaging = [ordered]@{
                ExtensionRecommendations = $false
                FeatureRecommendations = $false
                FirefoxLabs = $false
                MoreFromMozilla = $false
                SkipOnboarding = $true
                UrlbarInterventions = $false
                WhatsNew = $false
            }
            FirefoxSuggest = [ordered]@{
                WebSuggestions = $false
                SponsoredSuggestions = $false
                ImproveSuggest = $false
                Locked = $true
            }
            EnableTrackingProtection = [ordered]@{
                Value = $true
                Fingerprinting = $true
                Cryptomining = $true
                Locked = $true
            }
            Cookies = [ordered]@{
                Behavior = 'reject-tracker-and-partition-foreign'
                BehaviorPrivateBrowsing = 'reject-tracker-and-partition-foreign'
            }
            Preferences = [ordered]@{
                'browser.tabs.loadBookmarksInTabs' = [ordered]@{ Value = $true; Status = 'locked' }
                'browser.tabs.loadBookmarksInBackground' = [ordered]@{ Value = $false; Status = 'locked' }
                'browser.shell.checkDefaultBrowser' = [ordered]@{ Value = $false; Status = 'locked' }
                'browser.newtabpage.enabled' = [ordered]@{ Value = $false; Status = 'locked' }
                'browser.startup.homepage' = [ordered]@{ Value = 'about:blank'; Status = 'locked' }
                'browser.urlbar.suggest.quicksuggest.sponsored' = [ordered]@{ Value = $false; Status = 'locked' }
                'browser.urlbar.suggest.quicksuggest.nonsponsored' = [ordered]@{ Value = $false; Status = 'locked' }
                'browser.urlbar.trending.featureGate' = [ordered]@{ Value = $false; Status = 'locked' }
                'browser.urlbar.weather.featureGate' = [ordered]@{ Value = $false; Status = 'locked' }
                'browser.urlbar.pocket.featureGate' = [ordered]@{ Value = $false; Status = 'locked' }
                'browser.ml.chat.enabled' = [ordered]@{ Value = $false; Status = 'locked' }
                'browser.ml.chat.sidebar' = [ordered]@{ Value = $false; Status = 'locked' }
                'browser.translations.enable' = [ordered]@{ Value = $true; Status = 'default' }
                'media.peerconnection.ice.default_address_only' = [ordered]@{ Value = $true; Status = 'locked' }
                'network.trr.mode' = [ordered]@{ Value = 5; Status = 'locked' }
            }
        }
    }
}

function Add-FirefoxExtensionSettings {
    param([object]$PolicyObject, [string]$BrowserName)

    $enabled = @($ExtensionConfig.firefox_addons | Where-Object { $_.browsers -contains $BrowserName })
    if ($enabled.Count -eq 0) {
        return
    }

    $settings = [ordered]@{}
    foreach ($ext in $enabled) {
        if ([string]::IsNullOrWhiteSpace($ext.id) -or [string]::IsNullOrWhiteSpace($ext.install_url) -or $ext.install_url -notmatch '^https://') {
            Write-Warn "Skipping invalid Firefox-family extension entry '$($ext.name)' for $BrowserName."
            continue
        }
        $settings[[string]$ext.id] = [ordered]@{
            installation_mode = 'force_installed'
            install_url = [string]$ext.install_url
        }
    }

    if ($settings.Count -gt 0) {
        $PolicyObject.policies.ExtensionSettings = $settings
    }
}

function Set-FirefoxPolicies {
    param([object]$Browser)

    if (-not (Test-Path -LiteralPath $Browser.InstallRoot)) {
        Write-Info "$($Browser.Name) install root not found; skipping policies.json."
        return
    }

    $distribution = Join-Path $Browser.InstallRoot 'distribution'
    $policyPath = Join-Path $distribution 'policies.json'
    $policyObject = New-FirefoxPolicies -Locale $Browser.Locale
    Add-FirefoxExtensionSettings -PolicyObject $policyObject -BrowserName $Browser.Name

    $programRoots = @($env:ProgramFiles, ${env:ProgramFiles(x86)}) | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
    $underProgramFiles = @($programRoots | Where-Object { $Browser.InstallRoot.StartsWith($_, [StringComparison]::OrdinalIgnoreCase) }).Count -gt 0
    if ((-not $DryRun) -and $underProgramFiles -and (-not $IsAdmin)) {
        Write-Warn "$($Browser.Name) policies.json is under Program Files. Current shell is not elevated; distribution policy write skipped."
        return
    }

    if (-not $DryRun) {
        New-Item -ItemType Directory -Path $distribution -Force | Out-Null
    }
    Backup-File -Path $policyPath

    if ($DryRun) {
        Write-Change "Would update $policyPath"
    }
    else {
        Set-Utf8NoBomFile -Path $policyPath -Value ($policyObject | ConvertTo-Json -Depth 100)
        Write-Change "Updated $policyPath"
    }
}

function Set-FirefoxUserJs {
    param([object]$Browser)

    if (-not $ApplyProfilePreferences -or -not (Test-Path -LiteralPath $Browser.ProfileRoot)) {
        return
    }

    if (Test-BrowserRunning -ProcessNames $Browser.ProcessNames) {
        Write-Warn "$($Browser.Name) is running. user.js edits skipped; close it and run again for profile cleanup."
        return
    }

    $lines = @(
        '// Managed by Multi Browser Clean Policy Toolkit',
        'user_pref("browser.tabs.loadBookmarksInTabs", true);',
        'user_pref("browser.tabs.loadBookmarksInBackground", false);',
        'user_pref("browser.shell.checkDefaultBrowser", false);',
        'user_pref("browser.startup.homepage", "about:blank");',
        'user_pref("browser.startup.page", 0);',
        'user_pref("browser.newtabpage.enabled", false);',
        'user_pref("browser.newtabpage.activity-stream.showSponsored", false);',
        'user_pref("browser.newtabpage.activity-stream.showSponsoredTopSites", false);',
        'user_pref("browser.newtabpage.activity-stream.feeds.section.topstories", false);',
        'user_pref("browser.urlbar.suggest.quicksuggest.sponsored", false);',
        'user_pref("browser.urlbar.trending.featureGate", false);',
        'user_pref("browser.urlbar.weather.featureGate", false);',
        'user_pref("browser.urlbar.pocket.featureGate", false);',
        'user_pref("privacy.trackingprotection.enabled", true);',
        'user_pref("privacy.trackingprotection.cryptomining.enabled", true);',
        'user_pref("privacy.trackingprotection.fingerprinting.enabled", true);',
        'user_pref("media.peerconnection.ice.default_address_only", true);',
        'user_pref("network.trr.mode", 5);',
        'user_pref("browser.translations.enable", true);'
    )

    foreach ($profile in Get-ChildItem -LiteralPath $Browser.ProfileRoot -Directory -ErrorAction SilentlyContinue) {
        $userJs = Join-Path $profile.FullName 'user.js'
        Backup-File -Path $userJs
        if ($DryRun) {
            Write-Change "Would update $userJs"
        }
        else {
            Set-Utf8NoBomFile -Path $userJs -Value $lines
            Write-Change "Updated $userJs"
        }
    }
}

Write-Info "Running as user: $([Security.Principal.WindowsIdentity]::GetCurrent().Name)"
Write-Info "Elevated: $IsAdmin"
Write-Info "Dry run: $DryRun"
Write-Info "HKLM machine policies: $ApplyMachinePolicies"
Write-Info "Extension config: $ExtensionConfigPath"

Initialize-BrowserDetection

foreach ($browser in $ChromiumBrowsers) {
    if ($OnlyInstalled -and -not $browser.Installed) {
        Write-Info "$($browser.Name) not detected; skipped because -OnlyInstalled was specified."
        continue
    }
    Set-ChromiumPolicies -Browser $browser
    Set-ChromiumProfilePreferences -Browser $browser
}

if (-not $OnlyInstalled -or $Opera.Installed) {
    Set-ChromiumProfilePreferences -Browser $Opera
}
else {
    Write-Info "Opera not detected; skipped because -OnlyInstalled was specified."
}
Write-Warn "Opera registry force-install policy is intentionally skipped because Opera does not document Chrome/Edge-compatible Windows enterprise policy support."

foreach ($browser in $FirefoxBrowsers) {
    if ($OnlyInstalled -and -not $browser.Installed) {
        Write-Info "$($browser.Name) not detected; skipped because -OnlyInstalled was specified."
        continue
    }
    Set-FirefoxPolicies -Browser $browser
    Set-FirefoxUserJs -Browser $browser
}

Write-Warn "Chromium-family browsers do not expose an official policy to make native bookmark-bar clicks open in a new foreground tab. Firefox, LibreWolf, and Zen are configured for this through Mozilla preferences."

Write-Host ''
Write-Host "Summary"
Write-Host "-------"
Write-Host "Changes: $($Script:Changes.Count)"
Write-Host "Warnings: $($Script:Warnings.Count)"
Write-Host "Backup root: $BackupRoot"

if ($Script:Warnings.Count -gt 0) {
    Write-Host ''
    Write-Host "Warnings"
    foreach ($warning in $Script:Warnings) {
        Write-Host "- $warning"
    }
}
