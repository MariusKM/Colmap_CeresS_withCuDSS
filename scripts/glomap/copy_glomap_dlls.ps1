# Copy all necessary DLLs to GLOMAP install directory for standalone usage

$ErrorActionPreference = "Stop"

Write-Host "`n========================================"
Write-Host "Copy GLOMAP Dependencies"
Write-Host "Make GLOMAP standalone by copying DLLs"
Write-Host "========================================`n"

$vcpkgBin = "..\..\vcpkg\installed\x64-windows\bin"
$glomapBin = "..\..\glomap\install\bin"
$cudaBin = "C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v12.8\bin"
$cudssBin = "C:\NVIDIA_cuDSS\v0.7\bin\12"

# Check source directories
if (-not (Test-Path $vcpkgBin)) {
    Write-Host "❌ vcpkg bin directory not found: $vcpkgBin" -ForegroundColor Red
    exit 1
}

if (-not (Test-Path $glomapBin)) {
    Write-Host "❌ GLOMAP bin directory not found: $glomapBin" -ForegroundColor Red
    exit 1
}

# List of DLLs to copy from vcpkg
$vcpkgDlls = @(
    # Core dependencies
    "ceres.dll",
    "glog.dll",
    "gflags.dll",
    
    # COLMAP libraries
    "colmap_util.dll",
    "colmap_scene.dll",
    "colmap_estimators.dll",
    "colmap_feature.dll",
    "colmap_geometry.dll",
    "colmap_image.dll",
    "colmap_math.dll",
    "colmap_optim.dll",
    "colmap_retrieval.dll",
    "colmap_sensor.dll",
    "colmap_sfm.dll",
    "colmap_mvs.dll",
    "colmap_controllers.dll",
    "colmap_exe.dll",
    
    # Image libraries
    "freeimage.dll",
    "FreeImagePlus.dll",
    "jpeg62.dll",
    "libpng16.dll",
    "tiff.dll",
    "zlib1.dll",
    "lzma.dll",
    "webp.dll",
    "webpdemux.dll",
    "webpmux.dll",
    "libsharpyuv.dll",
    "Imath-3_1.dll",
    "OpenEXR-3_1.dll",
    "OpenEXRCore-3_1.dll",
    "OpenEXRUtil-3_1.dll",
    "Iex-3_1.dll",
    "IlmThread-3_1.dll",
    "jxrglue.dll",
    "jpegxr.dll",
    "openjp2.dll",
    "raw.dll",
    
    # SQLite
    "sqlite3.dll",
    
    # Boost
    "boost_filesystem-vc143-mt-x64-1_89.dll",
    "boost_serialization-vc143-mt-x64-1_89.dll",
    "boost_program_options-vc143-mt-x64-1_89.dll",
    "boost_graph-vc143-mt-x64-1_89.dll",
    "boost_regex-vc143-mt-x64-1_89.dll",
    "boost_thread-vc143-mt-x64-1_89.dll",
    "boost_chrono-vc143-mt-x64-1_89.dll",
    "boost_date_time-vc143-mt-x64-1_89.dll",
    "boost_atomic-vc143-mt-x64-1_89.dll",
    "boost_container-vc143-mt-x64-1_89.dll",
    "boost_random-vc143-mt-x64-1_89.dll",
    
    # FLANN
    "flann_cpp.dll",
    "lz4.dll",
    
    # SuiteSparse (for Eigen/Ceres)
    "suitesparseconfig.dll",
    "cholmod.dll",
    "amd.dll",
    "colamd.dll",
    "ccolamd.dll",
    "camd.dll",
    "spqr.dll",
    "metis.dll",
    
    # Intel TBB (for some libraries)
    "tbb12.dll",
    "tbbmalloc.dll"
)

# CUDA DLLs (if CUDA bin exists)
$cudaDlls = @(
    "cudart64_12.dll",
    "cublas64_12.dll",
    "cublasLt64_12.dll",
    "cusparse64_12.dll",
    "cusolver64_12.dll"
)

# cuDSS DLLs
$cudssDlls = @(
    "cudss64_0.dll"
)

Write-Host "Copying DLLs from vcpkg..." -ForegroundColor Cyan
$copiedCount = 0
$skippedCount = 0

foreach ($dll in $vcpkgDlls) {
    $sourcePath = Join-Path $vcpkgBin $dll
    $destPath = Join-Path $glomapBin $dll
    
    if (Test-Path $sourcePath) {
        Copy-Item -Path $sourcePath -Destination $destPath -Force
        Write-Host "  ✓ $dll" -ForegroundColor Green
        $copiedCount++
    } else {
        Write-Host "  ⚠ $dll (not found, may not be needed)" -ForegroundColor Yellow
        $skippedCount++
    }
}

# Copy CUDA DLLs
if (Test-Path $cudaBin) {
    Write-Host "`nCopying CUDA DLLs..." -ForegroundColor Cyan
    foreach ($dll in $cudaDlls) {
        $sourcePath = Join-Path $cudaBin $dll
        $destPath = Join-Path $glomapBin $dll
        
        if (Test-Path $sourcePath) {
            Copy-Item -Path $sourcePath -Destination $destPath -Force
            Write-Host "  ✓ $dll" -ForegroundColor Green
            $copiedCount++
        } else {
            Write-Host "  ⚠ $dll (not found)" -ForegroundColor Yellow
            $skippedCount++
        }
    }
} else {
    Write-Host "`n⚠ CUDA bin directory not found: $cudaBin" -ForegroundColor Yellow
}

# Copy cuDSS DLLs
if (Test-Path $cudssBin) {
    Write-Host "`nCopying cuDSS DLLs..." -ForegroundColor Cyan
    foreach ($dll in $cudssDlls) {
        $sourcePath = Join-Path $cudssBin $dll
        $destPath = Join-Path $glomapBin $dll
        
        if (Test-Path $sourcePath) {
            Copy-Item -Path $sourcePath -Destination $destPath -Force
            Write-Host "  ✓ $dll" -ForegroundColor Green
            $copiedCount++
        } else {
            Write-Host "  ⚠ $dll (not found)" -ForegroundColor Yellow
            $skippedCount++
        }
    }
} else {
    Write-Host "`n⚠ cuDSS bin directory not found: $cudssBin" -ForegroundColor Yellow
}

Write-Host "`n========================================"
Write-Host "Summary"
Write-Host "========================================`n"
Write-Host "✓ Copied: $copiedCount DLLs" -ForegroundColor Green
Write-Host "⚠ Skipped: $skippedCount DLLs (not found or not needed)" -ForegroundColor Yellow
Write-Host "`nGLOMAP is now standalone at:" -ForegroundColor Cyan
Write-Host "  $glomapBin`n"
Write-Host "You can now run GLOMAP without vcpkg in PATH:`n"
Write-Host "  .\glomap\install\bin\glomap.exe mapper --database_path ... --image_path ... --output_path ...`n"

