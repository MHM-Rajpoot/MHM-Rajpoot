$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$metaPath = Join-Path $repoRoot "meta"
$updateScript = Join-Path $PSScriptRoot "update-readme-gifs.ps1"

if (-not (Test-Path -LiteralPath $metaPath)) {
    throw "The meta folder was not found."
}

Write-Host "Watching $metaPath for GIF changes. Press Ctrl+C to stop."
& $updateScript

$watcher = [System.IO.FileSystemWatcher]::new($metaPath, "*.gif")
$watcher.IncludeSubdirectories = $false
$watcher.EnableRaisingEvents = $true

$action = {
    Start-Sleep -Milliseconds 500
    powershell -ExecutionPolicy Bypass -File $using:updateScript
}

$events = @(
    Register-ObjectEvent -InputObject $watcher -EventName Created -Action $action
    Register-ObjectEvent -InputObject $watcher -EventName Deleted -Action $action
    Register-ObjectEvent -InputObject $watcher -EventName Renamed -Action $action
    Register-ObjectEvent -InputObject $watcher -EventName Changed -Action $action
)

try {
    while ($true) {
        Wait-Event -Timeout 1 | Out-Null
    }
}
finally {
    foreach ($event in $events) {
        Unregister-Event -SubscriptionId $event.Id -ErrorAction SilentlyContinue
    }
    $watcher.Dispose()
}
