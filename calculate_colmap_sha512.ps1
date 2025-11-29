# Calculate SHA512 Hash for COLMAP Source Archive
# This script downloads the COLMAP source tarball and calculates its SHA512 hash
# Required for vcpkg portfile configuration

param(
    [string]$CommitHash = "0b31f98133b470eae62811b557dc2bcff1e4f9a5",
    [string]$Version = "3.13.0"
)

Write-Host "======================================" -ForegroundColor Cyan
Write-Host "COLMAP SHA512 Hash Calculator" -ForegroundColor Cyan
Write-Host "======================================`n" -ForegroundColor Cyan

Write-Host "Version: $Version" -ForegroundColor White
Write-Host "Commit:  $CommitHash`n" -ForegroundColor White

# Create temporary directory
$tempDir = Join-Path $env:TEMP "colmap_hash_calc"
if (Test-Path $tempDir) {
    Remove-Item -Recurse -Force $tempDir
}
New-Item -ItemType Directory -Path $tempDir | Out-Null

$downloadUrl = "https://github.com/colmap/colmap/archive/${Version}.tar.gz"
$tarballPath = Join-Path $tempDir "colmap-${CommitHash}.tar.gz"

Write-Host "Download URL: $downloadUrl" -ForegroundColor Gray
Write-Host "Temporary file: $tarballPath`n" -ForegroundColor Gray

Write-Host "Downloading COLMAP source archive..." -ForegroundColor Yellow

try {
    # Download the file
    $ProgressPreference = 'SilentlyContinue'  # Speed up download
    Invoke-WebRequest -Uri $downloadUrl -OutFile $tarballPath -UseBasicParsing
    $ProgressPreference = 'Continue'
    
    if (-not (Test-Path $tarballPath)) {
        throw "Download failed - file not found at $tarballPath"
    }
    
    $fileSize = (Get-Item $tarballPath).Length
    $fileSizeMB = [math]::Round($fileSize / 1MB, 2)
    Write-Host "✓ Downloaded successfully ($fileSizeMB MB)" -ForegroundColor Green
    
} catch {
    Write-Host "❌ Error downloading file: $_" -ForegroundColor Red
    Remove-Item -Recurse -Force $tempDir -ErrorAction SilentlyContinue
    exit 1
}

Write-Host "`nCalculating SHA512 hash..." -ForegroundColor Yellow
Write-Host "(This may take a minute for large files)" -ForegroundColor Gray

try {
    # Calculate SHA512 hash
    $hash = Get-FileHash -Path $tarballPath -Algorithm SHA512
    $sha512 = $hash.Hash.ToLower()
    
    Write-Host "`n✓ SHA512 hash calculated successfully!" -ForegroundColor Green
    
    Write-Host "`n======================================" -ForegroundColor Cyan
    Write-Host "RESULT" -ForegroundColor Cyan
    Write-Host "======================================`n" -ForegroundColor Cyan
    
    Write-Host "SHA512 Hash:" -ForegroundColor White
    Write-Host $sha512 -ForegroundColor Yellow
    
    Write-Host "`n======================================" -ForegroundColor Cyan
    Write-Host "Configuration Updates Required" -ForegroundColor Cyan
    Write-Host "======================================`n" -ForegroundColor Cyan
    
    Write-Host "File: vcpkg/ports/colmap/portfile.cmake" -ForegroundColor White
    Write-Host "Line 2: " -ForegroundColor Gray -NoNewline
    Write-Host "set(COLMAP_REF $Version `"$CommitHash`")" -ForegroundColor Cyan
    Write-Host "Line 8: " -ForegroundColor Gray -NoNewline
    Write-Host "SHA512 $sha512" -ForegroundColor Cyan
    
    Write-Host "`nFile: vcpkg/ports/colmap/vcpkg.json" -ForegroundColor White
    Write-Host "Line 3: " -ForegroundColor Gray -NoNewline
    Write-Host "`"version`": `"$Version`"," -ForegroundColor Cyan
    
    # Save to file for later use
    $resultFile = "colmap_${Version}_sha512.txt"
    @"
COLMAP Version: $Version
Commit Hash: $CommitHash
SHA512: $sha512

Configuration for vcpkg/ports/colmap/portfile.cmake:
Line 2: set(COLMAP_REF $Version "$CommitHash")
Line 8: SHA512 $sha512

Configuration for vcpkg/ports/colmap/vcpkg.json:
Line 3: "version": "$Version",
"@ | Out-File -FilePath $resultFile -Encoding UTF8
    
    Write-Host "`n✓ Results saved to: $resultFile" -ForegroundColor Green
    
    # Return the hash for use in other scripts
    return $sha512
    
} catch {
    Write-Host "❌ Error calculating hash: $_" -ForegroundColor Red
    exit 1
} finally {
    # Cleanup
    Write-Host "`nCleaning up temporary files..." -ForegroundColor Gray
    Remove-Item -Recurse -Force $tempDir -ErrorAction SilentlyContinue
    Write-Host "✓ Cleanup complete`n" -ForegroundColor Green
}

Write-Host "======================================`n" -ForegroundColor Cyan

