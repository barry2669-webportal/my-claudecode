<#
Reads hosts.txt (one hostname/IP per line, same folder as this script), pings each host,
and writes a timestamped CSV report of the results into the reports subfolder.
If hosts.txt does not exist, a sample file is created and the script exits so it can be edited.
#>

$ScriptDir = $PSScriptRoot
$HostsFile = Join-Path $ScriptDir "hosts.txt"
$ReportsDir = Join-Path $ScriptDir "reports"

if (-not (Test-Path $HostsFile)) {
    $sampleLines = @(
        "# 每行一個主機名稱或 IP，開頭 # 為註解，空白行會被忽略",
        "localhost",
        "127.0.0.1",
        "8.8.8.8",
        "google.com",
        "invalid.host.example"
    )
    $sampleLines | Out-File -FilePath $HostsFile -Encoding utf8

    Write-Host "找不到 hosts.txt，已建立範例檔案：$HostsFile"
    Write-Host "請編輯後再重新執行此腳本。"
    return
}

$targets = Get-Content -Path $HostsFile -Encoding UTF8 |
    ForEach-Object { $_.Trim() } |
    Where-Object { $_ -and -not $_.StartsWith("#") }

if (-not $targets) {
    Write-Host "hosts.txt 沒有可用的主機清單，請至少加入一行主機名稱或 IP。"
    return
}

if (-not (Test-Path $ReportsDir)) {
    New-Item -ItemType Directory -Path $ReportsDir | Out-Null
}

$results = foreach ($target in $targets) {
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $success = $false
    try {
        $success = Test-Connection -ComputerName $target -Count 2 -Quiet -ErrorAction Stop
    } catch {
        $success = $false
    }

    $status = if ($success) { "Success" } else { "Failed" }
    $color = if ($success) { "Green" } else { "Red" }
    Write-Host "[$timestamp] $target -> $status" -ForegroundColor $color

    [PSCustomObject]@{
        Timestamp = $timestamp
        Target    = $target
        Status    = $status
    }
}

$reportTimestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$reportFile = Join-Path $ReportsDir "host-status-$reportTimestamp.csv"
$results | Export-Csv -Path $reportFile -NoTypeInformation -Encoding utf8

Write-Host ""
Write-Host "報表已輸出：$reportFile"
