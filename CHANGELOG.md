# Changelog - COLMAP with CUDA-enabled Ceres Solver

## [3.13.0] - 2025-11-28

### Added
- **COLMAP 3.13.0** support (commit hash: 0b31f98133b470eae62811b557dc2bcff1e4f9a5)
- `calculate_colmap_sha512.ps1` - Automated SHA512 hash calculation for version upgrades
- `test_bundle_adjuster_gpu.ps1` - Comprehensive bundle adjuster test with full logging
- Upgrade instructions in README.md
- Detailed version upgrade process documentation
- CHANGELOG.md to track version history

### Changed
- **cuDSS Version**: Updated from v0.4 to v0.7
- **Recommended Installation Path**: Changed from `C:\Program Files\NVIDIA cuDSS` to `C:\NVIDIA_cuDSS\v0.7` (avoids path with spaces issues)
- **Build Times**: COLMAP 3.13.0 builds in 5-10 minutes (previously 45-90 minutes!)
- **Test Output**: Updated success criteria for COLMAP 3.13.0 (different logging behavior)
- **Visual Studio**: Added support for Build Tools 2022 as alternative to full VS installation
- **Environment Detection**: Enhanced CUDA_PATH auto-detection and setting
- **DLL Management**: Automatic copying of cuDSS and CUDA DLLs to COLMAP executable directory

### Fixed
- Duplicate `port-version` entries in `vcpkg/ports/ceres/vcpkg.json`
- SHA512 hash calculation to use version tag URL instead of commit hash URL
- CMake path handling for cuDSS with spaces in path
- Missing DLLs preventing COLMAP executable from running
- vcpkg caching issues preventing clean rebuilds

### Updated Documentation
- **README.md**: 
  - Added COLMAP 3.13.0 version information
  - Updated all cuDSS paths to v0.7
  - Added recommended installation path without spaces
  - Updated build time estimates
  - Added log level guide for verbose output
  - Added version verification commands
  - Added upgrade instructions section

- **MANUAL_CONFIGURATION_GUIDE.md**:
  - Updated to COLMAP 3.13.0
  - Changed cuDSS recommended installation path
  - Updated build time estimates
  - Updated success criteria and test outputs
  - Updated file paths to include version-specific directories

- **QUICKSTART.md**:
  - Updated status to show completed build
  - Added current version information
  - Updated build time estimates
  - Added comprehensive test script references
  - Added upgrade instructions
  - Updated success criteria for 3.13.0

### Technical Details

**COLMAP 3.13.0 Changes:**
- Uses version tag archive instead of commit hash archive for vcpkg
- SHA512: `a6de525e98d1a22f180d3148a5282814a6d5dc4e407d4b3b37d217e20b0c6d1511e4b1c0bdaaf0f6f00dcc4386c3160f7de8b6310b9bdd99f65c74fb3531c2c6`
- Build system improvements result in significantly faster compilation
- Different logging behavior - less verbose CUDA device detection messages

**Build System:**
- Removed non-existent `[tests]` feature from COLMAP vcpkg installation
- Added `--no-binarycaching` flag to ensure fresh builds
- Implemented automatic build artifact cleanup before rebuilds
- Enhanced error detection and reporting in build scripts

### Test Results
- Bundle adjuster test completes successfully in ~20.7 minutes
- No "compiled without cuDSS support" errors
- Convergence achieved in 80 iterations
- 5,246,224 residuals processed successfully

---

## [Initial Release] - 2024-11-27

### Added
- Initial project setup with COLMAP 3.12.6
- Ceres Solver 2.3.0 with CUDA support
- cuDSS v0.4 integration
- Automated build scripts:
  - `check_environment.ps1`
  - `configure_vcpkg_ceres.ps1`
  - `build_ceres.ps1`
  - `build_colmap_initial.ps1`
  - `edit_colmap_cmake.ps1`
  - `build_colmap_final.ps1`
  - `test_colmap_gpu.ps1`
- Documentation:
  - README.md
  - MANUAL_CONFIGURATION_GUIDE.md
  - QUICKSTART.md
- vcpkg integration for Windows builds
- CUDA 12.8 support

---

## Version Information

| Component | Version | Notes |
|-----------|---------|-------|
| COLMAP | 3.13.0 | Latest release |
| Ceres Solver | 2.3.0 | With CUDA support |
| cuDSS | 0.7 | GPU-accelerated sparse solver |
| CUDA | 12.8 | Minimum 12.0 required |
| Visual Studio | Build Tools 2022 | Or VS 2019+ |

## Migration Notes

### Upgrading from 3.12.6 to 3.13.0

If you have an existing 3.12.6 installation:

1. Run `calculate_colmap_sha512.ps1` to get the new hash
2. Update `vcpkg/ports/colmap/vcpkg.json` version to 3.13.0
3. Update `vcpkg/ports/colmap/portfile.cmake` with new REF and SHA512
4. Clear build cache: `vcpkg remove colmap:x64-windows`
5. Rebuild following Steps 4-7 in README.md

Total time: ~15-20 minutes (much faster than initial build!)

---

**Maintained By:** AI Assistant
**Last Updated:** November 28, 2025
**Status:** ✅ Production Ready

