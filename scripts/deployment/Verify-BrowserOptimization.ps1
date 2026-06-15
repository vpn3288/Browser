[CmdletBinding()]
param(
    [switch]$RequireMachinePolicy,
    [switch]$StrictProfilePreferences,
    [switch]$Quiet,
    [switch]$Detailed,
    [switch]$OnlyInstalled,
    [switch]$AllBrowsers
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if ($OnlyInstalled -and $AllBrowsers) {
    throw 'Do not use -OnlyInstalled and -AllBrowsers together. The default already verifies detected browsers only; use -AllBrowsers only for strict full-target verification.'
}

$ProcessInstalledOnly = -not $AllBrowsers

$script:Results = New-Object System.Collections.Generic.List[object]

function Add-Result {
    param(
        [ValidateSet('PASS','WARN','FAIL')]
        [string]$Level,
        [string]$Scope,
        [string]$Name,
        [object]$Expected,
        [object]$Actual,
        [string]$Details = ''
    )

    $script:Results.Add([pscustomobject]@{
        Level = $Level
        Scope = $Scope
        Name = $Name
        Expected = $Expected
        Actual = $Actual
        Details = $Details
    })
}

function Test-IsAdmin {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Convert-ToText {
    param([object]$Value)
    if ($null -eq $Value) {
        return '<missing>'
    }
    if ($Value -is [array]) {
        return ($Value -join ', ')
    }
    return [string]$Value
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

function Get-ResultCategory {
    param([object]$Result)

    $text = "$($Result.Scope) $($Result.Name)"
    switch -Regex ($text) {
        'KnownLimit' { return 'Known limits' }
        'Extension|force-install' { return 'Extensions' }
        'installed executable|policies\.json parse|profile preferences|profile count|profile root|JSON' { return 'Install/profile health' }
        'Bookmark|FavoritesBar|DisplayBookmarksToolbar|ShowHomeButton|loadBookmarks' { return 'Bookmarks/home button' }
        'Homepage|NewTabPage|RestoreOnStartup|startup\.homepage|newtabpage|home\.|session\.restore' { return 'Blank home/start/new-tab' }
        'BackgroundMode|StartupBoost|BackgroundAppUpdate|process count|background' { return 'No background runtime' }
        'Telemetry|Metrics|UserFeedback|UrlKeyed|Personalization|Studies|P3A|StatsPing|WebDiscovery|usage_personalized' { return 'Telemetry off' }
        'Tracking|Fingerprinting|Cryptomining|PrivacySandbox|Cookies|WebRtc|Geolocation|Notifications|Payment|DnsOverHttps|Quic|trr|DoNotTrack' { return 'Privacy controls' }
        'Promotional|Recommendations|FirstRun|DefaultBrowser|Campaign|Content|QuickLinks|Sidebar|Shopping|Wallet|Rewards|Collections|Workspaces|Insider|VisualSearch|News|VPN|Talk|AIChat|Pocket|UserMessaging|FirefoxSuggest|Sponsored|urlbar|weather|trending|ml\.chat|IPFS|TorDisabled|check_default_browser' { return 'Clean vendor UI' }
        'SafeBrowsing|SmartScreen|HardwareAcceleration|Password|Autofill|Signin|OfferToSaveLogins|FormHistory|translations|translate' { return 'Useful features kept' }
        default { return 'Other' }
    }
}

function Format-ResultLine {
    param([object]$Item)

    $line = "  [$($Item.Scope)] $($Item.Name) expected=$(Convert-ToText $Item.Expected) actual=$(Convert-ToText $Item.Actual)"
    if (-not [string]::IsNullOrWhiteSpace($Item.Details)) {
        $line += " :: $($Item.Details)"
    }
    return $line
}

function Write-ResultSummary {
    param(
        [string]$Title,
        [object[]]$Items,
        [scriptblock]$KeySelector
    )

    Write-Host "${Title}:"
    $buckets = @{}
    foreach ($item in $Items) {
        $key = [string](& $KeySelector $item)
        if ([string]::IsNullOrWhiteSpace($key)) {
            $key = '<unknown>'
        }
        if (-not $buckets.ContainsKey($key)) {
            $buckets[$key] = New-Object System.Collections.ArrayList
        }
        [void]$buckets[$key].Add($item)
    }

    if ($buckets.Count -eq 0) {
        Write-Host '  none'
        Write-Host ''
        return
    }

    foreach ($key in @($buckets.Keys | Sort-Object)) {
        $group = @($buckets[$key])
        $pass = @($group | Where-Object { $_.Level -eq 'PASS' }).Count
        $warn = @($group | Where-Object { $_.Level -eq 'WARN' }).Count
        $fail = @($group | Where-Object { $_.Level -eq 'FAIL' }).Count
        $status = if ($fail -gt 0) { 'FAIL' } elseif ($warn -gt 0) { 'WARN' } else { 'PASS' }
        Write-Host ("  {0,-28} {1,5} pass={2,-4} warn={3,-3} fail={4,-3}" -f $key, $status, $pass, $warn, $fail)
    }
    Write-Host ''
}

function Test-Value {
    param(
        [string]$Scope,
        [string]$Name,
        [object]$Actual,
        [object]$Expected,
        [switch]$Warning
    )

    $ok = $false
    if ($null -eq $Expected) {
        $ok = ($null -eq $Actual)
    }
    else {
        $ok = ($Actual -eq $Expected)
    }

    if ($ok) {
        Add-Result -Level PASS -Scope $Scope -Name $Name -Expected $Expected -Actual $Actual
    }
    elseif ($Warning) {
        Add-Result -Level WARN -Scope $Scope -Name $Name -Expected $Expected -Actual $Actual
    }
    else {
        Add-Result -Level FAIL -Scope $Scope -Name $Name -Expected $Expected -Actual $Actual
    }
}

function Get-RegistryValue {
    param([string]$Hive, [string]$SubPath, [string]$Name)

    $path = "Registry::$Hive\$SubPath"
    if (-not (Test-Path -LiteralPath $path)) {
        return $null
    }

    $item = Get-ItemProperty -LiteralPath $path -ErrorAction SilentlyContinue
    if ($null -eq $item) {
        return $null
    }

    if ($item.PSObject.Properties.Name -contains $Name) {
        return $item.$Name
    }
    return $null
}

function Get-RegistryPolicyValueCount {
    param([string]$Hive, [string]$SubPath)

    $path = "Registry::$Hive\$SubPath"
    if (-not (Test-Path -LiteralPath $path)) {
        return 0
    }

    $item = Get-ItemProperty -LiteralPath $path -ErrorAction SilentlyContinue
    if ($null -eq $item) {
        return 0
    }

    return @($item.PSObject.Properties |
        Where-Object { $_.Name -notin @('PSPath','PSParentPath','PSChildName','PSDrive','PSProvider') }).Count
}

function Test-EffectivePolicy {
    param(
        [string]$Browser,
        [string]$PolicySubPath,
        [string]$Name,
        [object]$Expected
    )

    $hklm = Get-RegistryValue -Hive 'HKEY_LOCAL_MACHINE' -SubPath $PolicySubPath -Name $Name
    $hkcu = Get-RegistryValue -Hive 'HKEY_CURRENT_USER' -SubPath $PolicySubPath -Name $Name

    if ($RequireMachinePolicy) {
        Test-Value -Scope $Browser -Name "HKLM policy $Name" -Actual $hklm -Expected $Expected
        return
    }

    if ($hklm -eq $Expected -or $hkcu -eq $Expected) {
        Add-Result -Level PASS -Scope $Browser -Name "effective policy $Name" -Expected $Expected -Actual "HKLM=$(Convert-ToText $hklm); HKCU=$(Convert-ToText $hkcu)"
        return
    }

    Add-Result -Level FAIL -Scope $Browser -Name "effective policy $Name" -Expected $Expected -Actual "HKLM=$(Convert-ToText $hklm); HKCU=$(Convert-ToText $hkcu)"
}

function Read-JsonFile {
    param([string]$Path, [string]$Scope)

    if (-not (Test-Path -LiteralPath $Path)) {
        return $null
    }

    try {
        $raw = Get-Content -LiteralPath $Path -Raw -Encoding UTF8 -ErrorAction Stop
        if ([string]::IsNullOrWhiteSpace($raw)) {
            Add-Result -Level WARN -Scope $Scope -Name 'JSON empty' -Expected 'valid JSON' -Actual $Path
            return $null
        }
        return ConvertFrom-BrowserJsonText -Raw $raw
    }
    catch {
        $reason = ($_.Exception.Message -split "(`r`n|`n|`r)")[0]
        if ($reason.Length -gt 180) {
            $reason = $reason.Substring(0, 180) + '...'
        }
        Add-Result -Level WARN -Scope $Scope -Name 'JSON parse skipped' -Expected 'valid JSON' -Actual $Path -Details $reason
        return $null
    }
}

function Get-NestedValue {
    param([object]$Object, [string[]]$Path)

    $cursor = $Object
    foreach ($part in $Path) {
        if ($null -eq $cursor) {
            return $null
        }

        if ($cursor -is [System.Collections.IDictionary]) {
            if (-not $cursor.Contains($part)) {
                return $null
            }
            $cursor = $cursor[$part]
            continue
        }

        $property = $cursor.PSObject.Properties[$part]
        if ($null -eq $property) {
            return $null
        }
        $cursor = $property.Value
    }
    return $cursor
}

function Find-FirstExistingPath {
    param([string[]]$Paths)
    foreach ($path in $Paths) {
        if ([string]::IsNullOrWhiteSpace($path)) {
            continue
        }
        if (Test-Path -LiteralPath $path) {
            return (Resolve-Path -LiteralPath $path).Path
        }
    }
    return $null
}

function Get-AppPathExecutable {
    param(
        [string[]]$ExecutableNames,
        [switch]$SkipAppPaths
    )

    if ($SkipAppPaths) {
        return $null
    }

    foreach ($exe in @($ExecutableNames)) {
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
    param(
        [string[]]$ExecutableNames,
        [switch]$SkipCommandLookup
    )

    if ($SkipCommandLookup) {
        return $null
    }

    foreach ($exe in @($ExecutableNames)) {
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

    $candidate = Find-FirstExistingPath -Paths $Browser.Candidates
    if ($candidate) {
        return $candidate
    }

    $skipAppPaths = $false
    $skipAppPathProperty = $Browser.PSObject.Properties['SkipAppPaths']
    if ($null -ne $skipAppPathProperty) {
        $skipAppPaths = [bool]$skipAppPathProperty.Value
    }

    $appPath = Get-AppPathExecutable -ExecutableNames $Browser.ExecutableNames -SkipAppPaths:$skipAppPaths
    if ($appPath) {
        return $appPath
    }

    $skipCommandLookup = $false
    $skipCommandLookupProperty = $Browser.PSObject.Properties['SkipCommandLookup']
    if ($null -ne $skipCommandLookupProperty) {
        $skipCommandLookup = [bool]$skipCommandLookupProperty.Value
    }

    return Get-CommandExecutable -ExecutableNames $Browser.ExecutableNames -SkipCommandLookup:$skipCommandLookup
}

function Get-ChromiumPreferenceFiles {
    param([string]$UserDataRoot)

    if (-not (Test-Path -LiteralPath $UserDataRoot)) {
        return @()
    }

    return @(Get-ChildItem -LiteralPath $UserDataRoot -Directory -ErrorAction SilentlyContinue |
        Where-Object {
            $_.Name -eq 'Default' -or
            $_.Name -like 'Profile *' -or
            $_.Name -like 'Person *' -or
            $_.Name -like 'Default Profile*'
        } |
        ForEach-Object { Join-Path $_.FullName 'Preferences' } |
        Where-Object { Test-Path -LiteralPath $_ })
}

function Test-ProfilePreferenceFile {
    param(
        [string]$Browser,
        [string]$Path,
        [array]$Checks,
        [switch]$Required
    )

    $json = Read-JsonFile -Path $Path -Scope $Browser
    if ($null -eq $json) {
        if ($Required) {
            Add-Result -Level FAIL -Scope $Browser -Name 'profile preferences readable' -Expected 'valid Preferences JSON' -Actual $Path
        }
        return
    }

    foreach ($check in $Checks) {
        $actual = Get-NestedValue -Object $json -Path $check.Path
        $warning = [bool]$check.Warning
        if ($StrictProfilePreferences -or $Required) {
            $warning = $false
        }
        Test-Value -Scope $Browser -Name "profile $($check.Name)" -Actual $actual -Expected $check.Expected -Warning:($warning)
    }
}

function Test-NoRuntimeProcess {
    param([string]$ProcessName)

    $count = @(Get-Process -Name $ProcessName -ErrorAction SilentlyContinue).Count
    Test-Value -Scope 'Runtime' -Name "$ProcessName process count" -Actual $count -Expected 0
}

$repoRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..\..')).Path
$programFilesX86 = ${env:ProgramFiles(x86)}

$chromiumBrowsers = @(
    [pscustomobject]@{
        Name = 'Chrome'
        Policy = 'SOFTWARE\Policies\Google\Chrome'
        UserDataRoot = Join-Path $env:LOCALAPPDATA 'Google\Chrome\User Data'
        Candidates = @((Join-Path $env:ProgramFiles 'Google\Chrome\Application\chrome.exe'), (Join-Path $programFilesX86 'Google\Chrome\Application\chrome.exe'), (Join-Path $env:LOCALAPPDATA 'Google\Chrome\Application\chrome.exe'))
        ExecutableNames = @('chrome.exe')
        Processes = @('chrome')
    },
    [pscustomobject]@{
        Name = 'Chromium'
        Policy = 'SOFTWARE\Policies\Chromium'
        UserDataRoot = Join-Path $env:LOCALAPPDATA 'Chromium\User Data'
        Candidates = @(
            (Join-Path $env:LOCALAPPDATA 'Chromium\Application\chrome.exe'),
            (Join-Path $env:LOCALAPPDATA 'Chromium\chrome-win\chrome.exe'),
            (Join-Path $env:ProgramFiles 'Chromium\Application\chrome.exe'),
            (Join-Path $programFilesX86 'Chromium\Application\chrome.exe'),
            (Join-Path $env:USERPROFILE 'Desktop\chrome-win\chrome.exe'),
            (Join-Path $env:USERPROFILE 'Downloads\chrome-win\chrome.exe'),
            (Join-Path $env:USERPROFILE 'Documents\chrome-win\chrome.exe'),
            (Join-Path $env:USERPROFILE 'Documents\Chromium\chrome-win\chrome.exe'),
            (Join-Path $env:USERPROFILE 'Downloads\Chromium\chrome-win\chrome.exe')
        )
        ExecutableNames = @('chrome.exe')
        SkipAppPaths = $true
        SkipCommandLookup = $true
        Processes = @('chrome')
    },
    [pscustomobject]@{
        Name = 'Edge'
        Policy = 'SOFTWARE\Policies\Microsoft\Edge'
        UserDataRoot = Join-Path $env:LOCALAPPDATA 'Microsoft\Edge\User Data'
        Candidates = @((Join-Path $programFilesX86 'Microsoft\Edge\Application\msedge.exe'), (Join-Path $env:ProgramFiles 'Microsoft\Edge\Application\msedge.exe'), (Join-Path $env:LOCALAPPDATA 'Microsoft\Edge\Application\msedge.exe'))
        ExecutableNames = @('msedge.exe')
        Processes = @('msedge')
    },
    [pscustomobject]@{
        Name = 'Brave'
        Policy = 'SOFTWARE\Policies\BraveSoftware\Brave'
        UserDataRoot = Join-Path $env:LOCALAPPDATA 'BraveSoftware\Brave-Browser\User Data'
        Candidates = @((Join-Path $env:ProgramFiles 'BraveSoftware\Brave-Browser\Application\brave.exe'), (Join-Path $programFilesX86 'BraveSoftware\Brave-Browser\Application\brave.exe'), (Join-Path $env:LOCALAPPDATA 'BraveSoftware\Brave-Browser\Application\brave.exe'))
        ExecutableNames = @('brave.exe')
        Processes = @('brave')
    },
    [pscustomobject]@{
        Name = 'Vivaldi'
        Policy = 'SOFTWARE\Policies\Vivaldi'
        UserDataRoot = Join-Path $env:LOCALAPPDATA 'Vivaldi\User Data'
        Candidates = @((Join-Path $env:LOCALAPPDATA 'Vivaldi\Application\vivaldi.exe'), (Join-Path $env:ProgramFiles 'Vivaldi\Application\vivaldi.exe'), (Join-Path $programFilesX86 'Vivaldi\Application\vivaldi.exe'))
        ExecutableNames = @('vivaldi.exe')
        Processes = @('vivaldi')
    }
)

$opera = [pscustomobject]@{
    Name = 'Opera'
    UserDataRoot = Join-Path $env:APPDATA 'Opera Software\Opera Stable'
    Candidates = @((Join-Path $env:LOCALAPPDATA 'Programs\Opera\opera.exe'), (Join-Path $env:ProgramFiles 'Opera\opera.exe'), (Join-Path $programFilesX86 'Opera\opera.exe'))
    ExecutableNames = @('opera.exe')
    Processes = @('opera')
}

$firefoxBrowsers = @(
    [pscustomobject]@{
        Name = 'Firefox'
        InstallRoot = Join-Path $env:ProgramFiles 'Mozilla Firefox'
        Candidates = @((Join-Path $env:ProgramFiles 'Mozilla Firefox\firefox.exe'), (Join-Path $programFilesX86 'Mozilla Firefox\firefox.exe'))
        ExecutableNames = @('firefox.exe')
        Profiles = Join-Path $env:APPDATA 'Mozilla\Firefox\Profiles'
        Processes = @('firefox')
    },
    [pscustomobject]@{
        Name = 'LibreWolf'
        InstallRoot = Join-Path $env:ProgramFiles 'LibreWolf'
        Candidates = @((Join-Path $env:ProgramFiles 'LibreWolf\librewolf.exe'), (Join-Path $programFilesX86 'LibreWolf\librewolf.exe'))
        ExecutableNames = @('librewolf.exe')
        Profiles = Join-Path $env:APPDATA 'LibreWolf\Profiles'
        Processes = @('librewolf')
    },
    [pscustomobject]@{
        Name = 'Zen'
        InstallRoot = Join-Path $env:ProgramFiles 'Zen Browser'
        Candidates = @(
            (Join-Path $env:ProgramFiles 'Zen Browser\zen.exe'),
            (Join-Path $programFilesX86 'Zen Browser\zen.exe'),
            (Join-Path $env:ProgramFiles 'Zen\zen.exe'),
            (Join-Path $env:ProgramFiles 'Zen-Browser\zen.exe'),
            (Join-Path $env:LOCALAPPDATA 'Zen\zen.exe'),
            (Join-Path $env:LOCALAPPDATA 'Zen-Browser\zen.exe'),
            (Join-Path $env:LOCALAPPDATA 'Zen Browser\zen.exe')
        )
        ExecutableNames = @('zen.exe')
        Profiles = Join-Path $env:APPDATA 'zen\Profiles'
        Processes = @('zen')
    }
)

$commonChromiumPolicies = @(
    @{ Name='BookmarkBarEnabled'; Expected=1 },
    @{ Name='ShowHomeButton'; Expected=1 },
    @{ Name='HomepageIsNewTabPage'; Expected=0 },
    @{ Name='HomepageLocation'; Expected='about:blank' },
    @{ Name='NewTabPageLocation'; Expected='about:blank' },
    @{ Name='RestoreOnStartup'; Expected=4 },
    @{ Name='DefaultBrowserSettingEnabled'; Expected=0 },
    @{ Name='BackgroundModeEnabled'; Expected=0 },
    @{ Name='PromotionalTabsEnabled'; Expected=0 },
    @{ Name='PrivacySandboxAdMeasurementEnabled'; Expected=0 },
    @{ Name='PrivacySandboxAdTopicsEnabled'; Expected=0 },
    @{ Name='PrivacySandboxSiteEnabledAdsEnabled'; Expected=0 },
    @{ Name='PrivacySandboxPromptEnabled'; Expected=0 },
    @{ Name='QuicAllowed'; Expected=0 },
    @{ Name='DnsOverHttpsMode'; Expected='off' },
    @{ Name='WebRtcIPHandling'; Expected='disable_non_proxied_udp' },
    @{ Name='DefaultGeolocationSetting'; Expected=2 },
    @{ Name='DefaultNotificationsSetting'; Expected=2 },
    @{ Name='PaymentMethodQueryEnabled'; Expected=0 },
    @{ Name='SafeBrowsingProtectionLevel'; Expected=1 },
    @{ Name='DefaultCookiesSetting'; Expected=1 },
    @{ Name='BlockThirdPartyCookies'; Expected=1 },
    @{ Name='PasswordManagerEnabled'; Expected=1 },
    @{ Name='AutofillAddressEnabled'; Expected=1 },
    @{ Name='AutofillCreditCardEnabled'; Expected=1 },
    @{ Name='BrowserSignin'; Expected=1 },
    @{ Name='SigninAllowed'; Expected=1 }
)

$edgePolicies = @(
    @{ Name='FavoritesBarEnabled'; Expected=1 },
    @{ Name='StartupBoostEnabled'; Expected=0 },
    @{ Name='HideFirstRunExperience'; Expected=1 },
    @{ Name='ShowRecommendationsEnabled'; Expected=0 },
    @{ Name='DefaultBrowserSettingsCampaignEnabled'; Expected=0 },
    @{ Name='PersonalizationReportingEnabled'; Expected=0 },
    @{ Name='NewTabPageContentEnabled'; Expected=0 },
    @{ Name='NewTabPageQuickLinksEnabled'; Expected=0 },
    @{ Name='HubsSidebarEnabled'; Expected=0 },
    @{ Name='EdgeShoppingAssistantEnabled'; Expected=0 },
    @{ Name='EdgeWalletCheckoutEnabled'; Expected=0 },
    @{ Name='ShowMicrosoftRewards'; Expected=0 },
    @{ Name='EdgeCollectionsEnabled'; Expected=0 },
    @{ Name='EdgeWorkspacesEnabled'; Expected=0 },
    @{ Name='MicrosoftEdgeInsiderPromotionEnabled'; Expected=0 },
    @{ Name='VisualSearchEnabled'; Expected=0 },
    @{ Name='ConfigureDoNotTrack'; Expected=1 },
    @{ Name='TrackingPrevention'; Expected=2 },
    @{ Name='SmartScreenEnabled'; Expected=1 },
    @{ Name='WebRtcLocalhostIpHandling'; Expected='DisableNonProxiedUdp' }
)

$bravePolicies = @(
    @{ Name='BraveNewsDisabled'; Expected=1 },
    @{ Name='BraveRewardsDisabled'; Expected=1 },
    @{ Name='BraveWalletDisabled'; Expected=1 },
    @{ Name='BraveVPNDisabled'; Expected=1 },
    @{ Name='BraveTalkDisabled'; Expected=1 },
    @{ Name='BraveAIChatEnabled'; Expected=0 },
    @{ Name='BraveP3AEnabled'; Expected=0 },
    @{ Name='BraveStatsPingEnabled'; Expected=0 },
    @{ Name='BraveWebDiscoveryEnabled'; Expected=0 },
    @{ Name='TorDisabled'; Expected=1 },
    @{ Name='IPFSEnabled'; Expected=0 }
)

$profileChecks = @(
    @{ Name='bookmark_bar.show_on_all_tabs'; Path=@('bookmark_bar','show_on_all_tabs'); Expected=$true; Warning=$true },
    @{ Name='browser.check_default_browser'; Path=@('browser','check_default_browser'); Expected=$false; Warning=$true },
    @{ Name='homepage'; Path=@('homepage'); Expected='about:blank'; Warning=$true },
    @{ Name='homepage_is_newtabpage'; Path=@('homepage_is_newtabpage'); Expected=$false; Warning=$true },
    @{ Name='session.restore_on_startup'; Path=@('session','restore_on_startup'); Expected=4; Warning=$true },
    @{ Name='profile.default_content_setting_values.geolocation'; Path=@('profile','default_content_setting_values','geolocation'); Expected=2; Warning=$true },
    @{ Name='profile.default_content_setting_values.notifications'; Path=@('profile','default_content_setting_values','notifications'); Expected=2; Warning=$true },
    @{ Name='privacy_sandbox.apis_enabled'; Path=@('privacy_sandbox','apis_enabled'); Expected=$false; Warning=$true }
)

$operaProfileChecks = @(
    @{ Name='bookmark_bar.show_on_all_tabs'; Path=@('bookmark_bar','show_on_all_tabs'); Expected=$true; Warning=$false },
    @{ Name='browser.check_default_browser'; Path=@('browser','check_default_browser'); Expected=$false; Warning=$false },
    @{ Name='homepage'; Path=@('homepage'); Expected='about:blank'; Warning=$false },
    @{ Name='homepage_is_newtabpage'; Path=@('homepage_is_newtabpage'); Expected=$false; Warning=$false },
    @{ Name='bookmark_bar.auto_visibility'; Path=@('bookmark_bar','auto_visibility'); Expected=$false; Warning=$false },
    @{ Name='consent_flow.option.usage_personalized_ad'; Path=@('consent_flow','option','usage_personalized_ad'); Expected=$false; Warning=$false },
    @{ Name='consent_flow.option.usage_personalized_content'; Path=@('consent_flow','option','usage_personalized_content'); Expected=$false; Warning=$false }
)

$firefoxPolicyChecks = @(
    @{ Name='DisableTelemetry'; Path=@('policies','DisableTelemetry'); Expected=$true },
    @{ Name='DisableFirefoxStudies'; Path=@('policies','DisableFirefoxStudies'); Expected=$true },
    @{ Name='DisablePocket'; Path=@('policies','DisablePocket'); Expected=$true },
    @{ Name='DisableDefaultBrowserAgent'; Path=@('policies','DisableDefaultBrowserAgent'); Expected=$true },
    @{ Name='DontCheckDefaultBrowser'; Path=@('policies','DontCheckDefaultBrowser'); Expected=$true },
    @{ Name='BackgroundAppUpdate'; Path=@('policies','BackgroundAppUpdate'); Expected=$false },
    @{ Name='DisplayBookmarksToolbar'; Path=@('policies','DisplayBookmarksToolbar'); Expected='always' },
    @{ Name='ShowHomeButton'; Path=@('policies','ShowHomeButton'); Expected=$true },
    @{ Name='NewTabPage'; Path=@('policies','NewTabPage'); Expected=$false },
    @{ Name='HardwareAcceleration'; Path=@('policies','HardwareAcceleration'); Expected=$true },
    @{ Name='PasswordManagerEnabled'; Path=@('policies','PasswordManagerEnabled'); Expected=$true },
    @{ Name='OfferToSaveLogins'; Path=@('policies','OfferToSaveLogins'); Expected=$true },
    @{ Name='DisableFormHistory'; Path=@('policies','DisableFormHistory'); Expected=$false },
    @{ Name='Homepage.URL'; Path=@('policies','Homepage','URL'); Expected='about:blank' },
    @{ Name='Homepage.StartPage'; Path=@('policies','Homepage','StartPage'); Expected='none' },
    @{ Name='Homepage.Locked'; Path=@('policies','Homepage','Locked'); Expected=$true },
    @{ Name='FirefoxHome.Search'; Path=@('policies','FirefoxHome','Search'); Expected=$false },
    @{ Name='FirefoxHome.TopSites'; Path=@('policies','FirefoxHome','TopSites'); Expected=$false },
    @{ Name='FirefoxHome.SponsoredTopSites'; Path=@('policies','FirefoxHome','SponsoredTopSites'); Expected=$false },
    @{ Name='FirefoxHome.Pocket'; Path=@('policies','FirefoxHome','Pocket'); Expected=$false },
    @{ Name='FirefoxHome.SponsoredPocket'; Path=@('policies','FirefoxHome','SponsoredPocket'); Expected=$false },
    @{ Name='FirefoxHome.Locked'; Path=@('policies','FirefoxHome','Locked'); Expected=$true },
    @{ Name='UserMessaging.ExtensionRecommendations'; Path=@('policies','UserMessaging','ExtensionRecommendations'); Expected=$false },
    @{ Name='UserMessaging.FeatureRecommendations'; Path=@('policies','UserMessaging','FeatureRecommendations'); Expected=$false },
    @{ Name='UserMessaging.MoreFromMozilla'; Path=@('policies','UserMessaging','MoreFromMozilla'); Expected=$false },
    @{ Name='UserMessaging.SkipOnboarding'; Path=@('policies','UserMessaging','SkipOnboarding'); Expected=$true },
    @{ Name='FirefoxSuggest.SponsoredSuggestions'; Path=@('policies','FirefoxSuggest','SponsoredSuggestions'); Expected=$false },
    @{ Name='FirefoxSuggest.ImproveSuggest'; Path=@('policies','FirefoxSuggest','ImproveSuggest'); Expected=$false },
    @{ Name='EnableTrackingProtection.Value'; Path=@('policies','EnableTrackingProtection','Value'); Expected=$true },
    @{ Name='EnableTrackingProtection.Fingerprinting'; Path=@('policies','EnableTrackingProtection','Fingerprinting'); Expected=$true },
    @{ Name='EnableTrackingProtection.Cryptomining'; Path=@('policies','EnableTrackingProtection','Cryptomining'); Expected=$true },
    @{ Name='Cookies.Behavior'; Path=@('policies','Cookies','Behavior'); Expected='reject-tracker-and-partition-foreign' },
    @{ Name='Preferences.browser.tabs.loadBookmarksInTabs'; Path=@('policies','Preferences','browser.tabs.loadBookmarksInTabs','Value'); Expected=$true },
    @{ Name='Preferences.browser.tabs.loadBookmarksInBackground'; Path=@('policies','Preferences','browser.tabs.loadBookmarksInBackground','Value'); Expected=$false },
    @{ Name='Preferences.browser.shell.checkDefaultBrowser'; Path=@('policies','Preferences','browser.shell.checkDefaultBrowser','Value'); Expected=$false },
    @{ Name='Preferences.browser.newtabpage.enabled'; Path=@('policies','Preferences','browser.newtabpage.enabled','Value'); Expected=$false },
    @{ Name='Preferences.browser.startup.homepage'; Path=@('policies','Preferences','browser.startup.homepage','Value'); Expected='about:blank' },
    @{ Name='Preferences.browser.urlbar.suggest.quicksuggest.sponsored'; Path=@('policies','Preferences','browser.urlbar.suggest.quicksuggest.sponsored','Value'); Expected=$false },
    @{ Name='Preferences.browser.urlbar.trending.featureGate'; Path=@('policies','Preferences','browser.urlbar.trending.featureGate','Value'); Expected=$false },
    @{ Name='Preferences.browser.urlbar.weather.featureGate'; Path=@('policies','Preferences','browser.urlbar.weather.featureGate','Value'); Expected=$false },
    @{ Name='Preferences.browser.urlbar.pocket.featureGate'; Path=@('policies','Preferences','browser.urlbar.pocket.featureGate','Value'); Expected=$false },
    @{ Name='Preferences.browser.ml.chat.enabled'; Path=@('policies','Preferences','browser.ml.chat.enabled','Value'); Expected=$false },
    @{ Name='Preferences.browser.ml.chat.sidebar'; Path=@('policies','Preferences','browser.ml.chat.sidebar','Value'); Expected=$false },
    @{ Name='Preferences.browser.translations.enable'; Path=@('policies','Preferences','browser.translations.enable','Value'); Expected=$true },
    @{ Name='Preferences.media.peerconnection.ice.default_address_only'; Path=@('policies','Preferences','media.peerconnection.ice.default_address_only','Value'); Expected=$true },
    @{ Name='Preferences.network.trr.mode'; Path=@('policies','Preferences','network.trr.mode','Value'); Expected=5 }
)

$extensionConfigPath = Join-Path $repoRoot 'config\extensions.json'
$extensionConfig = Read-JsonFile -Path $extensionConfigPath -Scope 'Extensions'
if ($null -eq $extensionConfig) {
    Add-Result -Level FAIL -Scope 'Extensions' -Name 'config/extensions.json' -Expected 'readable extension config' -Actual $extensionConfigPath
}
else {
    $enabled = @()
    foreach ($section in @('chromium_web_store','edge_addons','firefox_addons')) {
        $items = Get-NestedValue -Object $extensionConfig -Path @($section)
        if ($items) {
            $enabled += @($items | Where-Object { $_.enabled -eq $true })
        }
    }
    Test-Value -Scope 'Extensions' -Name 'enabled force-install entries' -Actual $enabled.Count -Expected 0
}

foreach ($browser in $chromiumBrowsers) {
    $exe = Resolve-BrowserExecutable -Browser $browser
    if ($null -eq $exe) {
        if ($ProcessInstalledOnly) {
            continue
        }
        Add-Result -Level FAIL -Scope $browser.Name -Name 'installed executable' -Expected 'installed' -Actual '<missing>'
    }
    else {
        $version = (Get-Item -LiteralPath $exe).VersionInfo.ProductVersion
        Add-Result -Level PASS -Scope $browser.Name -Name 'installed executable' -Expected 'installed' -Actual "$version :: $exe"
    }

    foreach ($policy in $commonChromiumPolicies) {
        Test-EffectivePolicy -Browser $browser.Name -PolicySubPath $browser.Policy -Name $policy.Name -Expected $policy.Expected
    }
    Test-EffectivePolicy -Browser $browser.Name -PolicySubPath (Join-Path $browser.Policy 'RestoreOnStartupURLs') -Name '1' -Expected 'about:blank'

    $forcelistHklm = Get-RegistryPolicyValueCount -Hive 'HKEY_LOCAL_MACHINE' -SubPath (Join-Path $browser.Policy 'ExtensionInstallForcelist')
    $forcelistHkcu = Get-RegistryPolicyValueCount -Hive 'HKEY_CURRENT_USER' -SubPath (Join-Path $browser.Policy 'ExtensionInstallForcelist')
    if ($RequireMachinePolicy) {
        Test-Value -Scope $browser.Name -Name 'HKLM ExtensionInstallForcelist count' -Actual $forcelistHklm -Expected 0
    }
    elseif ($forcelistHklm -eq 0 -and $forcelistHkcu -eq 0) {
        Add-Result -Level PASS -Scope $browser.Name -Name 'ExtensionInstallForcelist empty' -Expected 0 -Actual "HKLM=$forcelistHklm; HKCU=$forcelistHkcu"
    }
    else {
        Add-Result -Level FAIL -Scope $browser.Name -Name 'ExtensionInstallForcelist empty' -Expected 0 -Actual "HKLM=$forcelistHklm; HKCU=$forcelistHkcu"
    }

    if ($browser.Name -eq 'Edge') {
        foreach ($policy in $edgePolicies) {
            Test-EffectivePolicy -Browser $browser.Name -PolicySubPath $browser.Policy -Name $policy.Name -Expected $policy.Expected
        }
    }
    if ($browser.Name -eq 'Brave') {
        foreach ($policy in $bravePolicies) {
            Test-EffectivePolicy -Browser $browser.Name -PolicySubPath $browser.Policy -Name $policy.Name -Expected $policy.Expected
        }
    }

    $prefFiles = @(Get-ChromiumPreferenceFiles -UserDataRoot $browser.UserDataRoot)
    if ($prefFiles.Count -eq 0) {
        Add-Result -Level WARN -Scope $browser.Name -Name 'profile preferences' -Expected 'at least one Preferences file' -Actual '<missing>' -Details 'registry policies still apply'
    }
    foreach ($prefFile in $prefFiles) {
        Test-ProfilePreferenceFile -Browser $browser.Name -Path $prefFile -Checks $profileChecks
    }
}

$operaExe = Resolve-BrowserExecutable -Browser $opera
if ($null -eq $operaExe) {
    if (-not $ProcessInstalledOnly) {
        Add-Result -Level FAIL -Scope 'Opera' -Name 'installed executable' -Expected 'installed' -Actual '<missing>'
    }
}
else {
    $version = (Get-Item -LiteralPath $operaExe).VersionInfo.ProductVersion
    Add-Result -Level PASS -Scope 'Opera' -Name 'installed executable' -Expected 'installed' -Actual "$version :: $operaExe"

    $operaPrefFiles = @(Get-ChromiumPreferenceFiles -UserDataRoot $opera.UserDataRoot)
    if ($operaPrefFiles.Count -eq 0) {
        Add-Result -Level FAIL -Scope 'Opera' -Name 'profile preferences' -Expected 'at least one Preferences file' -Actual '<missing>'
    }
    foreach ($prefFile in $operaPrefFiles) {
        Test-ProfilePreferenceFile -Browser 'Opera' -Path $prefFile -Checks $operaProfileChecks -Required
    }
}

foreach ($browser in $firefoxBrowsers) {
    $exe = Resolve-BrowserExecutable -Browser $browser
    if ($null -eq $exe) {
        if ($ProcessInstalledOnly) {
            continue
        }
        Add-Result -Level FAIL -Scope $browser.Name -Name 'installed executable' -Expected 'installed' -Actual '<missing>'
    }
    else {
        $version = (Get-Item -LiteralPath $exe).VersionInfo.ProductVersion
        Add-Result -Level PASS -Scope $browser.Name -Name 'installed executable' -Expected 'installed' -Actual "$version :: $exe"
        $browser.InstallRoot = Split-Path $exe -Parent
    }

    $policyPath = Join-Path $browser.InstallRoot 'distribution\policies.json'
    $policy = Read-JsonFile -Path $policyPath -Scope $browser.Name
    if ($null -eq $policy) {
        Add-Result -Level FAIL -Scope $browser.Name -Name 'policies.json' -Expected 'readable Mozilla policy file' -Actual $policyPath
    }
    else {
        Add-Result -Level PASS -Scope $browser.Name -Name 'policies.json parse' -Expected 'valid JSON' -Actual $policyPath
        foreach ($check in $firefoxPolicyChecks) {
            $actual = Get-NestedValue -Object $policy -Path $check.Path
            Test-Value -Scope $browser.Name -Name "policy $($check.Name)" -Actual $actual -Expected $check.Expected
        }
    }

    if (Test-Path -LiteralPath $browser.Profiles) {
        $profiles = @(Get-ChildItem -LiteralPath $browser.Profiles -Directory -ErrorAction SilentlyContinue)
        if ($profiles.Count -eq 0) {
            Add-Result -Level WARN -Scope $browser.Name -Name 'profile count' -Expected 'profile exists after first launch' -Actual 0
        }
        foreach ($profile in $profiles) {
            $userJs = Join-Path $profile.FullName 'user.js'
            if (Test-Path -LiteralPath $userJs) {
                Add-Result -Level PASS -Scope $browser.Name -Name "user.js $($profile.Name)" -Expected 'exists' -Actual $userJs
            }
            else {
                Add-Result -Level WARN -Scope $browser.Name -Name "user.js $($profile.Name)" -Expected 'exists' -Actual '<missing>' -Details 'policies.json still applies; rerun optimizer after browser creates profiles'
            }
        }
    }
    else {
        Add-Result -Level WARN -Scope $browser.Name -Name 'profile root' -Expected 'profile root exists after first launch' -Actual $browser.Profiles
    }
}

foreach ($processName in @('chrome','msedge','brave','vivaldi','opera','firefox','librewolf','zen')) {
    Test-NoRuntimeProcess -ProcessName $processName
}

Add-Result -Level WARN -Scope 'KnownLimit' -Name 'Chromium bookmark click foreground tab' -Expected 'official policy support' -Actual 'unsupported' -Details 'Firefox-family supports this through browser.tabs.loadBookmarksInTabs; Chromium-family browsers do not expose an official equivalent policy.'
Add-Result -Level WARN -Scope 'KnownLimit' -Name 'Opera registry policy' -Expected 'documented Opera Windows policy surface' -Actual 'not used' -Details 'Opera cleanup is verified through profile preferences instead of pretending Chrome registry policy support.'
Add-Result -Level WARN -Scope 'KnownLimit' -Name 'Chrome NewTabPageLocation' -Expected 'always honored unmanaged' -Actual 'may be ignored' -Details 'Confirm in chrome://policy after restart on unmanaged Windows devices.'

$failCount = @($script:Results | Where-Object Level -eq 'FAIL').Count
$warnCount = @($script:Results | Where-Object Level -eq 'WARN').Count
$passCount = @($script:Results | Where-Object Level -eq 'PASS').Count

if (-not $Quiet) {
    Write-Host 'Browser optimization verification'
    Write-Host '================================='
    Write-Host "Repo: $repoRoot"
    Write-Host "Elevated: $(Test-IsAdmin)"
    Write-Host "RequireMachinePolicy: $RequireMachinePolicy"
    Write-Host "StrictProfilePreferences: $StrictProfilePreferences"
    Write-Host "Detailed: $Detailed"
    $browserSelection = if ($ProcessInstalledOnly) { 'detected browsers only (default)' } else { 'all supported browsers' }
    Write-Host "Browser selection: $browserSelection"
    Write-Host ''
    Write-Host "Summary: PASS=$passCount WARN=$warnCount FAIL=$failCount"
    Write-Host ''

    Write-ResultSummary -Title 'Browser summary' -Items $script:Results -KeySelector { param($item) $item.Scope }
    Write-ResultSummary -Title 'Category summary' -Items $script:Results -KeySelector { param($item) Get-ResultCategory -Result $item }

    foreach ($level in @('FAIL','WARN')) {
        $items = @($script:Results | Where-Object Level -eq $level)
        Write-Host "${level}:"
        if ($items.Count -eq 0) {
            Write-Host '  none'
        }
        else {
            foreach ($item in $items) {
                Write-Host (Format-ResultLine -Item $item)
            }
        }
        Write-Host ''
    }

    if ($Detailed) {
        Write-Host 'All verification items:'
        foreach ($item in @($script:Results | Sort-Object Scope, Name, Level)) {
            Write-Host "  $($item.Level) $(Format-ResultLine -Item $item)"
        }
    }
    else {
        Write-Host 'PASS samples:'
        foreach ($item in @($script:Results | Where-Object Level -eq 'PASS' | Select-Object -First 20)) {
            Write-Host "  [$($item.Scope)] $($item.Name)"
        }
    }
}

if ($failCount -gt 0) {
    exit 1
}
exit 0
