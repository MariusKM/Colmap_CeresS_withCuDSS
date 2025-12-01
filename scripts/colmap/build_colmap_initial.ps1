# Build COLMAP with CUDA Support - Initial Build
# This script performs the initial COLMAP build which will clone the source code

Write-Host "======================================" -ForegroundColor Cyan
Write-Host "Build COLMAP with CUDA - Initial Build" -ForegroundColor Cyan
Write-Host "======================================`n" -ForegroundColor Cyan

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

# Check if Ceres is installed
$ceresPackage = ".\packages\ceres_x64-windows"
if (-not (Test-Path $ceresPackage)) {
    Write-Host "❌ Error: Ceres package not found at $ceresPackage" -ForegroundColor Red
    Write-Host "Please run .\build_ceres.ps1 first to build Ceres with CUDA support." -ForegroundColor Red
    exit 1
}

Write-Host "✓ Ceres package found" -ForegroundColor Green
Write-Host "`nStarting COLMAP initial build..." -ForegroundColor Yellow
Write-Host "This may take 45-90 minutes depending on your system.`n" -ForegroundColor Yellow
Write-Host "⚠ Note: This initial build may fail or complete, either way is OK." -ForegroundColor Yellow
Write-Host "The purpose is to clone the COLMAP source code so we can modify CMakeLists.txt`n" -ForegroundColor Yellow

Write-Host "Command: .\vcpkg install colmap[cuda]:x64-windows --editable`n" -ForegroundColor Gray

$colmapStart = Get-Date

try {
    & .\vcpkg install colmap[cuda]:x64-windows --editable
    
    $exitCode = $LASTEXITCODE
    $colmapEnd = Get-Date
    $colmapDuration = ($colmapEnd - $colmapStart).ToString("hh\:mm\:ss")
    
    if ($exitCode -eq 0) {
        Write-Host "`n✓ COLMAP initial build completed successfully (Duration: $colmapDuration)" -ForegroundColor Green
    } else {
        Write-Host "`n⚠ Initial build exited with code $exitCode (Duration: $colmapDuration)" -ForegroundColor Yellow
        Write-Host "This is expected - we need to modify CMakeLists.txt and rebuild." -ForegroundColor Yellow
    }
} catch {
    Write-Host "`n⚠ Initial build encountered an error: $_" -ForegroundColor Yellow
    Write-Host "This may be expected - continuing with next steps..." -ForegroundColor Yellow
}

Write-Host "`n======================================" -ForegroundColor Cyan
Write-Host "Initial Build Phase Complete" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan

# Find COLMAP source directory
Write-Host "`nLooking for COLMAP source code..." -ForegroundColor Yellow

$colmapSourceBase = ".\buildtrees\colmap\src"
if (Test-Path $colmapSourceBase) {
    $colmapSourceDirs = Get-ChildItem -Path $colmapSourceBase -Directory
    
    if ($colmapSourceDirs) {
        Write-Host "✓ COLMAP source code found!" -ForegroundColor Green
        
        foreach ($dir in $colmapSourceDirs) {
            $cmakeListsPath = Join-Path $dir.FullName "CMakeLists.txt"
            if (Test-Path $cmakeListsPath) {
                Write-Host "`nCOLMAP CMakeLists.txt location:" -ForegroundColor Cyan
                Write-Host "  $cmakeListsPath" -ForegroundColor White
                
                # Provide instructions
                Write-Host "`n======================================" -ForegroundColor Cyan
                Write-Host "⚠ MANUAL STEP REQUIRED" -ForegroundColor Yellow
                Write-Host "======================================" -ForegroundColor Cyan
                
                Write-Host "`nYou must now edit the COLMAP CMakeLists.txt file:" -ForegroundColor Yellow
                Write-Host "`n1. Open this file in a text editor:" -ForegroundColor White
                Write-Host "   $cmakeListsPath" -ForegroundColor Cyan
                
                Write-Host "`n2. Add the following line after 'cmake_minimum_required':" -ForegroundColor White
                Write-Host '   set(cudss_DIR "YOUR_CUDSS_CMAKE_PATH")' -ForegroundColor Cyan
                
                Write-Host "`n3. Replace YOUR_CUDSS_CMAKE_PATH with your actual cuDSS path" -ForegroundColor White
                Write-Host "   Example: C:/Program Files/NVIDIA cuDSS/v0.4/lib/12/cmake/cudss" -ForegroundColor Gray
                
                Write-Host "`n4. Save the file" -ForegroundColor White
                
                Write-Host "`n5. Run the final build script:" -ForegroundColor White
                Write-Host "   cd ..\.." -ForegroundColor Cyan
                Write-Host "   .\scripts\colmap\build_colmap_final.ps1" -ForegroundColor Cyan
                
                # Create a helper script for quick editing
                Write-Host "`n======================================" -ForegroundColor Cyan
                Write-Host "Helper Script Created" -ForegroundColor Green
                Write-Host "======================================" -ForegroundColor Cyan
                
                $editScriptPath = "..\..\edit_colmap_cmake.ps1"
                $editScriptContent = @"
# Quick Edit Script for COLMAP CMakeLists.txt
# This script helps you edit the CMakeLists.txt file

param(
    [Parameter(Mandatory=`$true)]
    [string]`$CuDSSPath
)

`$cmakeListsPath = "$cmakeListsPath"

Write-Host "Adding cuDSS path to COLMAP CMakeLists.txt..." -ForegroundColor Yellow
Write-Host "Path: `$CuDSSPath`n" -ForegroundColor White

try {
    # Read the file
    `$content = Get-Content `$cmakeListsPath -Raw
    
    # Find the cmake_minimum_required line and add our line after it
    `$cudssLine = "set(cudss_DIR ```"`$(`$CuDSSPath -replace '\\', '/')```")"
    
    if (`$content -match "cmake_minimum_required") {
        # Check if cudss_DIR is already set
        if (`$content -match "set\(cudss_DIR") {
            Write-Host "✓ cudss_DIR already exists, updating..." -ForegroundColor Yellow
            `$content = `$content -replace 'set\(cudss_DIR\s+"[^"]*"\)', `$cudssLine
        } else {
            # Add after cmake_minimum_required
            `$content = `$content -replace "(cmake_minimum_required[^\r\n]*)", "`$1`r`n`r`n`$cudssLine"
        }
        
        # Write back
        `$content | Set-Content `$cmakeListsPath -NoNewline
        
        Write-Host "✓ CMakeLists.txt updated successfully!" -ForegroundColor Green
        Write-Host "`nYou can now run: .\build_colmap_final.ps1" -ForegroundColor Cyan
    } else {
        Write-Host "❌ Could not find cmake_minimum_required in file" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "❌ Error: `$_" -ForegroundColor Red
    exit 1
}
"@
                $editScriptContent | Set-Content $editScriptPath
                
                Write-Host "`nQuick edit option:" -ForegroundColor White
                Write-Host "   cd ..\.." -ForegroundColor Cyan
                Write-Host '   .\edit_colmap_cmake.ps1 -CuDSSPath "YOUR_CUDSS_PATH"' -ForegroundColor Cyan
                
                break
            }
        }
    } else {
        Write-Host "⚠ Warning: COLMAP source directory is empty" -ForegroundColor Yellow
        Write-Host "The build may have failed. Check error messages above." -ForegroundColor Yellow
    }
} else {
    Write-Host "⚠ Warning: COLMAP source directory not found at $colmapSourceBase" -ForegroundColor Yellow
    Write-Host "The build may have failed. Check error messages above." -ForegroundColor Yellow
}

Write-Host "`n======================================`n" -ForegroundColor Cyan

