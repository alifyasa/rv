@echo off
rem install-windows-amd64.bat - Install rv for Windows AMD64 from GitHub releases

echo Installing rv for Windows AMD64...

rem Check if curl is available (Windows 10 1803+ has curl built-in)
curl --version >nul 2>&1
if %errorlevel% neq 0 (
    echo Error: curl is required but not found. Please use PowerShell script instead:
    echo powershell -ExecutionPolicy RemoteSigned -File install-windows-amd64.ps1
    pause
    exit /b 1
)

rem Binary info
set BINARY_NAME=rv-windows-amd64.exe
set TARGET_NAME=rv.exe
set REPO=alifyasa/rv

rem Create temp directory
set TEMP_DIR=%TEMP%\rv_install_%RANDOM%
mkdir "%TEMP_DIR%" 2>nul

rem Get latest release download URL using curl and findstr
echo Fetching latest release information...
curl -s "https://api.github.com/repos/%REPO%/releases/latest" > "%TEMP_DIR%\release.json"
if %errorlevel% neq 0 (
    echo Error: Failed to fetch release information
    goto :cleanup_and_exit
)

rem Extract download URL (basic parsing)
for /f "tokens=2 delims=:" %%a in ('type "%TEMP_DIR%\release.json" ^| findstr /C:"browser_download_url" ^| findstr /C:"%BINARY_NAME%"') do (
    set DOWNLOAD_URL=%%a
)
rem Remove quotes and whitespace
set DOWNLOAD_URL=%DOWNLOAD_URL:"=%
set DOWNLOAD_URL=%DOWNLOAD_URL: =%
set DOWNLOAD_URL=%DOWNLOAD_URL:,=%

if "%DOWNLOAD_URL%"=="" (
    echo Error: Could not find download URL for %BINARY_NAME%
    goto :cleanup_and_exit
)

echo Download URL: %DOWNLOAD_URL%

rem Try installation directories in order of preference
set INSTALL_DIRS="%LOCALAPPDATA%\Programs\rv" "%USERPROFILE%\bin" "C:\Program Files\rv"

for %%d in (%INSTALL_DIRS%) do (
    echo.
    echo Trying to install to %%d...

    rem Create directory
    mkdir %%d 2>nul

    rem Test write access
    echo test > "%%d\write_test.tmp" 2>nul
    if exist "%%d\write_test.tmp" (
        del "%%d\write_test.tmp" 2>nul

        rem Download and install
        echo Downloading %BINARY_NAME%...
        curl -L "%DOWNLOAD_URL%" -o "%%d\%TARGET_NAME%"
        if %errorlevel% equ 0 (
            echo.
            echo ✅ Successfully installed %TARGET_NAME% to %%d
            echo.

            rem Add to PATH if it's a user directory
            echo %%d | findstr /C:"Program Files" >nul
            if %errorlevel% neq 0 (
                echo Adding %%d to user PATH...
                rem Note: This requires restarting the terminal
                setx PATH "%%PATH%%;%%d" >nul 2>&1
                echo Note: You may need to restart your terminal for PATH changes to take effect
            )

            echo.
            echo Installation complete! You can now run: rv
            goto :cleanup_and_success
        ) else (
            echo Failed to download to %%d
        )
    ) else (
        echo No write permission to %%d
    )
)

rem If we get here, all installations failed
echo.
echo ❌ Automatic installation failed
echo.
echo Manual installation:
echo 1. Download the binary manually:
echo    curl -L "%DOWNLOAD_URL%" -o rv.exe
echo.
echo 2. Choose an installation directory:
echo    - %LOCALAPPDATA%\Programs\rv (recommended)
echo    - C:\Program Files\rv (requires admin)
echo.
echo 3. Create directory and install:
echo    mkdir "C:\Program Files\rv"
echo    copy rv.exe "C:\Program Files\rv\rv.exe"
echo.
echo 4. Add directory to PATH if needed
echo.

:cleanup_and_exit
if exist "%TEMP_DIR%" rmdir /s /q "%TEMP_DIR%" 2>nul
pause
exit /b 1

:cleanup_and_success
if exist "%TEMP_DIR%" rmdir /s /q "%TEMP_DIR%" 2>nul
pause
exit /b 0
