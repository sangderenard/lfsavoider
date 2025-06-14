param(
    [switch]$Verbose
)

function Check-Command {
    param([string]$Cmd)
    if (-not (Get-Command $Cmd -ErrorAction SilentlyContinue)) {
        Write-Error "$Cmd is required but not found"
        return $false
    }
    return $true
}

$allGood = $true
$allGood &= Check-Command git
$allGood &= Check-Command 'git-lfs'
$allGood &= Check-Command gsutil
$allGood &= Check-Command tar

$disk = Get-PSDrive -Name (Get-Item .).PSDrive.Name
$repoSize = (Get-ChildItem -Recurse | Measure-Object -Property Length -Sum).Sum
if ($disk.Free -lt $repoSize*2) {
    Write-Warning "Less than 2x repo size free disk space"
}

if ($allGood) {
    Write-Host "Preflight checks passed"
    exit 0
} else {
    Write-Host "Preflight checks failed" -ForegroundColor Red
    exit 1
}
