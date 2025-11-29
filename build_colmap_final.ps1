# Build COLMAP with CUDA Support - Final Build
# This script performs the final COLMAP build after CMakeLists.txt has been modified

Write-Host "======================================" -ForegroundColor Cyan
Write-Host "Build COLMAP with CUDA - Final Build" -ForegroundColor Cyan
Write-Host "======================================`n" -ForegroundColor Cyan

# Change to vcpkg directory
$vcpkgRoot = "E:\Programs\Gaussians\colmap_Ceres_2.3\vcpkg"

if (-not (Test-Path $vcpkgRoot)) {
    Write-Host "❌ Error: vcpkg not found at $vcpkgRoot" -ForegroundColor Red
    exit 1
}

Set-Location $vcpkgRoot

# Check if vcpkg.exe exists
if (-not (Test-Path ".\vcpkg.exe")) {
    Write-Host "❌ Error: vcpkg.exe not found. Please run bootstrap-vcpkg.bat first." -ForegroundColor Red
    exit 1
}

# Verify CMakeLists.txt was modified
Write-Host "Checking if COLMAP CMakeLists.txt was modified..." -ForegroundColor Yellow

$colmapSourceBase = ".\buildtrees\colmap\src"
$cmakeListsFound = $false
$cudssConfigured = $false

if (Test-Path $colmapSourceBase) {
    $colmapSourceDirs = Get-ChildItem -Path $colmapSourceBase -Directory
    
    foreach ($dir in $colmapSourceDirs) {
        $cmakeListsPath = Join-Path $dir.FullName "CMakeLists.txt"
        if (Test-Path $cmakeListsPath) {
            $cmakeListsFound = $true
            $content = Get-Content $cmakeListsPath -Raw
            
            if ($content -match "set\(cudss_DIR") {
                $cudssConfigured = $true
                Write-Host "✓ CMakeLists.txt found and cudss_DIR is configured" -ForegroundColor Green
                
                # Extract and display the path
                if ($content -match 'set\(cudss_DIR\s+"([^"]+)"\)') {
                    $configuredPath = $matches[1]
                    Write-Host "  cuDSS path: $configuredPath" -ForegroundColor White
                }
            } else {
                Write-Host "⚠ Warning: cudss_DIR not found in CMakeLists.txt" -ForegroundColor Yellow
                Write-Host "  Location: $cmakeListsPath" -ForegroundColor Gray
            }
            break
        }
    }
}

if (-not $cmakeListsFound) {
    Write-Host "❌ Error: COLMAP CMakeLists.txt not found" -ForegroundColor Red
    Write-Host "Please run .\build_colmap_initial.ps1 first" -ForegroundColor Red
    exit 1
}

if (-not $cudssConfigured) {
    Write-Host "`n⚠ WARNING: cudss_DIR not configured in CMakeLists.txt" -ForegroundColor Yellow
    Write-Host "`nThe build may fail without this configuration." -ForegroundColor Yellow
    Write-Host "Do you want to continue anyway? (y/N): " -ForegroundColor Yellow -NoNewline
    
    $response = Read-Host
    if ($response -ne "y" -and $response -ne "Y") {
        Write-Host "`nBuild cancelled. Please configure CMakeLists.txt first." -ForegroundColor Red
        Write-Host "Use: .\edit_colmap_cmake.ps1 -CuDSSPath YOUR_PATH" -ForegroundColor Cyan
        exit 1
    }
}

Write-Host "`nStarting COLMAP final build..." -ForegroundColor Yellow
Write-Host "This may take 45-90 minutes depending on your system.`n" -ForegroundColor Yellow

Write-Host "Command: .\vcpkg install colmap[cuda]:x64-windows --editable`n" -ForegroundColor Gray

$colmapStart = Get-Date

try {
    & .\vcpkg install colmap[cuda]:x64-windows --editable
    
    if ($LASTEXITCODE -eq 0) {
        $colmapEnd = Get-Date
        $colmapDuration = ($colmapEnd - $colmapStart).ToString("hh\:mm\:ss")
        Write-Host "`n✓ COLMAP build completed successfully! (Duration: $colmapDuration)" -ForegroundColor Green
    } else {
        Write-Host "`n❌ Error: COLMAP build failed with exit code $LASTEXITCODE" -ForegroundColor Red
        Write-Host "`nPossible issues:" -ForegroundColor Yellow
        Write-Host "  1. cuDSS path may be incorrect in CMakeLists.txt" -ForegroundColor Yellow
        Write-Host "  2. Ceres was not built with CUDA support" -ForegroundColor Yellow
        Write-Host "  3. CUDA not properly detected" -ForegroundColor Yellow
        Write-Host "`nCheck the error messages above for details." -ForegroundColor Yellow
        exit 1
    }
} catch {
    Write-Host "`n❌ Error during COLMAP build: $_" -ForegroundColor Red
    exit 1
}

Write-Host "`n======================================" -ForegroundColor Cyan
Write-Host "COLMAP Build Complete!" -ForegroundColor Green
Write-Host "======================================" -ForegroundColor Cyan

# Verify COLMAP executable
$colmapExePath = ".\packages\colmap_x64-windows\tools\colmap\colmap.exe"
if (Test-Path $colmapExePath) {
    Write-Host "`n✓ COLMAP executable found at:" -ForegroundColor Green
    Write-Host "  $colmapExePath" -ForegroundColor White
    
    # Get file info
    $colmapExe = Get-Item $colmapExePath
    $fileSize = [math]::Round($colmapExe.Length / 1MB, 2)
    Write-Host "  Size: $fileSize MB" -ForegroundColor Gray
    Write-Host "  Modified: $($colmapExe.LastWriteTime)" -ForegroundColor Gray
} else {
    Write-Host "`n⚠ Warning: COLMAP executable not found at expected location" -ForegroundColor Yellow
    Write-Host "  Expected: $colmapExePath" -ForegroundColor Gray
}

# Check COLMAP package
$colmapPackage = ".\packages\colmap_x64-windows"
if (Test-Path $colmapPackage) {
    Write-Host "`n✓ COLMAP package directory found" -ForegroundColor Green
    
    # List some key directories
    $binDir = Join-Path $colmapPackage "bin"
    $toolsDir = Join-Path $colmapPackage "tools"
    
    if (Test-Path $binDir) {
        $binFiles = Get-ChildItem $binDir -File | Measure-Object
        Write-Host "  Binary files: $($binFiles.Count)" -ForegroundColor Gray
    }
}

Write-Host "`n======================================" -ForegroundColor Cyan
Write-Host "Next Steps" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan

Write-Host "`n1. Test the GPU-enabled COLMAP:" -ForegroundColor White
Write-Host "   cd E:\Programs\Gaussians\colmap_Ceres_2.3" -ForegroundColor Cyan
Write-Host "   .\test_colmap_gpu.ps1" -ForegroundColor Cyan

Write-Host "`n2. Or manually test:" -ForegroundColor White
Write-Host "   & '$colmapExePath' -h" -ForegroundColor Cyan

Write-Host "`n3. To verify GPU support, run bundle_adjuster with --BundleAdjustment.use_gpu=1" -ForegroundColor White

Write-Host "`n======================================`n" -ForegroundColor Cyan

$totalEnd = Get-Date
Write-Host "Build completed at: $totalEnd" -ForegroundColor Gray

