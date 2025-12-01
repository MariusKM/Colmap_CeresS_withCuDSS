# Configure GLOMAP Build
# Sets up CMake configuration to use existing GPU-enabled COLMAP

param(
    [string]$SourceDir = "..\..\glomap",
    [string]$BuildDir = "..\..\glomap\build",
    [string]$InstallDir = "..\..\glomap\install"
)

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Configure GLOMAP Build" -ForegroundColor Cyan
Write-Host "With GPU-enabled COLMAP 3.13.0" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# Check if source directory exists
if (-not (Test-Path $SourceDir)) {
    Write-Host "❌ GLOMAP source directory not found: $SourceDir" -ForegroundColor Red
    Write-Host "Please run .\clone_glomap.ps1 first" -ForegroundColor Yellow
    exit 1
}

# Resolve absolute paths
$SourceDirAbs = (Resolve-Path $SourceDir).Path
$BuildDirAbs = Join-Path $SourceDirAbs "build"
$InstallDirAbs = Join-Path $SourceDirAbs "install"
$VcpkgRoot = (Resolve-Path "..\..\vcpkg").Path
$VcpkgInstalled = Join-Path $VcpkgRoot "installed\x64-windows"
$VcpkgToolchain = Join-Path $VcpkgRoot "scripts\buildsystems\vcpkg.cmake"

Write-Host "Configuration:" -ForegroundColor White
Write-Host "  Source: $SourceDirAbs" -ForegroundColor Gray
Write-Host "  Build: $BuildDirAbs" -ForegroundColor Gray
Write-Host "  Install: $InstallDirAbs" -ForegroundColor Gray
Write-Host "  COLMAP: $VcpkgInstalled" -ForegroundColor Gray

# Create build directory
if (Test-Path $BuildDirAbs) {
    Write-Host "`n⚠ Build directory exists - cleaning..." -ForegroundColor Yellow
    Remove-Item -Recurse -Force $BuildDirAbs
}
New-Item -ItemType Directory -Path $BuildDirAbs | Out-Null
Write-Host "✓ Build directory created" -ForegroundColor Green

# Find CMake
$vcpkgRootForCMake = (Get-Item "..\..\vcpkg").FullName
$cmakePaths = @(
    "$vcpkgRootForCMake\downloads\tools\cmake-3.30.1-windows\cmake-3.30.1-windows-i386\bin\cmake.exe",
    "$vcpkgRootForCMake\downloads\tools\cmake-3.30.1-windows-i386\bin\cmake.exe"
)

$cmakeExe = $null
foreach ($path in $cmakePaths) {
    if (Test-Path $path) {
        $cmakeExe = $path
        break
    }
}

if (-not $cmakeExe) {
    $systemCMake = Get-Command cmake -ErrorAction SilentlyContinue
    if ($systemCMake) {
        $cmakeExe = $systemCMake.Source
    }
}

if (-not $cmakeExe) {
    Write-Host "❌ CMake not found" -ForegroundColor Red
    exit 1
}

Write-Host "✓ Using CMake: $(Split-Path $cmakeExe -Leaf)" -ForegroundColor Green

# Find Ninja or use MSBuild
$ninjaCmd = Get-Command ninja -ErrorAction SilentlyContinue
$localNinja = "..\..\ninja\ninja.exe"

# Check if we're in a Visual Studio environment
$vsEnvInitialized = $env:VCINSTALLDIR -or $env:VisualStudioVersion

if ($ninjaCmd) {
    if (-not $vsEnvInitialized) {
        Write-Host "⚠ Ninja found but Visual Studio environment not initialized" -ForegroundColor Yellow
        Write-Host "  Using MSBuild instead for better compatibility" -ForegroundColor Yellow
        $generator = "Visual Studio 17 2022"
        $generateArch = "-A", "x64"
    } else {
        $generator = "Ninja"
        $generateArch = @()
        Write-Host "✓ Using system Ninja with VS environment" -ForegroundColor Green
    }
} elseif (Test-Path $localNinja) {
    if (-not $vsEnvInitialized) {
        Write-Host "⚠ Local Ninja found but Visual Studio environment not initialized" -ForegroundColor Yellow
        Write-Host "  Using MSBuild instead for better compatibility" -ForegroundColor Yellow
        $generator = "Visual Studio 17 2022"
        $generateArch = "-A", "x64"
    } else {
        $generator = "Ninja"
        $generateArch = @()
        $env:PATH = "$(Resolve-Path '..\..\ninja');$env:PATH"
        Write-Host "✓ Using local Ninja with VS environment" -ForegroundColor Green
    }
} else {
    $generator = "Visual Studio 17 2022"
    $generateArch = "-A", "x64"
    Write-Host "✓ Using MSBuild (Visual Studio generator)" -ForegroundColor Green
}

