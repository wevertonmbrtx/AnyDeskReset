$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$desktop = [Environment]::GetFolderPath('Desktop')
$lnkPath = Join-Path $desktop 'AnyDesk.lnk'
$iconPath = "$env:TEMP\anydesk.ico"
$webClient = New-Object Net.WebClient
$webClient.Headers.Add('User-Agent', 'Mozilla/5.0')

if (-not (Test-Path $iconPath)) {
    try {
        $html = $webClient.DownloadString('https://play.google.com/store/apps/details?id=com.anydesk.anydeskandroid')

        if ($html -match '(https://play-lh\.googleusercontent\.com/[^\s"&]+)') {
            $pngUrl = $matches[1] + '=s256'
            $pngBytes = $webClient.DownloadData($pngUrl)

            $width  = 256
            $height = 256
            if ($width -ge 256) { $width = 0 }
            if ($height -ge 256) { $height = 0 }

            $imageSize = $pngBytes.Length
            $offset    = 6 + 16

            $icoBytes = New-Object System.Collections.Generic.List[byte]

            $icoBytes.AddRange([System.BitConverter]::GetBytes([UInt16]0))
            $icoBytes.AddRange([System.BitConverter]::GetBytes([UInt16]1))
            $icoBytes.AddRange([System.BitConverter]::GetBytes([UInt16]1))

            $icoBytes.Add([byte]$width)
            $icoBytes.Add([byte]$height)
            $icoBytes.Add([byte]0)
            $icoBytes.Add([byte]0)
            $icoBytes.AddRange([System.BitConverter]::GetBytes([UInt16]1))
            $icoBytes.AddRange([System.BitConverter]::GetBytes([UInt16]32))
            $icoBytes.AddRange([System.BitConverter]::GetBytes([UInt32]$imageSize))
            $icoBytes.AddRange([System.BitConverter]::GetBytes([UInt32]$offset))

            $icoBytes.AddRange($pngBytes)

            [System.IO.File]::WriteAllBytes($iconPath, $icoBytes.ToArray())
        } else {
            throw "URL do ícone não encontrada na página da Play Store."
        }
    } catch {
        Write-Warning "Não foi possível gerar o ícone: $_"
    }
}

if (-not (Test-Path $lnkPath)) {
    $lnkUrl = 'https://github.com/wevertonmbrtx/anydesk/raw/refs/heads/main/AnyDesk.lnk'
    $webClient.DownloadFile($lnkUrl, $lnkPath)
}

if (Test-Path $lnkPath) {
    Invoke-Item $lnkPath
} else {
    Write-Warning "Arquivo do atalho não encontrado: $lnkPath"
}
