# Quick Start Guide - COLMAP 3.13.0 with CUDA-enabled Ceres 2.3.0

## Current Status

✅ **Completed:**
- COLMAP 3.13.0 successfully built
- Ceres 2.3.0 with CUDA and cuDSS 0.7 support
- Environment check script created
- vcpkg cloned and bootstrapped
- All build scripts created and tested
- Configuration scripts ready
- Test scripts prepared
- Comprehensive documentation written

✅ **System Verified:**
- CUDA Toolkit 12.8 detected
- cuDSS 0.7 installed
- Visual Studio Build Tools 2022 installed
- All dependencies configured

## Current Build Details

**COLMAP Version:** 3.13.0 (commit 0b31f98133b470eae62811b557dc2bcff1e4f9a5)
**Ceres Version:** 2.3.0
**cuDSS Version:** 0.7
**Build Status:** ✅ Operational

## Build Process Summary

### Prerequisites Check
```powershell
.\check_environment.ps1
```
This checks for CUDA, cuDSS, Git, CMake, and Visual Studio.

### Configuration & Build Sequence

```powershell
# 1. Configure Ceres for your cuDSS path
.\configure_vcpkg_ceres.ps1 -CuDSSPath "C:/NVIDIA_cuDSS/v0.7/lib/12/cmake/cudss"

# 2. Build Ceres with CUDA (30-60 min)
.\build_ceres.ps1

# 3. Initial COLMAP build to get source
.\build_colmap_initial.ps1

# 4. Edit COLMAP CMakeLists.txt (automated helper)
.\edit_colmap_cmake.ps1 -CuDSSPath "C:/NVIDIA_cuDSS/v0.7/lib/12/cmake/cudss"

# 5. Final COLMAP build (5-10 min - FAST!)
.\build_colmap_final.ps1

# 6. Test GPU support with comprehensive logging
.\test_bundle_adjuster_gpu.ps1
```

### cuDSS Path Format

Your cuDSS path should look like:
```
C:/NVIDIA_cuDSS/v0.7/lib/12/cmake/cudss
```

**Important:** 
- Use forward slashes (`/`) not backslashes (`\`)
- Avoid paths with spaces when possible
- Recommended: `C:\NVIDIA_cuDSS\v0.7`
- Default (may cause issues): `C:\Program Files\NVIDIA cuDSS\v0.7`

## Files Created

| File | Purpose |
|------|---------|
| `check_environment.ps1` | Verify prerequisites |
| `configure_vcpkg_ceres.ps1` | Configure vcpkg for Ceres 2.3.0 |
| `build_ceres.ps1` | Build Ceres with CUDA |
| `build_colmap_initial.ps1` | Clone COLMAP 3.13.0 source |
| `edit_colmap_cmake.ps1` | Edit COLMAP CMakeLists.txt |
| `build_colmap_final.ps1` | Build COLMAP 3.13.0 with CUDA |
| `test_colmap_gpu.ps1` | Quick GPU verification test |
| `test_bundle_adjuster_gpu.ps1` | Comprehensive bundle adjuster test with logging |
| `calculate_colmap_sha512.ps1` | SHA512 hash calculator for version upgrades |
| `README.md` | Complete documentation |
| `MANUAL_CONFIGURATION_GUIDE.md` | Detailed manual steps |

## Success Criteria

✓ `test_bundle_adjuster_gpu.ps1` shows:
```
Bundle adjustment completed successfully!
  Residuals: 5246224
  Iterations: 80
  Time: 1238.05 seconds

✓ Full log saved to: .\bundle_adjuster_gpu_test.log
```

**Key Indicators:**
- No "compiled without cuDSS support" errors
- Bundle adjustment converges
- GPU memory usage visible in Task Manager
- Log file contains detailed timing information

## Estimated Time

- Setup: 10 minutes (if cuDSS already installed)
- Ceres build: 30-60 minutes  
- COLMAP 3.13.0 build: 5-10 minutes (much faster than previous versions!)
- **Total: ~45-70 minutes**

**Note:** COLMAP 3.13.0 builds significantly faster than 3.12.x and earlier versions.

## What Was Automated

Everything except cuDSS installation has been automated and completed:

1. ✅ **Environment Detection** - Automatic CUDA, cuDSS, Visual Studio detection
2. ✅ **vcpkg Setup** - Cloned and bootstrapped
3. ✅ **Ceres 2.3.0 Build** - Built with CUDA and cuDSS 0.7
4. ✅ **COLMAP 3.13.0 Build** - Built with CUDA-enabled Ceres
5. ✅ **DLL Management** - Automatic copying of required CUDA and cuDSS DLLs
6. ✅ **GPU Verification** - Comprehensive testing with detailed logging

## Upgrading to Newer COLMAP Versions

To upgrade to a future COLMAP version:

1. Run the SHA512 calculator:
   ```powershell
   .\calculate_colmap_sha512.ps1
   ```

2. Update vcpkg configuration files with new version and hash

3. Clear build cache and rebuild following the same process

## Next Steps for New Builds

If starting fresh on a new machine:

1. ❌ **Install cuDSS 0.7+** (REQUIRED - Download from NVIDIA)
2. ❌ **Install Visual Studio Build Tools 2022** (REQUIRED if not detected)
3. Run `.\check_environment.ps1` to verify
4. Run `.\configure_vcpkg_ceres.ps1 -CuDSSPath "YOUR_PATH"`
5. Follow the build sequence above

## Key Points to Remember

1. **Forward slashes** in paths: `C:/NVIDIA_cuDSS/...` not `C:\NVIDIA_cuDSS\...`
2. **Avoid paths with spaces** - Install cuDSS to `C:\NVIDIA_cuDSS\v0.7` if possible
3. **cuDSS 0.7 is current version** - Provides best performance
4. **COLMAP 3.13.0 builds fast** - Only 5-10 minutes vs 45-90 for older versions
5. **Use PowerShell** - Not Command Prompt
6. **Check Task Manager** - GPU memory usage indicates GPU acceleration is working
7. **Use log_level 0** - For verbose logging when troubleshooting

---

**System Status:** ✅ COLMAP 3.13.0 with CUDA-enabled Ceres 2.3.0 + cuDSS 0.7 - Fully operational!

**Last Updated:** November 28, 2025

