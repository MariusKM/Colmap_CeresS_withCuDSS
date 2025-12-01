# COLMAP and GLOMAP with CUDA-enabled Ceres Solver - Build Guide

This repository contains automated scripts and documentation for building COLMAP 3.13.0 with CUDA-enabled Ceres Solver 2.3.0 on Windows, including cuDSS 0.7 support for GPU-accelerated bundle adjustment.

## 📋 Overview

This build process enables GPU acceleration for COLMAP's bundle adjustment by:
- Building Ceres Solver 2.3.0 with CUDA and cuDSS support
- Building COLMAP 3.13.0 with the CUDA-enabled Ceres
- Verifying GPU support is properly configured

**Latest Version:** COLMAP 3.13.0 (commit 0b31f98133b470eae62811b557dc2bcff1e4f9a5)

## 🔧 Prerequisites

### Required Software (Manual Installation)

1. **CUDA Toolkit 12.0 or later**
   - Download from: https://developer.nvidia.com/cuda-downloads
   - The installer should set environment variables automatically

2. **cuDSS 0.7 or later** 
   - Download from: https://developer.nvidia.com/cudss-downloads
   - This is CRITICAL - must be installed before building
   - **Recommended installation:** `C:\NVIDIA_cuDSS\v0.7` (path without spaces)
   - Default installation: `C:\Program Files\NVIDIA cuDSS` (may cause CMake issues)
   - Note: Version 0.7 is the current version and provides optimal performance

3. **Visual Studio 2019 or later (or Build Tools 2022)**
   - Download from: https://visualstudio.microsoft.com/
   - Required workload: "Desktop development with C++"
   - Visual Studio Build Tools 2022 is sufficient and recommended

4. **Git** 

### Automated Components

These are handled by the scripts:
- vcpkg (package manager) 
- CMake (installed by vcpkg if needed)
- CUDA_PATH environment variable (auto-detected and set)
- All required dependencies (Eigen, Boost, etc.)

## 🚀 Quick Start

### Step 1: Check Your Environment

Run the environment check script to verify prerequisites:

```powershell
.\check_environment.ps1
```

**⚠️ IMPORTANT:** You must install cuDSS before proceeding!

### Step 2: Configure vcpkg for Ceres

After installing cuDSS, configure the vcpkg files with your cuDSS path:

```powershell
# For cuDSS v0.7 (recommended installation path without spaces)
.\configure_vcpkg_ceres.ps1 -CuDSSPath "C:/NVIDIA_cuDSS/v0.7/lib/12/cmake/cudss"

# Or if installed to default location
.\configure_vcpkg_ceres.ps1 -CuDSSPath "C:/Program Files/NVIDIA cuDSS/v0.7/lib/12/cmake/cudss"
```

Replace the path with your actual cuDSS installation path (use forward slashes `/`).  
**Important:** If you encounter CMake path issues, reinstall cuDSS to a path without spaces like `C:\NVIDIA_cuDSS\v0.7`.

### Step 3: Build Ceres Solver

Build Ceres with CUDA and cuDSS support (takes 30-60 minutes):

```powershell
.\build_ceres.ps1
```

### Step 4: Build COLMAP (Initial)

Start the initial COLMAP build to clone the source code:

```powershell
.\build_colmap_initial.ps1
```

This will clone COLMAP and may partially build it. The script will tell you the location of the CMakeLists.txt file.

### Step 5: Configure COLMAP CMakeLists.txt

Edit COLMAP's CMakeLists.txt to add the cuDSS path:

**Option A - Use the helper script:**
```powershell
# For recommended installation path
.\edit_colmap_cmake.ps1 -CuDSSPath "C:/NVIDIA_cuDSS/v0.7/lib/12/cmake/cudss"
```

**Option B - Manual edit:**
Open the CMakeLists.txt file (location shown by the initial build script) and add this line after `cmake_minimum_required`:
```cmake
# For cuDSS v0.7 installed without spaces in path
set(cudss_DIR "C:/NVIDIA_cuDSS/v0.7/lib/12/cmake/cudss")
```

### Step 6: Build COLMAP (Final)

Complete the COLMAP build (takes 45-90 minutes):

```powershell
.\build_colmap_final.ps1
```

### Step 7: Test GPU Support

Verify that GPU support is working with comprehensive logging:

```powershell
# Quick test (may not show detailed output)
.\test_colmap_gpu.ps1

# Or use the bundle adjuster test with full logging
.\test_bundle_adjuster_gpu.ps1
```

**Expected success output:**
- No "compiled without cuDSS support" errors
- Bundle adjustment completes successfully
- Log file saved with detailed timing information
- GPU memory usage visible in Task Manager during execution

**Note:** COLMAP 3.13.0 may not explicitly log "Found CUDA device" messages, but the absence of cuDSS errors and successful completion indicates GPU support is working.

