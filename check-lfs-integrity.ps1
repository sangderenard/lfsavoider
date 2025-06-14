param(
    [switch]$Verbose
)

$fsckOutput = git lfs fsck 2>&1
$missing = $fsckOutput | Select-String "Object does not exist on the server"

if ($missing) {
    Write-Host "Missing LFS objects detected:" -ForegroundColor Red
    $missing | ForEach-Object { Write-Host $_.Line }
    exit 1
} else {
    Write-Host "No missing LFS objects found."
    exit 0
}
