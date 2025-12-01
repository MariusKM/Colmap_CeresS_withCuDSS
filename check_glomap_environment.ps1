# Check GLOMAP Build Environment
# Verifies prerequisites for building GLOMAP with GPU-enabled COLMAP

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "GLOMAP Environment Check" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

$allChecksPass = $true
$vcpkgRoot = ".\vcpkg"
$installedDir = "$vcpkgRoot\installed\x64-windows"

# Check 1: COLMAP Installation
Write-Host "Check 1: COLMAP Installation" -ForegroundColor Yellow
$colmapLibs = @(
    "$installedDir\lib\colmap_util.lib",
    "$installedDir\lib\colmap_scene.lib",
    "$installedDir\lib\colmap_feature.lib",
    "$installedDir\lib\colmap_sfm.lib"
)

$colmapFound = $true
foreach ($lib in $colmapLibs) {
    if (-not (Test-Path $lib)) {
        Write-Host "  ✗ Missing: $lib" -ForegroundColor Red
        $colmapFound = $false
    }
}

if ($colmapFound) {
    Write-Host "  ✓ COLMAP libraries found" -ForegroundColor Green
    Write-Host "    Location: $installedDir" -ForegroundColor Gray
} else {
    Write-Host "  ✗ COLMAP libraries not found" -ForegroundColor Red
    Write-Host "    Please ensure COLMAP is built first" -ForegroundColor Yellow
    $allChecksPass = $false
}

# Check 2: PoseLib Installation
Write-Host "`nCheck 2: PoseLib Installation" -ForegroundColor Yellow
$poselibLib = "$installedDir\lib\PoseLib.lib"
$poselibCMake = "$installedDir\share\poselib\PoseLibConfig.cmake"

if ((Test-Path $poselibLib) -and (Test-Path $poselibCMake)) {
    Write-Host "  ✓ PoseLib found" -ForegroundColor Green
    Write-Host "    Library: $poselibLib" -ForegroundColor Gray
    Write-Host "    CMake: $poselibCMake" -ForegroundColor Gray
} else {
    Write-Host "  ✗ PoseLib not found" -ForegroundColor Red
    Write-Host "    PoseLib is required for GLOMAP" -ForegroundColor Yellow
    $allChecksPass = $false
}

# Check 3: Ceres Solver (with GPU)
Write-Host "`nCheck 3: Ceres Solver with CUDA" -ForegroundColor Yellow
$ceresLib = "$installedDir\lib\ceres.lib"
$ceresCudaKernels = "$installedDir\lib\ceres_cuda_kernels.lib"

if ((Test-Path $ceresLib) -and (Test-Path $ceresCudaKernels)) {
    Write-Host "  ✓ Ceres with CUDA found" -ForegroundColor Green
    Write-Host "    GPU acceleration: Enabled" -ForegroundColor Green
} else {
    Write-Host "  ⚠ Ceres without CUDA kernels" -ForegroundColor Yellow
    Write-Host "    GPU acceleration may not be available" -ForegroundColor Yellow
}

# Check 4: CMake
Write-Host "`nCheck 4: CMake" -ForegroundColor Yellow
$vcpkgCMake = "$vcpkgRoot\downloads\tools\cmake-3.30.1-windows-i386\bin\cmake.exe"
$systemCMake = Get-Command cmake -ErrorAction SilentlyContinue

if (Test-Path $vcpkgCMake) {
    $cmakeVersion = & $vcpkgCMake --version 2>&1 | Select-String -Pattern "cmake version (\d+\.\d+\.\d+)" | ForEach-Object { $_.Matches.Groups[1].Value }
    Write-Host "  ✓ CMake found (vcpkg)" -ForegroundColor Green
    Write-Host "    Version: $cmakeVersion" -ForegroundColor Gray
    Write-Host "    Path: $vcpkgCMake" -ForegroundColor Gray
} elseif ($systemCMake) {
    $cmakeVersion = & cmake --version 2>&1 | Select-String -Pattern "cmake version (\d+\.\d+\.\d+)" | ForEach-Object { $_.Matches.Groups[1].Value }
    Write-Host "  ✓ CMake found (system)" -ForegroundColor Green
    Write-Host "    Version: $cmakeVersion" -ForegroundColor Gray
    Write-Host "    Path: $($systemCMake.Source)" -ForegroundColor Gray
} else {
    Write-Host "  ✗ CMake not found" -ForegroundColor Red
    $allChecksPass = $false
}

