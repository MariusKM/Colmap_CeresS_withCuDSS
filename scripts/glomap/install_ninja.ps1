# Install Ninja Build System
# Downloads and installs Ninja for faster GLOMAP builds

param(
    [string]$InstallPath = "..\..\ninja",
    [string]$Version = "1.12.1"
)

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Ninja Build System Installer" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# Check if Ninja is already available
$ninjaCmd = Get-Command ninja -ErrorAction SilentlyContinue
if ($ninjaCmd) {
    $existingVersion = & ninja --version 2>&1
    Write-Host "✓ Ninja already installed (system)" -ForegroundColor Green
    Write-Host "  Version: $existingVersion" -ForegroundColor Gray
    Write-Host "  Path: $($ninjaCmd.Source)" -ForegroundColor Gray
    Write-Host "`nNo installation needed.`n" -ForegroundColor Green
    exit 0
}

# Check if local Ninja exists
$localNinja = Join-Path $InstallPath "ninja.exe"
if (Test-Path $localNinja) {
    $existingVersion = & $localNinja --version 2>&1
    Write-Host "✓ Ninja already installed (local)" -ForegroundColor Green
    Write-Host "  Version: $existingVersion" -ForegroundColor Gray
    Write-Host "  Path: $localNinja" -ForegroundColor Gray
    Write-Host "`nNo installation needed.`n" -ForegroundColor Green
    exit 0
}

Write-Host "Installing Ninja $Version..." -ForegroundColor Yellow
Write-Host "Install location: $InstallPath`n" -ForegroundColor Gray

# Create install directory
if (-not (Test-Path $InstallPath)) {
    New-Item -ItemType Directory -Path $InstallPath | Out-Null
    Write-Host "✓ Created directory: $InstallPath" -ForegroundColor Green
}

# Download URL
$downloadUrl = "https://github.com/ninja-build/ninja/releases/download/v$Version/ninja-win.zip"
$zipPath = Join-Path $env:TEMP "ninja-$Version.zip"

Write-Host "Downloading Ninja from GitHub..." -ForegroundColor Yellow
Write-Host "  URL: $downloadUrl" -ForegroundColor Gray

try {
    $ProgressPreference = 'SilentlyContinue'
    Invoke-WebRequest -Uri $downloadUrl -OutFile $zipPath -UseBasicParsing
    $ProgressPreference = 'Continue'
    
    $fileSize = (Get-Item $zipPath).Length
    $fileSizeKB = [math]::Round($fileSize / 1KB, 2)
    Write-Host "✓ Downloaded successfully ($fileSizeKB KB)" -ForegroundColor Green
} catch {
    Write-Host "❌ Error downloading Ninja: $_" -ForegroundColor Red
    exit 1
}

Write-Host "`nExtracting Ninja..." -ForegroundColor Yellow

try {
    Expand-Archive -Path $zipPath -DestinationPath $InstallPath -Force
    Write-Host "✓ Extracted to: $InstallPath" -ForegroundColor Green
} catch {
    Write-Host "❌ Error extracting Ninja: $_" -ForegroundColor Red
    Remove-Item $zipPath -ErrorAction SilentlyContinue
    exit 1
}

# Cleanup
Remove-Item $zipPath -ErrorAction SilentlyContinue

# Verify installation
if (Test-Path $localNinja) {
    $installedVersion = & $localNinja --version 2>&1
    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "✓ Ninja Installed Successfully!" -ForegroundColor Green
    Write-Host "========================================`n" -ForegroundColor Cyan
    Write-Host "Version: $installedVersion" -ForegroundColor White
    Write-Host "Path: $localNinja" -ForegroundColor White
    
    Write-Host "`nUsage:" -ForegroundColor White
    Write-Host "  Ninja is now available for GLOMAP builds" -ForegroundColor Gray
    Write-Host "  The build scripts will automatically use it" -ForegroundColor Gray
    
    Write-Host "`nOptional: Add to PATH permanently:" -ForegroundColor White
    Write-Host "  `$env:PATH += ';$(Resolve-Path $InstallPath)'" -ForegroundColor Cyan
    Write-Host "  [Environment]::SetEnvironmentVariable('PATH', `$env:PATH, 'User')" -ForegroundColor Cyan
    
    Write-Host "`n========================================`n" -ForegroundColor Cyan
} else {
    Write-Host "`n❌ Installation failed - ninja.exe not found" -ForegroundColor Red
    exit 1
}

