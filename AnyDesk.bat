@echo off
cls
title Iniciar AnyDesk
chcp 437 >nul

:init
    setlocal EnableExtensions DisableDelayedExpansion
    set cmdInvoke=1
    set winSysFolder=System32
    set "batchPath=%~f0"
    set "anydeskService=AnyDesk"
    set "anydesk1=%ProgramFiles(x86)%\AnyDesk\AnyDesk.exe"
    set "anydesk2=%ProgramFiles%\AnyDesk\AnyDesk.exe"
    set "anydesk3=%TEMP%\AnyDesk.exe"
    set "anydeskURL=https://download.anydesk.com/AnyDesk.exe"
    for %%k in ("%~f0") do set batchName=%%~nk
    set "vbsGetPrivileges=%TEMP%\getPrivilegesFor%batchName%.vbs"
    setlocal EnableDelayedExpansion

:check_privileges
    %SystemRoot%\%winSysFolder%\whoami.exe /groups /nh | %SystemRoot%\%winSysFolder%\find.exe "S-1-16-12288" 1>nul
    if errorlevel 1 goto get_privileges

:check_privileges2
    %SystemRoot%\%winSysFolder%\net.exe session 1>nul 2>nul
    if not errorlevel 1 goto got_privileges

:get_privileges
    if "%~1"=="ELEV" (echo ELEV & shift /1 & goto got_privileges)
    echo Set UAC = CreateObject^("Shell.Application"^) > "%vbsGetPrivileges%"
    echo args = "ELEV " >> "%vbsGetPrivileges%"
    echo For Each strArg in WScript.Arguments >> "%vbsGetPrivileges%"
    echo args = args ^& strArg ^& " " >> "%vbsGetPrivileges%"
    echo Next >> "%vbsGetPrivileges%"

    if "%cmdInvoke%"=="1" goto invoke_cmd

    echo UAC.ShellExecute "!batchPath!", args, "", "runas", 2 >> "%vbsGetPrivileges%"
    goto exec_elevation

:invoke_cmd
    echo args = "/c """ + "!batchPath!" + """ " + args >> "%vbsGetPrivileges%"
    echo UAC.ShellExecute "%SystemRoot%\%winSysFolder%\cmd.exe", args, "", "runas", 2 >> "%vbsGetPrivileges%"

:exec_elevation
    "%SystemRoot%\%winSysFolder%\WScript.exe" "%vbsGetPrivileges%" %*
    exit /B

:got_privileges
    endlocal
    setlocal
    cd /d "%~dp0"
    if "%~1"=="ELEV" (del "%vbsGetPrivileges%" 1>nul 2>nul & shift /1)
    goto main

:main
    sc query "%anydeskService%" >nul 2>&1
    if errorlevel 1 goto no_service
    if not exist "%ProgramFiles(x86)%\AnyDesk\AnyDesk.exe" if not exist "%ProgramFiles%\AnyDesk\AnyDesk.exe" goto no_service
    del /f /q "%anydesk3%" >nul 2>&1

    echo Parando AnyDesk...
    sc stop "%anydeskService%" >nul 2>&1
    taskkill /f /im "AnyDesk.exe" >nul 2>&1
    timeout /t 2 >nul

    copy /y "%APPDATA%\AnyDesk\user.conf" "%TEMP%\anydesk_user.conf" >nul 2>&1

    del /f /q "%ALLUSERSPROFILE%\AnyDesk\*.conf" 2>nul
    del /f /q "%APPDATA%\AnyDesk\*.conf"         2>nul
    rd /s /q "%LOCALAPPDATA%\AnyDesk"            2>nul

    echo Iniciando AnyDesk...
    sc start "%anydeskService%" >nul 2>&1

    set _count=0
:wait_id
    find "ad.anynet.id=" "%ALLUSERSPROFILE%\AnyDesk\system.conf" >nul 2>&1
    if not errorlevel 1 goto id_found
    timeout /t 1 >nul
    set /a _count+=1
    if %_count% lss 60 goto wait_id
    echo Aviso: timeout aguardando novo ID.
    goto open_gui

:id_found
    for /f "tokens=2 delims==" %%i in ('find "ad.anynet.id=" "%ALLUSERSPROFILE%\AnyDesk\system.conf" 2^>nul') do echo Novo ID: %%i

:open_gui
    if exist "%TEMP%\anydesk_user.conf" move /y "%TEMP%\anydesk_user.conf" "%APPDATA%\AnyDesk\user.conf" >nul 2>&1

    set "_exe="
    if exist "%anydesk1%" set "_exe=%anydesk1%"
    if not defined _exe if exist "%anydesk2%" set "_exe=%anydesk2%"
    if not defined _exe (
        echo Erro: executavel do AnyDesk nao encontrado.
        pause >nul
        goto :eof
    )

    sc stop "%anydeskService%" >nul 2>&1
    taskkill /f /im "AnyDesk.exe" >nul 2>&1
    timeout /t 2 >nul
    start "" /wait "%_exe%"

    taskkill /f /im "AnyDesk.exe" >nul 2>&1
    echo Concluido.
    goto :eof

:no_service
    echo Baixando AnyDesk...
    call :download_anydesk
    if errorlevel 1 goto :eof

    echo Executando versao portatil...
    start "" /wait "%anydesk3%"

    taskkill /f /im "AnyDesk.exe" >nul 2>&1
    timeout /t 2 >nul
    del /f /q "%anydesk3%"            2>nul
    rd /s /q "%APPDATA%\AnyDesk"      2>nul
    rd /s /q "%LOCALAPPDATA%\AnyDesk" 2>nul
    echo Concluido.
    goto :eof

:download_anydesk
    if exist "%anydesk3%" exit /b 0

    curl -L -s --max-time 120 -o "%anydesk3%" "%anydeskURL%" 2>nul
    if exist "%anydesk3%" exit /b 0

    certutil -urlcache -f "%anydeskURL%" nul >nul 2>&1
    certutil -urlcache -split -f "%anydeskURL%" "%anydesk3%" >nul 2>&1
    if exist "%anydesk3%" exit /b 0

    set "_vbs=%TEMP%\anydeskDownloader.vbs"
    >  "%_vbs%" echo Const T = 120000
    >> "%_vbs%" echo Set x = CreateObject("MSXML2.XMLHTTP")
    >> "%_vbs%" echo x.Open "GET", WScript.Arguments(0), False
    >> "%_vbs%" echo x.setTimeouts T, T, T, T
    >> "%_vbs%" echo x.Send
    >> "%_vbs%" echo If x.Status = 200 Then
    >> "%_vbs%" echo   Set s = CreateObject("ADODB.Stream")
    >> "%_vbs%" echo   s.Type = 1 : s.Open : s.Write x.ResponseBody
    >> "%_vbs%" echo   s.SaveToFile WScript.Arguments(1), 2 : s.Close
    >> "%_vbs%" echo End If
    cscript //nologo "%_vbs%" "%anydeskURL%" "%anydesk3%"
    del /f /q "%_vbs%" >nul 2>&1
    if exist "%anydesk3%" exit /b 0

    echo Falha ao baixar o AnyDesk.
    pause >nul
    exit /b 1