# Check 5: Ninja Build System
Write-Host "`nCheck 5: Ninja Build System" -ForegroundColor Yellow
$ninjaCmd = Get-Command ninja -ErrorAction SilentlyContinue
$localNinja = ".\ninja\ninja.exe"

if ($ninjaCmd) {
    $ninjaVersion = & ninja --version 2>&1
    Write-Host "  ✓ Ninja found (system)" -ForegroundColor Green
    Write-Host "    Version: $ninjaVersion" -ForegroundColor Gray
    Write-Host "    Path: $($ninjaCmd.Source)" -ForegroundColor Gray
} elseif (Test-Path $localNinja) {
    $ninjaVersion = & $localNinja --version 2>&1
    Write-Host "  ✓ Ninja found (local)" -ForegroundColor Green
    Write-Host "    Version: $ninjaVersion" -ForegroundColor Gray
    Write-Host "    Path: $localNinja" -ForegroundColor Gray
} else {
    Write-Host "  ⚠ Ninja not found" -ForegroundColor Yellow
    Write-Host "    Ninja is recommended for faster builds" -ForegroundColor Gray
    Write-Host "    Run .\install_ninja.ps1 to install" -ForegroundColor Cyan
    Write-Host "    Or GLOMAP will use MSBuild (slower)" -ForegroundColor Gray
}

# Check 6: Visual Studio / Build Tools
Write-Host "`nCheck 6: Visual Studio / Build Tools" -ForegroundColor Yellow
$vswhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"

if (Test-Path $vswhere) {
    $vsPath = & $vswhere -latest -property installationPath 2>$null
    if ($vsPath) {
        $vsVersion = & $vswhere -latest -property displayName 2>$null
        Write-Host "  ✓ Visual Studio found" -ForegroundColor Green
        Write-Host "    Version: $vsVersion" -ForegroundColor Gray
    } else {
        Write-Host "  ✗ Visual Studio not found" -ForegroundColor Red
        $allChecksPass = $false
    }
} else {
    Write-Host "  ✗ vswhere.exe not found" -ForegroundColor Red
    $allChecksPass = $false
}

# Check 7: CUDA (for reference)
Write-Host "`nCheck 7: CUDA Toolkit" -ForegroundColor Yellow
if ($env:CUDA_PATH) {
    $nvccPath = Join-Path $env:CUDA_PATH "bin\nvcc.exe"
    if (Test-Path $nvccPath) {
        $cudaVersion = & $nvccPath --version 2>&1 | Select-String -Pattern "release (\d+\.\d+)" | ForEach-Object { $_.Matches.Groups[1].Value }
        Write-Host "  ✓ CUDA Toolkit found" -ForegroundColor Green
        Write-Host "    Version: $cudaVersion" -ForegroundColor Gray
        Write-Host "    Path: $env:CUDA_PATH" -ForegroundColor Gray
    }
} else {
    Write-Host "  ℹ CUDA_PATH not set" -ForegroundColor Gray
    Write-Host "    (GPU support inherited from COLMAP/Ceres)" -ForegroundColor Gray
}

# Summary
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Environment Check Summary" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

if ($allChecksPass) {
    Write-Host "✓ All required components found" -ForegroundColor Green
    Write-Host "`nYou can proceed with:" -ForegroundColor White
    Write-Host "  1. .\clone_glomap.ps1     - Clone GLOMAP repository" -ForegroundColor Cyan
    Write-Host "  2. .\build_glomap.ps1     - Build GLOMAP with GPU support" -ForegroundColor Cyan
} else {
    Write-Host "✗ Some required components are missing" -ForegroundColor Red
    Write-Host "`nPlease install missing components before building GLOMAP" -ForegroundColor Yellow
}

Write-Host "`n========================================`n" -ForegroundColor Cyan

return $allChecksPass

