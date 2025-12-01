# Test COLMAP GPU Support
# This script verifies that COLMAP was built with CUDA and cuDSS support

Write-Host "======================================" -ForegroundColor Cyan
Write-Host "Test COLMAP GPU Support" -ForegroundColor Cyan
Write-Host "======================================`n" -ForegroundColor Cyan

# Locate COLMAP executable
$colmapExePath = "..\..\vcpkg\packages\colmap_x64-windows\tools\colmap\colmap.exe"

if (-not (Test-Path $colmapExePath)) {
    Write-Host "❌ Error: COLMAP executable not found at:" -ForegroundColor Red
    Write-Host "  $colmapExePath`n" -ForegroundColor Gray
    
    # Try to find it
    Write-Host "Searching for COLMAP executable..." -ForegroundColor Yellow
    $vcpkgRoot = "..\..\vcpkg"
    $searchPath = Join-Path $vcpkgRoot "packages\colmap_x64-windows"
    
    if (Test-Path $searchPath) {
        $foundExe = Get-ChildItem -Path $searchPath -Recurse -Filter "colmap.exe" -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($foundExe) {
            $colmapExePath = $foundExe.FullName
            Write-Host "✓ Found COLMAP at: $colmapExePath" -ForegroundColor Green
        } else {
            Write-Host "❌ Could not find colmap.exe" -ForegroundColor Red
            Write-Host "Please ensure COLMAP was built successfully." -ForegroundColor Red
            exit 1
        }
    } else {
        Write-Host "❌ COLMAP package directory not found" -ForegroundColor Red
        Write-Host "Please build COLMAP first using build_colmap_final.ps1" -ForegroundColor Red
        exit 1
    }
}

Write-Host "COLMAP executable: $colmapExePath`n" -ForegroundColor White

# Test 1: Check if COLMAP runs
Write-Host "Test 1: Checking if COLMAP executable runs..." -ForegroundColor Yellow