Write-Host "`nCMake Configuration:" -ForegroundColor White
Write-Host "  Generator: $generator" -ForegroundColor Gray
Write-Host "  Toolchain: vcpkg" -ForegroundColor Gray
Write-Host "  FETCH_COLMAP: ON (downloading compatible version)" -ForegroundColor Cyan
Write-Host "  FETCH_POSELIB: ON (downloading with COLMAP)" -ForegroundColor Cyan
Write-Host "  Using GPU-enabled Ceres from vcpkg" -ForegroundColor Green

# Convert paths to CMake-friendly format (forward slashes)
$VcpkgInstalledCmake = $VcpkgInstalled.Replace('\', '/')
$InstallDirCmake = $InstallDirAbs.Replace('\', '/')
$VcpkgToolchainCmake = $VcpkgToolchain.Replace('\', '/')

# Prepare CMake arguments
$cmakeArgs = @(
    "-S", $SourceDirAbs,
    "-B", $BuildDirAbs,
    "-G", $generator
) + $generateArch + @(
    "-DCMAKE_BUILD_TYPE=Release",
    "-DCMAKE_INSTALL_PREFIX=$InstallDirCmake",
    "-DCMAKE_TOOLCHAIN_FILE=$VcpkgToolchainCmake",
    "-DCMAKE_PREFIX_PATH=$VcpkgInstalledCmake;C:/NVIDIA_cuDSS/v0.7",
    "-DCMAKE_MODULE_PATH=$VcpkgInstalledCmake/share/jxr",
    "-DVCPKG_MANIFEST_MODE=OFF",
    "-DVCPKG_INSTALLED_DIR=$VcpkgInstalledCmake",
    "-DFETCH_COLMAP=ON",
    "-DFETCH_POSELIB=ON",
    "-Dcudss_DIR=C:/NVIDIA_cuDSS/v0.7/lib/12/cmake/cudss",
    "-DCUDA_ENABLED=ON",
    "-DCMAKE_CUDA_ARCHITECTURES=native"
)

Write-Host "`nRunning CMake configuration..." -ForegroundColor Yellow
Write-Host "This may take a few minutes...`n" -ForegroundColor Gray

try {
    Push-Location $BuildDirAbs
    
    $output = & $cmakeExe @cmakeArgs 2>&1
    $exitCode = $LASTEXITCODE
    
    Pop-Location
    
    if ($exitCode -eq 0) {
        Write-Host "`n========================================" -ForegroundColor Cyan
        Write-Host "✓ Configuration Successful!" -ForegroundColor Green
        Write-Host "========================================`n" -ForegroundColor Cyan
        
        Write-Host "Build directory: $BuildDirAbs" -ForegroundColor White
        Write-Host "Install prefix: $InstallDirAbs" -ForegroundColor White
        
        Write-Host "`nKey Settings:" -ForegroundColor White
        Write-Host "  ✓ GLOMAP will fetch compatible COLMAP version" -ForegroundColor Green
        Write-Host "  ✓ That COLMAP will use GPU-enabled Ceres 2.3.0" -ForegroundColor Green
        Write-Host "  ✓ cuDSS support enabled" -ForegroundColor Green
        Write-Host "  ✓ GPU acceleration enabled" -ForegroundColor Green
        
        Write-Host "`nNext Steps:" -ForegroundColor White
        Write-Host "  1. Build: Continue to next step (automatic)" -ForegroundColor Gray
        Write-Host "  2. Or run manually: cd $BuildDirAbs; ninja; ninja install" -ForegroundColor Cyan
        
        Write-Host "`n========================================`n" -ForegroundColor Cyan
        
        return $true
    } else {
        Write-Host "`n❌ Configuration Failed" -ForegroundColor Red
        Write-Host "`nCMake Output:" -ForegroundColor Yellow
        Write-Host $output -ForegroundColor Gray
        Write-Host "`nPlease check the error messages above" -ForegroundColor Yellow
        return $false
    }
} catch {
    Write-Host "❌ Error running CMake: $_" -ForegroundColor Red
    Pop-Location
    return $false
}

