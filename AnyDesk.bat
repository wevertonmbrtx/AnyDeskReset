@echo off
cls
title AnyDesk
mode con:cols=85 lines=34
chcp 437 >nul

echo                             @                 @@@
echo                           @@@@@             @@@@@@@
echo                         @@@@@@@@@         @@@@@@@@@@@
echo                       @@@@@@@@@@@@@         @@@@@@@@@@@
echo                     @@@@@@@@@@@@@@@@@         @@@@@@@@@@@
echo                   @@@@@@@@@@@@@@@@@@@@@         @@@@@@@@@@@
echo                 @@@@@@@@@@@@@@@@@@@@@@@@@         @@@@@@@@@@@
echo               @@@@@@@@@@@@@@@@@@@@@@@@@@@@@         @@@@@@@@@@@
echo             @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@         @@@@@@@@@@@
echo           @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@         @@@@@@@@@@@
echo         @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@         @@@@@@@@@@@
echo       @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@         @@@@@@@@@@@
echo     @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@         @@@@@@@@@@@    
echo       @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@         @@@@@@@@@@@
echo         @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@         @@@@@@@@@@@
echo           @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@         @@@@@@@@@@@
echo             @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@         @@@@@@@@@@@
echo               @@@@@@@@@@@@@@@@@@@@@@@@@@@@@         @@@@@@@@@@@
echo                 @@@@@@@@@@@@@@@@@@@@@@@@@         @@@@@@@@@@@
echo                   @@@@@@@@@@@@@@@@@@@@@         @@@@@@@@@@@
echo                     @@@@@@@@@@@@@@@@@         @@@@@@@@@@@
echo                       @@@@@@@@@@@@@         @@@@@@@@@@@
echo                         @@@@@@@@@         @@@@@@@@@@@
echo                           @@@@@             @@@@@@@
echo                             @                 @@@
timeout 1 >nul

:init
    setlocal EnableExtensions DisableDelayedExpansion
    set cmdInvoke=1
    set winSysFolder=System32
    set "batchPath=%~f0"
    set "service=AnyDesk"
    set "insPath0=%ProgramFiles(x86)%\AnyDesk\AnyDesk.exe"
    set "insPath1=%ProgramFiles%\AnyDesk\AnyDesk.exe"
    set "porPath0=%TEMP%\AnyDesk.exe"
    set "url=https://download.anydesk.com/AnyDesk.exe"
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
    sc query "%service%" >nul 2>&1
    if errorlevel 1 goto no_service
    if not exist "%ProgramFiles(x86)%\AnyDesk\AnyDesk.exe" if not exist "%ProgramFiles%\AnyDesk\AnyDesk.exe" goto no_service
    del /f /q "%porPath0%" >nul 2>&1

    echo Stopping AnyDesk...
    sc stop "%service%" >nul 2>&1
    taskkill /f /im "AnyDesk.exe" >nul 2>&1
    timeout /t 2 >nul

    copy /y "%APPDATA%\AnyDesk\user.conf" "%TEMP%\anydesk_user.conf" >nul 2>&1

    del /f /q "%ALLUSERSPROFILE%\AnyDesk\*.conf" 2>nul
    del /f /q "%APPDATA%\AnyDesk\*.conf"         2>nul
    rd /s /q "%LOCALAPPDATA%\AnyDesk"            2>nul

    cls
    echo.
    echo Initializing AnyDesk and service...
    sc start "%service%" >nul 2>&1

    set _count=0
:wait_id
    find "ad.anynet.id=" "%ALLUSERSPROFILE%\AnyDesk\system.conf" >nul 2>&1
    if not errorlevel 1 goto id_found
    timeout /t 1 >nul
    set /a _count+=1
    if %_count% lss 60 goto wait_id
    echo Warning: timeout waiting new ID.
    goto open_gui

:id_found
    for /f "tokens=2 delims==" %%i in ('find "ad.anynet.id=" "%ALLUSERSPROFILE%\AnyDesk\system.conf" 2^>nul') do echo ID: %%i

:open_gui
    if exist "%TEMP%\anydesk_user.conf" move /y "%TEMP%\anydesk_user.conf" "%APPDATA%\AnyDesk\user.conf" >nul 2>&1

    set "_exe="
    if exist "%insPath0%" set "_exe=%insPath0%"
    if not defined _exe if exist "%insPath1%" set "_exe=%insPath1%"
    if not defined _exe (
        cls
        echo Error: "AnyDesk.exe" not found.
        pause >nul
        goto :eof
    )

    sc stop "%service%" >nul 2>&1
    taskkill /f /im "AnyDesk.exe" >nul 2>&1
    timeout /t 2 >nul
    start "" /wait "%_exe%"

    taskkill /f /im "AnyDesk.exe" >nul 2>&1
    echo Success.
    goto :eof

:no_service
    echo Downloading "AnyDesk.exe"...
    call :download
    if errorlevel 1 goto :eof

    echo Executing portable version...
    start "" /wait "%porPath0%"

    taskkill /f /im "AnyDesk.exe" >nul 2>&1
    timeout /t 2 >nul
    del /f /q "%porPath0%"            2>nul
    rd /s /q "%APPDATA%\AnyDesk"      2>nul
    rd /s /q "%LOCALAPPDATA%\AnyDesk" 2>nul
    echo Success.
    goto :eof

:download
    if exist "%porPath0%" exit /b 0

    curl -L -s --max-time 120 -o "%porPath0%" "%url%" 2>nul
    if exist "%porPath0%" exit /b 0

    certutil -urlcache -f "%url%" nul >nul 2>&1
    certutil -urlcache -split -f "%url%" "%porPath0%" >nul 2>&1
    if exist "%porPath0%" exit /b 0

    set "dlVbs=%TEMP%\dl.vbs"
    >  "%dlVbs%" echo Const T = 120000
    >> "%dlVbs%" echo Set x = CreateObject("MSXML2.XMLHTTP")
    >> "%dlVbs%" echo x.Open "GET", WScript.Arguments(0), False
    >> "%dlVbs%" echo x.setTimeouts T, T, T, T
    >> "%dlVbs%" echo x.Send
    >> "%dlVbs%" echo If x.Status = 200 Then
    >> "%dlVbs%" echo   Set s = CreateObject("ADODB.Stream")
    >> "%dlVbs%" echo   s.Type = 1 : s.Open : s.Write x.ResponseBody
    >> "%dlVbs%" echo   s.SaveToFile WScript.Arguments(1), 2 : s.Close
    >> "%dlVbs%" echo End If
    cscript //nologo "%dlVbs%" "%url%" "%porPath0%"
    del /f /q "%dlVbs%" >nul 2>&1
    if exist "%porPath0%" exit /b 0

    echo Download error. File "AnyDesk.exe" can't download.
    pause >nul
    exit /b 1