## 📁 File Structure

```
E:\Programs\Gaussians\colmap_Ceres_2.3\
├── check_environment.ps1           # Check system prerequisites
├── configure_vcpkg_ceres.ps1       # Configure vcpkg for Ceres 2.3.0
├── build_ceres.ps1                 # Build Ceres with CUDA
├── build_colmap_initial.ps1        # Initial COLMAP build
├── edit_colmap_cmake.ps1           # Helper to edit CMakeLists.txt
├── build_colmap_final.ps1          # Final COLMAP build
├── test_colmap_gpu.ps1             # Quick GPU test
├── test_bundle_adjuster_gpu.ps1    # Comprehensive bundle adjuster test
├── calculate_colmap_sha512.ps1     # SHA512 hash calculator for version upgrades
├── MANUAL_CONFIGURATION_GUIDE.md   # Detailed manual steps guide
├── QUICKSTART.md                   # Quick reference guide
└── vcpkg\                          # vcpkg package manager (created)
    ├── vcpkg.exe
    ├── ports\ceres\                # Ceres configuration
    ├── buildtrees\                 # Build directories
    └── packages\                   # Installed packages
```

## 📖 Detailed Documentation

For comprehensive step-by-step instructions, see:
- [MANUAL_CONFIGURATION_GUIDE.md](MANUAL_CONFIGURATION_GUIDE.md) - Complete manual configuration guide

## 🔍 Verification

After successful build, the COLMAP 3.13.0 executable will be at:
```
E:\Programs\Gaussians\colmap_Ceres_2.3\vcpkg\packages\colmap_x64-windows\tools\colmap\colmap.exe
```

To verify the version:
```powershell
& ".\vcpkg\packages\colmap_x64-windows\tools\colmap\colmap.exe" -h
```

## 🎯 Usage Example

To run GPU-accelerated bundle adjustment:

```powershell
$colmap_exe = "E:\Programs\Gaussians\colmap_Ceres_2.3\vcpkg\packages\colmap_x64-windows\tools\colmap\colmap.exe"
$input_model_path = "C:\path\to\your\model"
$output_model_path = "C:\path\to\output"

& $colmap_exe `
    bundle_adjuster `
    --input_path "$input_model_path" `
    --output_path "$output_model_path" `
    --BundleAdjustment.use_gpu=1 `
    --BundleAdjustment.refine_focal_length=1 `
    --log_level 0
```

**Log Level Guide:**
- `--log_level 0` = INFO (most verbose, shows all details)
- `--log_level 1` = WARNING 
- `--log_level 2` = ERROR (least verbose)

## ⚠️ Troubleshooting

### Issue: "compiled without CUDA support"
**Solution:** Ceres was not built with CUDA. Verify:
1. CUDA is installed and in PATH
2. cuDSS path is correct in `vcpkg\ports\ceres\portfile.cmake`
3. Rebuild Ceres: `.\build_ceres.ps1`

### Issue: "compiled without cuDSS support"
**Solution:** cuDSS was not found during build. Verify:
1. cuDSS is installed
2. Path in portfile.cmake uses forward slashes (`/`)
3. Path points to the `cmake/cudss` directory
4. Rebuild Ceres: `.\build_ceres.ps1`

### Issue: Build fails with CMake errors
**Solution:**
1. Ensure Visual Studio is installed
2. Close all Visual Studio instances
3. Restart PowerShell
4. Try again

### Issue: vcpkg build is very slow
**Solution:**
- This is normal - Ceres and COLMAP take 1-2 hours total
- Close other applications to free up RAM
- The `--editable` flag is only needed for development

## 📝 Build Times (Approximate)

- Ceres Solver 2.3.0: 30-60 minutes
- COLMAP 3.13.0: 5-10 minutes (significantly faster than previous versions!)
- Total: 35-70 minutes

**Note:** COLMAP 3.13.0 builds much faster than earlier versions due to build system improvements.

## 🔄 Rebuild Process

If you need to rebuild after fixing issues:

1. **Rebuild Ceres:**
   ```powershell
   cd vcpkg
   .\vcpkg remove ceres:x64-windows
   cd ..
   .\build_ceres.ps1
   ```

2. **Rebuild COLMAP:**
   ```powershell
   cd vcpkg
   .\vcpkg remove colmap:x64-windows
   cd ..
   .\build_colmap_final.ps1
   ```

## 📚 References


- COLMAP GitHub: https://github.com/colmap/colmap
- GLOMAP GitHub: https://github.com/colmap/glomap
- Ceres Solver: http://ceres-solver.org/
- vcpkg: https://github.com/microsoft/vcpkg

## 🚀 Building GLOMAP with GPU-Enabled COLMAP

GLOMAP is a fast global structure-from-motion pipeline that can use your GPU-enabled COLMAP installation for even faster reconstruction.

