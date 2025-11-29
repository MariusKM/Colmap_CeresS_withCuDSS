# Configure vcpkg Ceres for CUDA Build
# This script updates the vcpkg Ceres configuration files with your cuDSS path

param(
    [Parameter(Mandatory=$true)]
    [string]$CuDSSPath
)

Write-Host "======================================" -ForegroundColor Cyan
Write-Host "vcpkg Ceres Configuration Script" -ForegroundColor Cyan
Write-Host "======================================`n" -ForegroundColor Cyan

# Validate cuDSS path
$CuDSSPathFormatted = $CuDSSPath -replace '\\', '/'
Write-Host "cuDSS CMake Path: $CuDSSPathFormatted" -ForegroundColor Yellow

# Paths
$vcpkgRoot = "E:\Programs\Gaussians\colmap_Ceres_2.3\vcpkg"
$ceresVcpkgJson = "$vcpkgRoot\ports\ceres\vcpkg.json"
$ceresPortfile = "$vcpkgRoot\ports\ceres\portfile.cmake"
$portfileSource = "E:\Programs\Gaussians\colmap_Ceres_2.3\Docs\portfilecmake.txt"

# Check if vcpkg exists
if (-not (Test-Path $vcpkgRoot)) {
    Write-Host "❌ Error: vcpkg not found at $vcpkgRoot" -ForegroundColor Red
    Write-Host "Please run the environment setup first." -ForegroundColor Red
    exit 1
}

# Step 1: Update vcpkg.json version
Write-Host "`n1. Updating Ceres version in vcpkg.json..." -ForegroundColor Yellow

if (Test-Path $ceresVcpkgJson) {
    try {
        # Backup original file
        $backupPath = "$ceresVcpkgJson.backup"
        if (-not (Test-Path $backupPath)) {
            Copy-Item $ceresVcpkgJson $backupPath
            Write-Host "   ✓ Backup created: $backupPath" -ForegroundColor Green
        }
        
        # Read and update JSON
        $jsonContent = Get-Content $ceresVcpkgJson -Raw | ConvertFrom-Json
        $oldVersion = $jsonContent.version
        $jsonContent.version = "2.3.0"
        
        # Write back to file
        $jsonContent | ConvertTo-Json -Depth 10 | Set-Content $ceresVcpkgJson
        
        Write-Host "   ✓ Updated version: $oldVersion -> 2.3.0" -ForegroundColor Green
    } catch {
        Write-Host "   ❌ Error updating vcpkg.json: $_" -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "   ❌ Error: vcpkg.json not found at $ceresVcpkgJson" -ForegroundColor Red
    exit 1
}

# Step 2: Update portfile.cmake
Write-Host "`n2. Updating Ceres portfile.cmake..." -ForegroundColor Yellow

if (Test-Path $portfileSource) {
    try {
        # Backup original file
        $backupPath = "$ceresPortfile.backup"
        if (-not (Test-Path $backupPath)) {
            Copy-Item $ceresPortfile $backupPath
            Write-Host "   ✓ Backup created: $backupPath" -ForegroundColor Green
        }
        
        # Read the source portfile
        $portfileContent = Get-Content $portfileSource -Raw
        
        # Replace the cuDSS paths - look for the template path in set(CUDSS_CMAKE_PATH "...") line
        $portfileContent = $portfileContent -replace 'C:/Users/owner/Desktop/NVIDIA_cuDSS/v0.4/lib/12/cmake/cudss', $CuDSSPathFormatted
        
        # Write to destination
        $portfileContent | Set-Content $ceresPortfile -NoNewline
        
        Write-Host "   ✓ Portfile updated with cuDSS path" -ForegroundColor Green
        Write-Host "   Path: $CuDSSPathFormatted" -ForegroundColor White
    } catch {
        Write-Host "   ❌ Error updating portfile.cmake: $_" -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "   ❌ Error: Source portfile not found at $portfileSource" -ForegroundColor Red
    exit 1
}

# Step 3: Verify changes
Write-Host "`n3. Verifying changes..." -ForegroundColor Yellow

try {
    # Check vcpkg.json
    $jsonContent = Get-Content $ceresVcpkgJson -Raw | ConvertFrom-Json
    if ($jsonContent.version -eq "2.3.0") {
        Write-Host "   ✓ vcpkg.json version is 2.3.0" -ForegroundColor Green
    } else {
        Write-Host "   ❌ vcpkg.json version verification failed" -ForegroundColor Red
    }
    
    # Check portfile.cmake contains the cuDSS path
    $portfileContent = Get-Content $ceresPortfile -Raw
    if ($portfileContent -match [regex]::Escape($CuDSSPathFormatted)) {
        Write-Host "   ✓ portfile.cmake contains your cuDSS path" -ForegroundColor Green
    } else {
        Write-Host "   ⚠ Warning: Could not verify cuDSS path in portfile.cmake" -ForegroundColor Yellow
    }
} catch {
    Write-Host "   ⚠ Warning: Verification failed: $_" -ForegroundColor Yellow
}

Write-Host "`n======================================" -ForegroundColor Cyan
Write-Host "✓ Configuration Complete!" -ForegroundColor Green
Write-Host "======================================" -ForegroundColor Cyan

Write-Host "`nNext Steps:" -ForegroundColor Cyan
Write-Host "1. Run .\build_ceres.ps1 to build Ceres with CUDA support" -ForegroundColor White
Write-Host "2. After Ceres builds, run .\build_colmap_initial.ps1" -ForegroundColor White

Write-Host "`nBackup files created:" -ForegroundColor Yellow
Write-Host "  - $ceresVcpkgJson.backup" -ForegroundColor Gray
Write-Host "  - $ceresPortfile.backup" -ForegroundColor Gray

