<#
.SYNOPSIS
    Runs the browser optimizer and verifier from any repository location.
.DESCRIPTION
    This wrapper resolves the repository root from its own file path, validates
    the required scripts before doing anything disruptive, optionally closes
    running browsers, then runs optimization and verification in sequence.
#>

[CmdletBinding()]
param(
    [switch]$DryRun,
    [switch]$OnlyInstalled,
    [switch]$AllBrowsers,
    [switch]$VerifyOnly,
    [switch]$SkipVerify,
    [switch]$NoCloseBrowsers,
    [switch]$RequireMachinePolicy = $true,
    [switch]$Detailed = $true
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if ($OnlyInstalled -and $AllBrowsers) {
    throw 'Do not use -OnlyInstalled and -AllBrowsers together. The default already processes detected browsers only; use -AllBrowsers only for full-target mode.'
}
if ($VerifyOnly -and $SkipVerify) {
    throw 'Do not use -VerifyOnly and -SkipVerify together.'
}
if ($VerifyOnly -and $DryRun) {
    throw 'Do not use -VerifyOnly and -DryRun together.'
}

$BrowserProcessNames = @(
    'chrome',
    'msedge',
    'brave',
    'vivaldi',
    'opera',
    'opera_gx',
    'firefox',
    'librewolf',
    'zen'
)

function Assert-Admin {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        throw 'Current PowerShell is not elevated. Run PowerShell as Administrator, then run this script again.'
    }
}

function Get-BestPowerShell {
    $pwsh = Get-Command pwsh -ErrorAction SilentlyContinue
    if ($pwsh) {
        return $pwsh.Source
    }

    return (Get-Command powershell -ErrorAction Stop).Source
}

function Stop-BrowsersForOptimization {
    if ($NoCloseBrowsers) {
        Write-Host '[INFO] -NoCloseBrowsers specified; browser auto-close skipped.'
        return
    }

    $processes = @(Get-Process -Name $BrowserProcessNames -ErrorAction SilentlyContinue | Sort-Object ProcessName, Id)
    if ($processes.Count -eq 0) {
        return
    }

    Write-Host 'Running browsers were detected. They must be closed before optimization and verification:' -ForegroundColor Yellow
    $processes | Select-Object ProcessName, Id, MainWindowTitle | Format-Table -AutoSize
    Write-Host 'The browsers above will be closed in 8 seconds. Press Ctrl+C now to cancel.' -ForegroundColor Yellow
    Start-Sleep -Seconds 8

    $processes | Stop-Process -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 3

    $left = @(Get-Process -Name $BrowserProcessNames -ErrorAction SilentlyContinue | Select-Object -ExpandProperty ProcessName -Unique)
    if ($left.Count -gt 0) {
        throw "Some browser processes are still running: $($left -join ', '). End them in Task Manager, then run again."
    }
}

function Invoke-CheckedScript {
    param(
        [string]$PowerShellExe,
        [string]$ScriptPath,
        [string[]]$Arguments,
        [string]$FailureMessage
    )

    & $PowerShellExe -NoProfile -ExecutionPolicy Bypass -File $ScriptPath @Arguments
    $exitCode = $LASTEXITCODE
    if ($exitCode -ne 0) {
        throw "$FailureMessage, exit code: $exitCode"
    }
}

try {
    $repoRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
    $optimizeScript = Join-Path $repoRoot 'scripts\deployment\OPTIMIZE_ALL_v14.26.ps1'
    $verifyScript = Join-Path $repoRoot 'scripts\deployment\Verify-BrowserOptimization.ps1'

    if (-not $DryRun) {
        Assert-Admin
    }
    if (-not (Test-Path -LiteralPath $optimizeScript)) {
        throw "Optimizer script not found: $optimizeScript"
    }
    if (-not $SkipVerify -and -not (Test-Path -LiteralPath $verifyScript)) {
        throw "Verifier script not found: $verifyScript"
    }

    $powerShellExe = Get-BestPowerShell
    Set-Location -LiteralPath $repoRoot

    if ($VerifyOnly) {
        Stop-BrowsersForOptimization

        $verifyOnlyArgs = New-Object System.Collections.Generic.List[string]
        if ($RequireMachinePolicy) {
            $verifyOnlyArgs.Add('-RequireMachinePolicy')
        }
        if ($OnlyInstalled) {
            $verifyOnlyArgs.Add('-OnlyInstalled')
        }
        if ($AllBrowsers) {
            $verifyOnlyArgs.Add('-AllBrowsers')
        }
        if ($Detailed) {
            $verifyOnlyArgs.Add('-Detailed')
        }

        Write-Host 'Starting optimization verification...' -ForegroundColor Cyan
        Invoke-CheckedScript -PowerShellExe $powerShellExe -ScriptPath $verifyScript -Arguments $verifyOnlyArgs.ToArray() -FailureMessage 'Verification failed'
        Write-Host 'Verification completed: FAIL=0.' -ForegroundColor Green
        exit 0
    }

    if (-not $DryRun) {
        Stop-BrowsersForOptimization
    }

    $optimizeArgs = New-Object System.Collections.Generic.List[string]
    if ($OnlyInstalled) {
        $optimizeArgs.Add('-OnlyInstalled')
    }
    if ($AllBrowsers) {
        $optimizeArgs.Add('-AllBrowsers')
    }
    if ($DryRun) {
        $optimizeArgs.Add('-DryRun')
    }

    Write-Host "Starting browser optimization. Repository: $repoRoot" -ForegroundColor Cyan
    Invoke-CheckedScript -PowerShellExe $powerShellExe -ScriptPath $optimizeScript -Arguments $optimizeArgs.ToArray() -FailureMessage 'Optimizer script failed'

    if ($DryRun) {
        Write-Host 'Dry run completed: no registry or browser profile files were written.' -ForegroundColor Green
        exit 0
    }

    if ($SkipVerify) {
        Write-Host 'Optimization completed: verification skipped as requested.' -ForegroundColor Green
        exit 0
    }

    Stop-BrowsersForOptimization

    $verifyArgs = New-Object System.Collections.Generic.List[string]
    if ($RequireMachinePolicy) {
        $verifyArgs.Add('-RequireMachinePolicy')
    }
    if ($OnlyInstalled) {
        $verifyArgs.Add('-OnlyInstalled')
    }
    if ($AllBrowsers) {
        $verifyArgs.Add('-AllBrowsers')
    }
    if ($Detailed) {
        $verifyArgs.Add('-Detailed')
    }

    Write-Host 'Starting optimization verification...' -ForegroundColor Cyan
    Invoke-CheckedScript -PowerShellExe $powerShellExe -ScriptPath $verifyScript -Arguments $verifyArgs.ToArray() -FailureMessage 'Verification failed'
    Write-Host 'All done: verification passed, FAIL=0.' -ForegroundColor Green
}
catch {
    Write-Error $_.Exception.Message
    exit 1
}