try {
    $versionOutput = & $colmapExePath -h 2>&1
    if ($LASTEXITCODE -eq 0 -or $versionOutput) {
        Write-Host "✓ COLMAP executable runs successfully" -ForegroundColor Green
        
        # Extract version if available
        if ($versionOutput -match "COLMAP (\d+\.\d+\.\d+)") {
            Write-Host "  Version: $($matches[1])" -ForegroundColor White
        }
    } else {
        Write-Host "❌ COLMAP executable failed to run" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "❌ Error running COLMAP: $_" -ForegroundColor Red
    exit 1
}

# Test 2: Check bundle_adjuster help
Write-Host "`nTest 2: Checking bundle_adjuster command..." -ForegroundColor Yellow

try {
    $bundleHelp = & $colmapExePath bundle_adjuster -h 2>&1
    if ($bundleHelp -match "BundleAdjustment.use_gpu") {
        Write-Host "✓ GPU bundle adjustment option is available" -ForegroundColor Green
    } else {
        Write-Host "⚠ Warning: GPU option may not be available" -ForegroundColor Yellow
    }
} catch {
    Write-Host "⚠ Warning: Could not check bundle_adjuster help: $_" -ForegroundColor Yellow
}

# Test 3: Check for CUDA libraries
Write-Host "`nTest 3: Checking for CUDA libraries..." -ForegroundColor Yellow

$colmapPackageDir = Split-Path (Split-Path (Split-Path $colmapExePath -Parent) -Parent) -Parent
$binDir = Join-Path $colmapPackageDir "bin"

if (Test-Path $binDir) {
    $cudaDlls = Get-ChildItem -Path $binDir -Filter "*cuda*.dll" -ErrorAction SilentlyContinue
    $nvrtcDlls = Get-ChildItem -Path $binDir -Filter "*nvrtc*.dll" -ErrorAction SilentlyContinue
    $cudartDlls = Get-ChildItem -Path $binDir -Filter "*cudart*.dll" -ErrorAction SilentlyContinue
    
    $allCudaDlls = @($cudaDlls) + @($nvrtcDlls) + @($cudartDlls)
    
    if ($allCudaDlls.Count -gt 0) {
        Write-Host "✓ CUDA libraries found:" -ForegroundColor Green
        foreach ($dll in $allCudaDlls) {
            Write-Host "  - $($dll.Name)" -ForegroundColor Gray
        }
    } else {
        Write-Host "⚠ No CUDA DLLs found in bin directory" -ForegroundColor Yellow
        Write-Host "  This may be normal if CUDA libraries are system-wide" -ForegroundColor Gray
    }
}

# Test 4: Check CUDA availability
Write-Host "`nTest 4: Checking CUDA device detection..." -ForegroundColor Yellow

# Create a temporary model directory for testing (empty)
$tempTestDir = Join-Path $env:TEMP "colmap_gpu_test"
if (-not (Test-Path $tempTestDir)) {
    New-Item -ItemType Directory -Path $tempTestDir -Force | Out-Null
}

Write-Host "  Note: This test requires a valid COLMAP model" -ForegroundColor Gray
Write-Host "  Creating a test to check CUDA detection...`n" -ForegroundColor Gray

# Try to run a simple CUDA check by invoking colmap with GPU flag
# We expect this to fail with a specific message about the model, but we can check CUDA output
try {
    $gpuTestOutput = & $colmapExePath bundle_adjuster `
        --input_path "$tempTestDir" `
        --output_path "$tempTestDir" `
        --BundleAdjustment.use_gpu=1 2>&1
    
    $gpuTestString = $gpuTestOutput | Out-String
    
    # Check for success message
    if ($gpuTestString -match "Found \d+ CUDA device") {
        Write-Host "✓ CUDA device detected successfully!" -ForegroundColor Green
        
        # Extract device info
        if ($gpuTestString -match "Found (\d+) CUDA device\(s\), selected device \d+ with name (.+)") {
            $deviceCount = $matches[1]
            $deviceName = $matches[2].Trim()
            Write-Host "  Devices: $deviceCount" -ForegroundColor White
            Write-Host "  GPU: $deviceName" -ForegroundColor White
        }
    }
    # Check for failure messages
    elseif ($gpuTestString -match "compiled without CUDA support") {
        Write-Host "❌ CRITICAL: Ceres was compiled without CUDA support!" -ForegroundColor Red
        Write-Host "`nThe build failed. You need to rebuild Ceres with CUDA enabled." -ForegroundColor Red
        Remove-Item $tempTestDir -Recurse -Force -ErrorAction SilentlyContinue
        exit 1
    }
    elseif ($gpuTestString -match "compiled without cuDSS support") {
        Write-Host "❌ CRITICAL: Ceres was compiled without cuDSS support!" -ForegroundColor Red
        Write-Host "`nThe build failed. You need to rebuild Ceres with cuDSS properly configured." -ForegroundColor Red
        Remove-Item $tempTestDir -Recurse -Force -ErrorAction SilentlyContinue
        exit 1
    }
    elseif ($gpuTestString -match "Invalid input path") {
        Write-Host "⚠ Cannot verify GPU without a valid model, but no CUDA/cuDSS errors detected" -ForegroundColor Yellow
        Write-Host "  This is expected - the test directory is empty" -ForegroundColor Gray
    }
    else {
        Write-Host "⚠ Could not determine CUDA status from output" -ForegroundColor Yellow
        Write-Host "  Check the output below:`n" -ForegroundColor Gray
        Write-Host $gpuTestString -ForegroundColor Gray
    }
    
} catch {
    Write-Host "⚠ GPU test encountered an error: $_" -ForegroundColor Yellow
} finally {
    # Clean up temp directory
    Remove-Item $tempTestDir -Recurse -Force -ErrorAction SilentlyContinue
}

# Summary
Write-Host "`n======================================" -ForegroundColor Cyan
Write-Host "Test Summary" -ForegroundColor Cyan
Write-Host "======================================`n" -ForegroundColor Cyan

Write-Host "If you see 'Found CUDA device' message above, your build is successful! ✓" -ForegroundColor Green
Write-Host "`nIf you see 'compiled without CUDA/cuDSS support', you need to:" -ForegroundColor Yellow
Write-Host "  1. Verify cuDSS is installed and paths are correct" -ForegroundColor Yellow
Write-Host "  2. Rebuild Ceres with: .\build_ceres.ps1" -ForegroundColor Yellow
Write-Host "  3. Rebuild COLMAP with: .\build_colmap_final.ps1" -ForegroundColor Yellow

Write-Host "`n======================================" -ForegroundColor Cyan
Write-Host "Usage Example" -ForegroundColor Cyan
Write-Host "======================================`n" -ForegroundColor Cyan

Write-Host "To use GPU-enabled bundle adjustment with your own model:" -ForegroundColor White
Write-Host @"

`$input_model_path = "C:\path\to\your\model"
`$output_model_path = "C:\path\to\output"

& '$colmapExePath' ``
    bundle_adjuster ``
    --input_path "`$input_model_path" ``
    --output_path "`$output_model_path" ``
    --BundleAdjustment.use_gpu=1 ``
    --BundleAdjustment.refine_focal_length=1 ``
    --log_level 2

"@ -ForegroundColor Cyan

Write-Host "Expected success output:" -ForegroundColor White
Write-Host "  I20250213 16:42:55.713294 24144 cuda.cc:75] Found 1 CUDA device(s), selected device 0 with name NVIDIA GeForce RTX..." -ForegroundColor Green

Write-Host "`n======================================`n" -ForegroundColor Cyan

