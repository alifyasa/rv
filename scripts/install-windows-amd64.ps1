# install-windows-amd64.ps1 - Install rv for Windows AMD64 from GitHub releases

param(
    [string]$InstallPath = ""
)

# Set execution policy for this session
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope Process -Force

# Binary info
$BINARY_NAME = "rv-windows-amd64.exe"
$TARGET_NAME = "rv.exe"
$REPO = "alifyasa/rv"

Write-Host "Installing rv for Windows AMD64..." -ForegroundColor Green

# Function to get latest release download URL
function Get-LatestReleaseUrl {
    try {
        $response = Invoke-RestMethod -Uri "https://api.github.com/repos/$REPO/releases/latest"
        $asset = $response.assets | Where-Object { $_.name -eq $BINARY_NAME }
        return $asset.browser_download_url
    }
    catch {
        Write-Host "Error: Could not fetch latest release information" -ForegroundColor Red
        return $null
    }
}

# Function to test if path is writable
function Test-WriteAccess {
    param([string]$Path)

    if (-not (Test-Path $Path)) {
        try {
            New-Item -Path $Path -ItemType Directory -Force | Out-Null
        }
        catch {
            return $false
        }
    }

    try {
        $testFile = Join-Path $Path "write_test_$(Get-Random).tmp"
        New-Item -Path $testFile -ItemType File -Force | Out-Null
        Remove-Item -Path $testFile -Force
        return $true
    }
    catch {
        return $false
    }
}

# Function to try installing to a directory
function Try-Install {
    param([string]$Dir)

    Write-Host "Trying to install to $Dir..." -ForegroundColor Yellow

    if (-not (Test-WriteAccess $Dir)) {
        Write-Host "No write permission to $Dir" -ForegroundColor Red
        return $false
    }

    # Download binary
    Write-Host "Downloading $BINARY_NAME from GitHub releases..."
    $downloadUrl = Get-LatestReleaseUrl

    if (-not $downloadUrl) {
        Write-Host "Error: Could not find download URL for $BINARY_NAME" -ForegroundColor Red
        return $false
    }

    $target = Join-Path $Dir $TARGET_NAME

    try {
        # Download with progress
        $webClient = New-Object System.Net.WebClient
        $webClient.DownloadFile($downloadUrl, $target)
        $webClient.Dispose()

        Write-Host "✅ Successfully installed $TARGET_NAME to $Dir" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Host "Error: Failed to download or install $BINARY_NAME" -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
        return $false
    }
}

# Get current PATH
$pathDirs = $env:PATH -split ';' | Where-Object { $_ -ne "" }

# Preferred installation directories (in order of preference)
$preferredDirs = @(
    "$env:LOCALAPPDATA\Programs\rv",
    "$env:USERPROFILE\bin",
    "C:\Program Files\rv"
)

# If user specified a path, try that first
if ($InstallPath) {
    if (Try-Install $InstallPath) {
        # Add to user PATH if not already there
        $userPath = [Environment]::GetEnvironmentVariable("PATH", "User")
        if ($userPath -notlike "*$InstallPath*") {
            Write-Host "Adding $InstallPath to user PATH..." -ForegroundColor Yellow
            [Environment]::SetEnvironmentVariable("PATH", "$userPath;$InstallPath", "User")
            Write-Host "Note: You may need to restart your terminal for PATH changes to take effect" -ForegroundColor Yellow
        }
        Write-Host "Installation complete! You can now run: rv" -ForegroundColor Green
        exit 0
    }
}

# Try preferred directories
foreach ($dir in $preferredDirs) {
    if (Try-Install $dir) {
        # Add to user PATH if not already there and not a system directory
        if ($dir -notlike "C:\Program Files*") {
            $userPath = [Environment]::GetEnvironmentVariable("PATH", "User")
            if ($userPath -notlike "*$dir*") {
                Write-Host "Adding $dir to user PATH..." -ForegroundColor Yellow
                [Environment]::SetEnvironmentVariable("PATH", "$userPath;$dir", "User")
                Write-Host "Note: You may need to restart your terminal for PATH changes to take effect" -ForegroundColor Yellow
            }
        }
        Write-Host "Installation complete! You can now run: rv" -ForegroundColor Green
        exit 0
    }
}

# If all failed, show manual instructions
Write-Host ""
Write-Host "❌ Automatic installation failed" -ForegroundColor Red
Write-Host ""
Write-Host "Manual installation:" -ForegroundColor Yellow

$downloadUrl = Get-LatestReleaseUrl
if ($downloadUrl) {
    Write-Host "1. Download the binary manually:"
    Write-Host "   Invoke-WebRequest -Uri '$downloadUrl' -OutFile 'rv.exe'"
}

Write-Host ""
Write-Host "2. Choose an installation directory:"
Write-Host "   - $env:LOCALAPPDATA\Programs\rv (recommended)"
Write-Host "   - C:\Program Files\rv (requires admin)"
Write-Host "   - Any directory in your PATH"

Write-Host ""
Write-Host "3. Create directory and install:"
Write-Host "   New-Item -Path 'C:\Program Files\rv' -ItemType Directory -Force"
Write-Host "   Copy-Item 'rv.exe' 'C:\Program Files\rv\rv.exe'"

Write-Host ""
Write-Host "4. Add directory to PATH if needed (for user installs):"
Write-Host "   `$userPath = [Environment]::GetEnvironmentVariable('PATH', 'User')"
Write-Host "   [Environment]::SetEnvironmentVariable('PATH', \"`$userPath;C:\your\install\path\", 'User')"

exit 1
