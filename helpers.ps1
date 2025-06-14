Set-StrictMode -Version Latest

function Invoke-CheckedCommand {
    param(
        [Parameter(Mandatory)][ScriptBlock]$Command,
        [switch]$WhatIf
    )
    if ($WhatIf) {
        Write-Host "[WhatIf] $($Command.ToString())" -ForegroundColor Yellow
    } else {
        & $Command
        if ($LASTEXITCODE -ne 0) {
            throw "Command failed: $($Command.ToString())"
        }
    }
}

function Assert-Config {
    param(
        [hashtable]$Config
    )
    foreach ($key in 'TargetFolders','PathsToPurge','WheelhouseSrc','GCSBucket','GCSKeyPath') {
        if (-not $Config.ContainsKey($key)) { throw "Missing configuration value: $key" }
    }
}

function Start-CleanupLog {
    param([string]$LogDir)
    if (-not (Test-Path $LogDir)) { New-Item -ItemType Directory -Path $LogDir | Out-Null }
    $global:CleanupLogPath = Join-Path $LogDir ("cleanup-" + (Get-Date -Format 'yyyyMMdd-HHmmss') + ".log")
    Start-Transcript -Path $CleanupLogPath | Out-Null
}

function Stop-CleanupLog {
    Stop-Transcript | Out-Null
    Write-Host "Log saved to $CleanupLogPath"
}
