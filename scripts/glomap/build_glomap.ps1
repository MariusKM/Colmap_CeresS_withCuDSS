# Build GLOMAP with GPU-enabled COLMAP
# Complete build process including configuration, compilation, and installation

param(
    [switch]$SkipConfiguration = $false,
    [switch]$Clean = $false
)

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Build GLOMAP" -ForegroundColor Cyan
Write-Host "With GPU-enabled COLMAP 3.13.0 + Ceres 2.3.0" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

$startTime = Get-Date

# Check prerequisites
if (-not (Test-Path "..\..\glomap")) {
    Write-Host "❌ GLOMAP source not found" -ForegroundColor Red
    Write-Host "Please run .\clone_glomap.ps1 first" -ForegroundColor Yellow
    exit 1
}

$buildDir = "..\..\glomap\build"
$installDir = "..\..\glomap\install"

# Clean if requested
if ($Clean -and (Test-Path $buildDir)) {
    Write-Host "Cleaning previous build..." -ForegroundColor Yellow
    Remove-Item -Recurse -Force $buildDir
    Remove-Item -Recurse -Force $installDir -ErrorAction SilentlyContinue
    Write-Host "✓ Cleaned" -ForegroundColor Green
    Write-Host ""
}

# Step 1: Configuration
if (-not $SkipConfiguration) {
    Write-Host "Step 1/3: Configuration" -ForegroundColor Yellow
    Write-Host "========================================`n" -ForegroundColor Gray
    
    $configResult = & ".\configure_glomap.ps1"
    
    if (-not $?) {
        Write-Host "`n❌ Configuration failed" -ForegroundColor Red
        exit 1
    }
    
    # Patch FetchContent COLMAP source for JXR and gflags
    $colmapFindDeps = "..\..\glomap\build\_deps\colmap-src\cmake\FindDependencies.cmake"
    if (Test-Path $colmapFindDeps) {
        Write-Host "`nPatching fetched COLMAP source..." -ForegroundColor Cyan
        $content = Get-Content $colmapFindDeps -Raw
        if ($content -notmatch "CMAKE_MODULE_PATH.*jxr") {
            $vcpkgPath = (Resolve-Path "..\..\vcpkg\installed\x64-windows\share\jxr").Path.Replace('\', '/')
            $patch = @"
if(COLMAP_FIND_QUIETLY)
    set(COLMAP_FIND_TYPE QUIET)
else()
    set(COLMAP_FIND_TYPE REQUIRED)
endif()

if(CMAKE_VERSION VERSION_GREATER_EQUAL "3.30")
    cmake_policy(SET CMP0167 NEW)
endif()

# Add JXR module path for finding JXR via Find module  
list(APPEND CMAKE_MODULE_PATH "$vcpkgPath")

# Find gflags which is required by glog
set(GFLAGS_USE_TARGET_NAMESPACE TRUE)
find_package(gflags CONFIG QUIET)
"@
            $content = $content -replace "if\(COLMAP_FIND_QUIETLY\)\s+set\(COLMAP_FIND_TYPE QUIET\)\s+else\(\)\s+set\(COLMAP_FIND_TYPE REQUIRED\)\s+endif\(\)\s+if\(CMAKE_VERSION VERSION_GREATER_EQUAL ""3\.30""\)\s+cmake_policy\(SET CMP0167 NEW\)\s+endif\(\)", $patch
            Set-Content -Path $colmapFindDeps -Value $content
            Write-Host "✓ COLMAP source patched" -ForegroundColor Green
        } else {
            Write-Host "✓ COLMAP source already patched" -ForegroundColor Green
        }
    }
    
    Write-Host ""
} else {
    Write-Host "Skipping configuration (using existing)`n" -ForegroundColor Gray
}

# Step 2: Build
Write-Host "Step 2/3: Compilation" -ForegroundColor Yellow
Write-Host "========================================`n" -ForegroundColor Gray

if (-not (Test-Path $buildDir)) {
    Write-Host "❌ Build directory not found" -ForegroundColor Red
    Write-Host "Configuration may have failed. Try running without -SkipConfiguration" -ForegroundColor Yellow
    exit 1
}

# Determine build command
$slnFile = Get-ChildItem -Path $buildDir -Filter "*.sln" -ErrorAction SilentlyContinue | Select-Object -First 1

# Find CMake for building
$vcpkgRoot = Resolve-Path "..\..\vcpkg"
$cmakePaths = @(
    "$vcpkgRoot\downloads\tools\cmake-3.30.1-windows\cmake-3.30.1-windows-i386\bin\cmake.exe",
    "$vcpkgRoot\downloads\tools\cmake-3.30.1-windows-i386\bin\cmake.exe"
)

$cmakeExe = $null
foreach ($path in $cmakePaths) {
    if (Test-Path $path) {
        $cmakeExe = $path
        break
    }
}

if (-not $cmakeExe) {
    $cmakeExe = Get-Command cmake -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source
}

if (-not $cmakeExe) {
    Write-Host "❌ CMake not found" -ForegroundColor Red
    exit 1
}

Write-Host "✓ Using CMake: $cmakeExe" -ForegroundColor Green

Push-Location $buildDir

try {
    if ($slnFile) {
        # Visual Studio generator was used - use CMake to build
        Write-Host "Building with MSBuild..." -ForegroundColor Yellow
        Write-Host "This may take 15-30 minutes...`n" -ForegroundColor Gray
        
        $buildOutput = & $cmakeExe --build . --config Release 2>&1
        $buildExitCode = $LASTEXITCODE
        
    } elseif (Test-Path "build.ninja") {
        # Ninja generator was used - use Ninja
        $ninjaCmd = Get-Command ninja -ErrorAction SilentlyContinue
        $localNinja = "..\..\ninja\ninja.exe"
        $buildCmd = if ($ninjaCmd) { "ninja" } elseif (Test-Path $localNinja) { (Resolve-Path $localNinja) } else { $null }
        
        if ($buildCmd) {
            Write-Host "Building with Ninja..." -ForegroundColor Yellow
            Write-Host "This may take 5-15 minutes...`n" -ForegroundColor Gray
            
            $buildOutput = & $buildCmd 2>&1
            $buildExitCode = $LASTEXITCODE
        } else {
            Write-Host "❌ Ninja build files found but Ninja is not available" -ForegroundColor Red
            exit 1
        }
    } else {
        Write-Host "❌ No build files found (neither .sln nor build.ninja)" -ForegroundColor Red
        exit 1
    }
    
    if ($buildExitCode -ne 0) {
        Write-Host "`n❌ Build failed" -ForegroundColor Red
        Write-Host "`nBuild output:" -ForegroundColor Yellow
        Write-Host $buildOutput -ForegroundColor Gray
        Pop-Location
        exit 1
    }
    
    Write-Host "`n✓ Build successful" -ForegroundColor Green
    
} catch {
    Write-Host "`n❌ Build error: $_" -ForegroundColor Red
    Pop-Location
    exit 1
}

Pop-Location

# Step 3: Installation
Write-Host "`nStep 3/3: Installation" -ForegroundColor Yellow
Write-Host "========================================`n" -ForegroundColor Gray

Push-Location $buildDir

try {
    if ($slnFile) {
        # Use CMake to install Visual Studio build
        $installOutput = & $cmakeExe --install . --config Release 2>&1
    } elseif (Test-Path "build.ninja") {
        # Use Ninja to install
        $ninjaCmd = Get-Command ninja -ErrorAction SilentlyContinue
        $localNinja = "..\..\ninja\ninja.exe"
        $buildCmd = if ($ninjaCmd) { "ninja" } elseif (Test-Path $localNinja) { (Resolve-Path $localNinja) } else { $null }
        
        if ($buildCmd) {
            $installOutput = & $buildCmd install 2>&1
        } else {
            Write-Host "❌ Cannot install - Ninja not found" -ForegroundColor Red
            Pop-Location
            exit 1
        }
    } else {
        Write-Host "❌ No build files found" -ForegroundColor Red
        Pop-Location
        exit 1
    }
    
    $installExitCode = $LASTEXITCODE
    
    if ($installExitCode -ne 0) {
        Write-Host "⚠ Installation had warnings" -ForegroundColor Yellow
    } else {
        Write-Host "✓ Installation successful" -ForegroundColor Green
    }
    
} catch {
    Write-Host "⚠ Installation warning: $_" -ForegroundColor Yellow
}

Pop-Location

# Calculate build time
$endTime = Get-Date
$duration = $endTime - $startTime
$minutes = [math]::Floor($duration.TotalMinutes)
$seconds = $duration.Seconds

# Verify installation
$glomapExe = Join-Path $installDir "bin\glomap.exe"
if (Test-Path $glomapExe) {
    $exeSize = (Get-Item $glomapExe).Length
    $exeSizeMB = [math]::Round($exeSize / 1MB, 2)
    
    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "✓ GLOMAP Build Complete!" -ForegroundColor Green
    Write-Host "========================================`n" -ForegroundColor Cyan
    
    Write-Host "Build Time: $minutes minutes, $seconds seconds" -ForegroundColor White
    Write-Host "Executable: $glomapExe" -ForegroundColor White
    Write-Host "Size: $exeSizeMB MB" -ForegroundColor White
    
    Write-Host "`nFeatures:" -ForegroundColor White
    Write-Host "  ✓ GPU-enabled COLMAP 3.13.0 integration" -ForegroundColor Green
    Write-Host "  ✓ Ceres 2.3.0 with CUDA + cuDSS support" -ForegroundColor Green
    Write-Host "  ✓ GPU-accelerated bundle adjustment" -ForegroundColor Green
    
    Write-Host "`nNext Steps:" -ForegroundColor White
    Write-Host "  1. Test: .\test_glomap.ps1" -ForegroundColor Cyan
    Write-Host "  2. Run: $glomapExe mapper --help" -ForegroundColor Cyan
    
    Write-Host "`n========================================`n" -ForegroundColor Cyan
    
} else {
    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "⚠ Build completed but executable not found" -ForegroundColor Yellow
    Write-Host "========================================`n" -ForegroundColor Cyan
    
    Write-Host "Build Time: $minutes minutes, $seconds seconds" -ForegroundColor White
    Write-Host "Expected location: $glomapExe" -ForegroundColor White
    
    Write-Host "`nPlease check:" -ForegroundColor Yellow
    Write-Host "  - Build output above for errors" -ForegroundColor Gray
    Write-Host "  - $buildDir for build artifacts" -ForegroundColor Gray
    
    Write-Host "`n========================================`n" -ForegroundColor Cyan
}

