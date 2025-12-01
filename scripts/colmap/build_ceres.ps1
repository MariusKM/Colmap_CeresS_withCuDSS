# Build Ceres Solver with CUDA Support
# This script builds Ceres 2.3.0 with CUDA and cuDSS support using vcpkg

Write-Host "======================================" -ForegroundColor Cyan
Write-Host "Build Ceres Solver with CUDA" -ForegroundColor Cyan
Write-Host "======================================`n" -ForegroundColor Cyan

# Check and set CUDA_PATH if not already set
Write-Host "Checking CUDA environment..." -ForegroundColor Yellow
if (-not $env:CUDA_PATH) {
    Write-Host "⚠ CUDA_PATH not set, attempting to locate CUDA..." -ForegroundColor Yellow
    
    # Try to find nvcc
    try {
        $nvccPath = where.exe nvcc 2>$null | Select-Object -First 1
        if ($nvccPath) {
            # Extract CUDA root from nvcc path (remove \bin\nvcc.exe)
            $cudaRoot = Split-Path (Split-Path $nvccPath -Parent) -Parent
            $env:CUDA_PATH = $cudaRoot
            [System.Environment]::SetEnvironmentVariable('CUDA_PATH', $cudaRoot, [System.EnvironmentVariableTarget]::User)
            Write-Host "✓ CUDA_PATH set to: $cudaRoot" -ForegroundColor Green
            Write-Host "  (Saved permanently for future sessions)" -ForegroundColor Gray
        } else {
            Write-Host "❌ Error: CUDA not found. Please install CUDA 12.0+" -ForegroundColor Red
            Write-Host "Download from: https://developer.nvidia.com/cuda-downloads" -ForegroundColor Yellow
            exit 1
        }
    } catch {
        Write-Host "❌ Error: Could not locate CUDA installation" -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "✓ CUDA_PATH is set: $env:CUDA_PATH" -ForegroundColor Green
}

# Change to vcpkg directory
$vcpkgRoot = "..\..\vcpkg"

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

Write-Host "Starting Ceres build process..." -ForegroundColor Yellow
Write-Host "This may take 30-60 minutes depending on your system.`n" -ForegroundColor Yellow

# Step 1: Install abseil (dependency of Ceres)
Write-Host "Step 1/2: Installing abseil (dependency)..." -ForegroundColor Cyan
Write-Host "Command: .\vcpkg install abseil:x64-windows`n" -ForegroundColor Gray

try {
    $abseilStart = Get-Date
    & .\vcpkg install abseil:x64-windows
    
    if ($LASTEXITCODE -eq 0) {
        $abseilEnd = Get-Date
        $abseilDuration = ($abseilEnd - $abseilStart).ToString("mm\:ss")
        Write-Host "`n✓ abseil installed successfully (Duration: $abseilDuration)" -ForegroundColor Green
    } else {
        Write-Host "`n❌ Error: abseil installation failed with exit code $LASTEXITCODE" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "`n❌ Error during abseil installation: $_" -ForegroundColor Red
    exit 1
}

# Step 2: Install Ceres with CUDA support
Write-Host "`nStep 2/2: Installing Ceres with CUDA support..." -ForegroundColor Cyan
Write-Host "Command: .\vcpkg install ceres[core,cuda,lapack,suitesparse]:x64-windows --editable`n" -ForegroundColor Gray
Write-Host "⚠ This step will take a long time (30-60 minutes)..." -ForegroundColor Yellow
Write-Host "Features enabled: core, cuda, lapack, suitesparse`n" -ForegroundColor White

try {
    $ceresStart = Get-Date
    & .\vcpkg install ceres[core,cuda,lapack,suitesparse]:x64-windows --editable
    
    if ($LASTEXITCODE -eq 0) {
        $ceresEnd = Get-Date
        $ceresDuration = ($ceresEnd - $ceresStart).ToString("hh\:mm\:ss")
        Write-Host "`n✓ Ceres installed successfully (Duration: $ceresDuration)" -ForegroundColor Green
    } else {
        Write-Host "`n❌ Error: Ceres installation failed with exit code $LASTEXITCODE" -ForegroundColor Red
        Write-Host "`nPossible issues:" -ForegroundColor Yellow
        Write-Host "  1. cuDSS path may be incorrect in portfile.cmake" -ForegroundColor Yellow
        Write-Host "  2. CUDA not properly detected" -ForegroundColor Yellow
        Write-Host "  3. Visual Studio not found" -ForegroundColor Yellow
        Write-Host "`nCheck the error messages above for details." -ForegroundColor Yellow
        exit 1
    }
} catch {
    Write-Host "`n❌ Error during Ceres installation: $_" -ForegroundColor Red
    exit 1
}

Write-Host "`n======================================" -ForegroundColor Cyan
Write-Host "Ceres Build Complete!" -ForegroundColor Green
Write-Host "======================================" -ForegroundColor Cyan

# Check if Ceres was built successfully
$ceresPackagePath = ".\packages\ceres_x64-windows"
if (Test-Path $ceresPackagePath) {
    Write-Host "`n✓ Ceres package found at: $ceresPackagePath" -ForegroundColor Green
    
    # Check for CUDA-related files
    $cudaLib = Get-ChildItem -Path $ceresPackagePath -Recurse -Filter "*cuda*.lib" -ErrorAction SilentlyContinue
    if ($cudaLib) {
        Write-Host "✓ CUDA libraries detected in build" -ForegroundColor Green
    }
} else {
    Write-Host "`n⚠ Warning: Ceres package directory not found" -ForegroundColor Yellow
}

# Show source location for debugging
$ceresSource = ".\buildtrees\ceres\src"
if (Test-Path $ceresSource) {
    Write-Host "`nCeres source code available at:" -ForegroundColor Cyan
    Write-Host "  $ceresSource" -ForegroundColor White
    Write-Host "  (--editable flag keeps source for debugging)" -ForegroundColor Gray
}

Write-Host "`nNext Steps:" -ForegroundColor Cyan
Write-Host "1. Run .\build_colmap_initial.ps1 to start COLMAP build" -ForegroundColor White
Write-Host "2. Follow the manual steps to modify COLMAP's CMakeLists.txt" -ForegroundColor White
Write-Host "3. Run .\build_colmap_final.ps1 to complete COLMAP build" -ForegroundColor White

$totalEnd = Get-Date
Write-Host "`nScript completed at: $totalEnd" -ForegroundColor Gray

