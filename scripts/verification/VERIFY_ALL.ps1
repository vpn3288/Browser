# ========================================
# Configuration Verification Script v6.0
# 验证所有浏览器配置是否正确应用
# ========================================

$ErrorActionPreference = "Continue"

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Configuration Verification v6.0" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# ========================================
# 验证 Chromium 系浏览器注册表配置
# ========================================

function Verify-ChromiumBrowser {
    param(
        [string]$BrowserName,
        [string]$PolicyPath
    )
    
    Write-Host ""
    Write-Host "Verifying $BrowserName..." -ForegroundColor Yellow
    
    if (-not (Test-Path $PolicyPath)) {
        Write-Host "  [FAIL] Policy path not found: $PolicyPath" -ForegroundColor Red
        return $false
    }
    
    $policies = Get-ItemProperty -Path $PolicyPath -ErrorAction SilentlyContinue
    
    if (-not $policies) {
        Write-Host "  [FAIL] No policies found" -ForegroundColor Red
        return $false
    }
    
    # 关键配置检查
    $checkList = @(
        @{Key="MetricsReportingEnabled"; Expected=0},
        @{Key="BrowserSignin"; Expected=0},
        @{Key="SyncDisabled"; Expected=1},
        @{Key="BlockThirdPartyCookies"; Expected=1},
        @{Key="BookmarkBarEnabled"; Expected=1},
        @{Key="BackgroundModeEnabled"; Expected=0},
        @{Key="DefaultBrowserSettingEnabled"; Expected=0},
        @{Key="TranslateEnabled"; Expected=0},
        @{Key="PasswordManagerEnabled"; Expected=0}
    )
    
    $passed = 0
    $failed = 0
    
    foreach ($check in $checkList) {
        $key = $check.Key
        $expected = $check.Expected
        $actual = $policies.$key
        
        if ($actual -eq $expected) {
            Write-Host "  [OK] $key = $actual" -ForegroundColor Green
            $passed++
        } else {
            Write-Host "  [FAIL] $key = $actual (expected $expected)" -ForegroundColor Red
            $failed++
        }
    }
    
    Write-Host ""
    Write-Host "  [$BrowserName] Passed: $passed | Failed: $failed" -ForegroundColor $(if ($failed -eq 0) { "Green" } else { "Yellow" })
    
    return ($failed -eq 0)
}

# ========================================
# 验证 Firefox 系浏览器配置
# ========================================

function Verify-FirefoxBrowser {
    param(
        [string]$BrowserName,
        [string]$PoliciesPath
    )
    
    Write-Host ""
    Write-Host "Verifying $BrowserName..." -ForegroundColor Yellow
    
    if (-not (Test-Path $PoliciesPath)) {
        Write-Host "  [FAIL] policies.json not found: $PoliciesPath" -ForegroundColor Red
        return $false
    }
    
    try {
        $policies = Get-Content -Path $PoliciesPath -Raw | ConvertFrom-Json
        
        # 关键配置检查
        $checkList = @(
            @{Key="DisableTelemetry"; Expected=$true},
            @{Key="DisablePocket"; Expected=$true},
            @{Key="DisableFirefoxAccounts"; Expected=$true},
            @{Key="SearchSuggestEnabled"; Expected=$false},
            @{Key="PasswordManagerEnabled"; Expected=$false},
            @{Key="HttpsOnlyMode"; Expected="enabled"}
        )
        
        $passed = 0
        $failed = 0
        
        foreach ($check in $checkList) {
            $key = $check.Key
            $expected = $check.Expected
            $actual = $policies.policies.$key
            
            if ($actual -eq $expected) {
                Write-Host "  [OK] $key = $actual" -ForegroundColor Green
                $passed++
            } else {
                Write-Host "  [FAIL] $key = $actual (expected $expected)" -ForegroundColor Red
                $failed++
            }
        }
        
        Write-Host ""
        Write-Host "  [$BrowserName] Passed: $passed | Failed: $failed" -ForegroundColor $(if ($failed -eq 0) { "Green" } else { "Yellow" })
        
        return ($failed -eq 0)
    }
    catch {
        Write-Host "  [FAIL] Error reading policies.json: $_" -ForegroundColor Red
        return $false
    }
}

# ========================================
# 验证启动脚本
# ========================================

