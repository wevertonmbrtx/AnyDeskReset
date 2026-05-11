$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12


$desktop      = [Environment]::GetFolderPath('Desktop')
$lnkPath      = Join-Path $desktop 'AnyDesk.lnk'
$iconPath     = "$env:TEMP\anydesk.ico"
$webClient    = New-Object System.Net.WebClient
$webClient.Headers.Add('User-Agent', 'Mozilla/5.0')

$playStoreUrl = 'https://play.google.com/store/apps/details?id=com.anydesk.anydeskandroid'
try {
    $html = $webClient.DownloadString($playStoreUrl)
    if ($html -match '(https://play-lh\.googleusercontent\.com/[^\s"&]+)') {
        $iconUrl = $matches[1] + '=s256'
        $webClient.DownloadFile($iconUrl, $iconPath)
    } else {
        Write-Warning "Can't find: $_"
    }
} catch {
    Write-Warning "Can't download: $_"
}

if (-not (Test-Path $lnkPath)) {
    $lnkUrl = 'https://github.com/wevertonmbrtx/anydesk/raw/refs/heads/main/AnyDesk.lnk'
    $webClient.DownloadFile($lnkUrl, $lnkPath)
}

Start-Process -FilePath $lnkPath