### Quick Start

```powershell
# 1. Check environment
.\check_glomap_environment.ps1

# 2. Install Ninja (optional, for faster builds)
.\install_ninja.ps1

# 3. Clone GLOMAP
.\clone_glomap.ps1

# 4. Build GLOMAP (5-15 minutes)
.\build_glomap.ps1

# 5. Test installation
.\test_glomap.ps1
```

### What You Get

- **GLOMAP** with GPU-enabled COLMAP 3.13.0 integration
- **GPU-accelerated bundle adjustment** (inherited from COLMAP/Ceres)
- **1-2 orders of magnitude faster** than standard COLMAP SfM
- **Compatible output format** - works with existing COLMAP workflows

### Usage Example

```powershell
# Path to GLOMAP executable
$glomap = ".\glomap\install\bin\glomap.exe"

# Add vcpkg DLLs to PATH
$env:PATH = "$(Resolve-Path '.\vcpkg\installed\x64-windows\bin');$env:PATH"

# Run GLOMAP mapper
& $glomap mapper `
    --database_path ./database.db `
    --image_path ./images `
    --output_path ./glomap_output
```

### Integration with COLMAP

GLOMAP works seamlessly with COLMAP databases:

```powershell
# 1. Extract features with COLMAP
$colmap = ".\vcpkg\packages\colmap_x64-windows\tools\colmap\colmap.exe"
& $colmap feature_extractor `
    --image_path ./images `
    --database_path ./database.db

# 2. Match features with COLMAP
& $colmap exhaustive_matcher `
    --database_path ./database.db

# 3. Reconstruct with GLOMAP (much faster!)
& $glomap mapper `
    --database_path ./database.db `
    --image_path ./images `
    --output_path ./output

# 4. Visualize with COLMAP GUI
& $colmap gui --import_path ./output
```

### Build Details

- **Build time:** 5-15 minutes (with Ninja) or 15-30 minutes (with MSBuild)
- **Uses existing COLMAP:** Links against your GPU-enabled COLMAP 3.13.0
- **GPU support:** Inherited from COLMAP/Ceres (CUDA + cuDSS 0.7)
- **Output format:** COLMAP sparse reconstruction format

### Troubleshooting

**DLL not found errors:**
```powershell
# Add vcpkg binaries to PATH
$env:PATH = "$(Resolve-Path '.\vcpkg\installed\x64-windows\bin');$env:PATH"
```

**Want to rebuild:**
```powershell
.\build_glomap.ps1 -Clean
```

For more information, see the [GLOMAP GitHub repository](https://github.com/colmap/glomap).

## ✅ Success Indicators

Your build is successful if:
- ✓ `test_bundle_adjuster_gpu.ps1` completes without errors
- ✓ No "compiled without CUDA/cuDSS support" errors appear
- ✓ Bundle adjustment completes successfully
- ✓ Log file shows convergence and timing information
- ✓ GPU is utilized during bundle adjustment (check Task Manager - NVIDIA GPU memory usage)

**Version Verification:**
```powershell
& ".\vcpkg\packages\colmap_x64-windows\tools\colmap\colmap.exe" -h | Select-String "COLMAP"
# Should show version 3.13.0
```

## 💡 Tips

1. **Use forward slashes** in all paths for CMake compatibility
2. **Install cuDSS to a path without spaces** to avoid CMake quoting issues (recommended: `C:\NVIDIA_cuDSS\`)
3. **Keep source code** with `--editable` flag for debugging
4. **Check logs** in `vcpkg\buildtrees\` if builds fail
5. **Monitor GPU usage** in Task Manager during bundle adjustment
6. **Run in PowerShell** not Command Prompt for best results
7. **Use log_level 0** for verbose output when troubleshooting
8. **COLMAP 3.13.0 builds much faster** - don't be surprised by the short build time!

## 🆘 Need Help?

1. Check [MANUAL_CONFIGURATION_GUIDE.md](MANUAL_CONFIGURATION_GUIDE.md) for detailed steps
2. Review error messages in the build output
3. Verify all prerequisites are installed
4. Check that paths use forward slashes (`/`)
5. Ensure cuDSS is properly installed

## 🔄 Upgrading to Newer COLMAP Versions

To upgrade to a newer version of COLMAP:

1. **Calculate SHA512 hash** for the new version:
   ```powershell
   .\calculate_colmap_sha512.ps1
   ```

2. **Update vcpkg configuration files:**
   - Edit `vcpkg/ports/colmap/vcpkg.json` - update version
   - Edit `vcpkg/ports/colmap/portfile.cmake` - update REF and SHA512

3. **Clear build cache:**
   ```powershell
   cd vcpkg
   .\vcpkg remove colmap:x64-windows
   cd ..
   ```

4. **Rebuild COLMAP** following Steps 4-7 above