function Verify-LaunchScripts {
    Write-Host ""
    Write-Host "Verifying Launch Scripts..." -ForegroundColor Yellow
    
    $profileRoot = "C:\BrowserProfiles"
    
    if (-not (Test-Path $profileRoot)) {
        Write-Host "  [FAIL] Profile root not found: $profileRoot" -ForegroundColor Red
        return $false
    }
    
    $browsers = @("Chrome", "Edge", "Brave", "Opera", "Vivaldi", "Chromium", "Firefox", "LibreWolf")
    
    $passed = 0
    $failed = 0
    
    foreach ($browser in $browsers) {
        $scriptPath = Join-Path $profileRoot "Launch_$browser.bat"
        
        if (Test-Path $scriptPath) {
            Write-Host "  [OK] Launch_$browser.bat exists" -ForegroundColor Green
            $passed++
        } else {
            Write-Host "  [FAIL] Launch_$browser.bat not found" -ForegroundColor Red
            $failed++
        }
    }
    
    $launchAllPath = Join-Path $profileRoot "Launch_All.bat"
    if (Test-Path $launchAllPath) {
        Write-Host "  [OK] Launch_All.bat exists" -ForegroundColor Green
        $passed++
    } else {
        Write-Host "  [FAIL] Launch_All.bat not found" -ForegroundColor Red
        $failed++
    }
    
    Write-Host ""
    Write-Host "  [Launch Scripts] Passed: $passed | Failed: $failed" -ForegroundColor $(if ($failed -eq 0) { "Green" } else { "Yellow" })
    
    return ($failed -eq 0)
}

# ========================================
# 主执行流程
# ========================================

$allPassed = $true

# Chromium 系浏览器
$allPassed = (Verify-ChromiumBrowser -BrowserName "Chrome" -PolicyPath "HKLM:\SOFTWARE\Policies\Google\Chrome") -and $allPassed
$allPassed = (Verify-ChromiumBrowser -BrowserName "Chromium" -PolicyPath "HKLM:\SOFTWARE\Policies\Chromium") -and $allPassed
$allPassed = (Verify-ChromiumBrowser -BrowserName "Edge" -PolicyPath "HKLM:\SOFTWARE\Policies\Microsoft\Edge") -and $allPassed
$allPassed = (Verify-ChromiumBrowser -BrowserName "Brave" -PolicyPath "HKLM:\SOFTWARE\Policies\BraveSoftware\Brave") -and $allPassed
$allPassed = (Verify-ChromiumBrowser -BrowserName "Opera" -PolicyPath "HKLM:\SOFTWARE\Policies\Opera Software\Opera") -and $allPassed
$allPassed = (Verify-ChromiumBrowser -BrowserName "Vivaldi" -PolicyPath "HKLM:\SOFTWARE\Policies\Vivaldi") -and $allPassed

# Firefox 系浏览器
$allPassed = (Verify-FirefoxBrowser -BrowserName "Firefox" -PoliciesPath "C:\Program Files\Mozilla Firefox\distribution\policies.json") -and $allPassed
$allPassed = (Verify-FirefoxBrowser -BrowserName "LibreWolf" -PoliciesPath "C:\Program Files\LibreWolf\distribution\policies.json") -and $allPassed

# 启动脚本
$allPassed = (Verify-LaunchScripts) -and $allPassed

Write-Host ""
Write-Host "========================================" -ForegroundColor $(if ($allPassed) { "Green" } else { "Red" })
Write-Host "Verification $(if ($allPassed) { 'PASSED' } else { 'FAILED' })" -ForegroundColor $(if ($allPassed) { "Green" } else { "Red" })
Write-Host "========================================" -ForegroundColor $(if ($allPassed) { "Green" } else { "Red" })
Write-Host ""

if ($allPassed) {
    Write-Host "All configurations are correctly applied!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Cyan
    Write-Host "1. Configure Clash proxy (8 different US IPs, ports 7891-7898)" -ForegroundColor White
    Write-Host "2. Launch browsers: C:\BrowserProfiles\Launch_All.bat" -ForegroundColor White
    Write-Host "3. Test WebRTC: https://browserleaks.com/webrtc" -ForegroundColor White
    Write-Host "4. Test fingerprints: https://amiunique.org" -ForegroundColor White
    Write-Host "5. Verify policies: chrome://policy or about:policies" -ForegroundColor White
} else {
    Write-Host "Some configurations failed. Please review the errors above." -ForegroundColor Red
}

Write-Host ""
