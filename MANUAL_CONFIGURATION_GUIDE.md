# Manual Configuration Guide for COLMAP 3.13.0 with CUDA-enabled Ceres 2.3.0

This guide contains detailed instructions for manual modifications that **YOU** must perform to configure vcpkg for building CUDA-enabled Ceres 2.3.0 and COLMAP 3.13.0.

**Current Versions:**
- COLMAP: 3.13.0 (commit 0b31f98133b470eae62811b557dc2bcff1e4f9a5)
- Ceres Solver: 2.3.0
- cuDSS: 0.7 (recommended)

## Prerequisites

Before following this guide, ensure you have:
1. ✅ CUDA Toolkit 12.0+ installed
2. ❌ **cuDSS 0.7+ installed** (REQUIRED - Install this manually first!)
3. ✅ Visual Studio 2019 or later (or Build Tools 2022) installed
4. ✅ vcpkg cloned and bootstrapped (completed by the automated scripts)

**Important:** cuDSS 0.7 is recommended. Avoid installing to paths with spaces (e.g., use `C:\NVIDIA_cuDSS\v0.7` instead of `C:\Program Files\NVIDIA cuDSS\v0.7`).

---

## Step 1: Install cuDSS (MANUAL STEP REQUIRED)

**⚠️ CRITICAL: You must install cuDSS before proceeding!**

### Installation Steps:
1. Download cuDSS from NVIDIA Developer website:
   - URL: https://developer.nvidia.com/cudss-downloads
   - Required version: 0.7 or later
   - File example: `cudss_0.7.0_windows.exe`

2. Run the installer
   - **Recommended location:** `C:\NVIDIA_cuDSS` (no spaces in path!)
   - Default location: `C:\Program Files\NVIDIA cuDSS` (may cause CMake issues)
   - If you choose default, be prepared for potential path quoting problems

3. After installation, locate the CMake configuration directory:
   - Recommended path: `C:\NVIDIA_cuDSS\v0.7\lib\12\cmake\cudss`
   - Default path: `C:\Program Files\NVIDIA cuDSS\v0.7\lib\12\cmake\cudss`
   - This path will be needed in the next steps

4. **Important:** Note down your cuDSS CMake path with forward slashes:
   ```
   Example (recommended): C:/NVIDIA_cuDSS/v0.7/lib/12/cmake/cudss
   Example (default): C:/Program Files/NVIDIA cuDSS/v0.7/lib/12/cmake/cudss
   ```

---

## Step 2: Determine Your cuDSS Path

Run the environment check script to find your cuDSS installation:

```powershell
.\check_environment.ps1
```

If cuDSS is found, the script will display the CMake path. If not found, you must:
- Verify cuDSS is installed
- Manually locate the `cmake\cudss` directory
- Note the full path with forward slashes (/)

**Your cuDSS CMake Path:**
```
_____________________________________________
(Write your actual path here)
```

---

## Step 3: Modify vcpkg Ceres Configuration Files

### File 1: Update Ceres Version in vcpkg.json

**Location:** `E:\Programs\Gaussians\colmap_Ceres_2.3\vcpkg\ports\ceres\vcpkg.json`

**Action Required:**
1. Open the file in a text editor
2. Find the line with `"version":`
3. Change the version from `"2.2.0"` to `"2.3.0"`

**Before:**
```json
{
  "name": "ceres",
  "version": "2.2.0",
  ...
}
```

**After:**
```json
{
  "name": "ceres",
  "version": "2.3.0",
  ...
}
```

### File 2: Replace Ceres portfile.cmake

**Location:** `E:\Programs\Gaussians\colmap_Ceres_2.3\vcpkg\ports\ceres\portfile.cmake`

**Action Required:**

#### Option A: Use the Automated Script (Recommended)
We've created a script that will update the portfile for you. You just need to provide your cuDSS path:

```powershell
# Navigate to the project root
cd E:\Programs\Gaussians\colmap_Ceres_2.3

# Run the configuration script (will be created)
.\configure_vcpkg_ceres.ps1 -CuDSSPath "YOUR_CUDSS_CMAKE_PATH"
```

#### Option B: Manual Replacement
1. **Backup the original file:**
   ```powershell
   Copy-Item "E:\Programs\Gaussians\colmap_Ceres_2.3\vcpkg\ports\ceres\portfile.cmake" `
             "E:\Programs\Gaussians\colmap_Ceres_2.3\vcpkg\ports\ceres\portfile.cmake.backup"
   ```

2. **Copy the new portfile:**
   ```powershell
   Copy-Item "E:\Programs\Gaussians\colmap_Ceres_2.3\Docs\portfilecmake.txt" `
             "E:\Programs\Gaussians\colmap_Ceres_2.3\vcpkg\ports\ceres\portfile.cmake" -Force
   ```

3. **Edit the file to update cuDSS paths:**
   - Open `E:\Programs\Gaussians\colmap_Ceres_2.3\vcpkg\ports\ceres\portfile.cmake`
   - Find the line: `set(CUDSS_CMAKE_PATH "C:/NVIDIA_cuDSS/v0.7/lib/12/cmake/cudss")`
   - Replace with YOUR actual cuDSS CMake path (use forward slashes `/`)

**Example replacement:**
```cmake
# Update this line with your actual path
set(CUDSS_CMAKE_PATH "C:/NVIDIA_cuDSS/v0.7/lib/12/cmake/cudss")
```

---

## Step 4: Build Ceres with CUDA Support

After completing the configuration, build Ceres using the provided script:

```powershell
cd E:\Programs\Gaussians\colmap_Ceres_2.3
.\build_ceres.ps1
```

Or manually run:
```powershell
cd E:\Programs\Gaussians\colmap_Ceres_2.3\vcpkg
.\vcpkg install abseil:x64-windows
.\vcpkg install ceres[core,cuda,lapack,suitesparse]:x64-windows --editable
```

**Expected build time:** 30-60 minutes

---

## Step 5: Build COLMAP 3.13.0 with CUDA Support

### Step 5a: Initial COLMAP Build

Run the initial COLMAP build:
```powershell
cd E:\Programs\Gaussians\colmap_Ceres_2.3\vcpkg
.\vcpkg install colmap[cuda]:x64-windows --editable
```

This will clone COLMAP 3.13.0 source code into:
```
E:\Programs\Gaussians\colmap_Ceres_2.3\vcpkg\buildtrees\colmap\src\3.13.0-<hash>\
```

### Step 5b: Modify COLMAP CMakeLists.txt

**⚠️ IMPORTANT:** After the initial build attempt, you need to modify COLMAP's CMakeLists.txt

1. **Find the COLMAP source directory:**
   ```powershell
   Get-ChildItem "E:\Programs\Gaussians\colmap_Ceres_2.3\vcpkg\buildtrees\colmap\src\" -Directory
   ```
   Look for a directory like `3.11.1-<hash>`

2. **Edit the CMakeLists.txt file:**
   - Open: `E:\Programs\Gaussians\colmap_Ceres_2.3\vcpkg\buildtrees\colmap\src\3.13.0-<hash>\CMakeLists.txt`
   - Add the following line near the top (after `cmake_minimum_required`):
   ```cmake
   set(cudss_DIR "YOUR_CUDSS_CMAKE_PATH")
   ```
   
   **Example:**
   ```cmake
   cmake_minimum_required(VERSION 3.12)
   
   set(cudss_DIR "C:/NVIDIA_cuDSS/v0.7/lib/12/cmake/cudss")
   
   project(COLMAP)
   ```

3. **Rebuild COLMAP:**
   ```powershell
   cd E:\Programs\Gaussians\colmap_Ceres_2.3\vcpkg
   .\vcpkg install colmap[cuda]:x64-windows --editable
   ```

**Expected build time:** 5-10 minutes (COLMAP 3.13.0 builds much faster than previous versions!)

---

## Step 6: Verify the Build

After successful compilation, verify that GPU support is enabled:

```powershell
cd E:\Programs\Gaussians\colmap_Ceres_2.3
.\test_bundle_adjuster_gpu.ps1
```

### Expected Output (Success):

```
Bundle adjustment completed successfully!
  Residuals: 5246224
  Iterations: 80
  Time: 1238.05 seconds
  Total: 20.691 minutes

✓ Full log saved to: .\bundle_adjuster_gpu_test.log
```

**Key Success Indicators:**
- No "compiled without cuDSS support" errors
- Bundle adjustment converges successfully
- GPU memory usage visible in Task Manager during execution

### Error Messages (Failure):

If you see this message, the build failed:

```
Requested to use GPU for bundle adjustment, but Ceres was compiled without cuDSS support. Falling back to CPU-based sparse solvers.
```

**If you see this error:**
1. Verify your cuDSS path is correct in both Ceres and COLMAP configurations
2. Check that cuDSS is properly installed (preferably without spaces in path)
3. Rebuild Ceres and COLMAP with the correct paths
4. Consider reinstalling cuDSS to `C:\NVIDIA_cuDSS\v0.7` if path issues persist

---

## Quick Reference: File Paths

| Item | Path |
|------|------|
| vcpkg root | `E:\Programs\Gaussians\colmap_Ceres_2.3\vcpkg\` |
| Ceres vcpkg.json | `E:\Programs\Gaussians\colmap_Ceres_2.3\vcpkg\ports\ceres\vcpkg.json` |
| Ceres portfile.cmake | `E:\Programs\Gaussians\colmap_Ceres_2.3\vcpkg\ports\ceres\portfile.cmake` |
| Reference portfile | `E:\Programs\Gaussians\colmap_Ceres_2.3\Docs\portfilecmake.txt` |
| Ceres source (after build) | `E:\Programs\Gaussians\colmap_Ceres_2.3\vcpkg\buildtrees\ceres\src\` |
| COLMAP 3.13.0 source | `E:\Programs\Gaussians\colmap_Ceres_2.3\vcpkg\buildtrees\colmap\src\3.13.0-<hash>\` |
| COLMAP executable | `E:\Programs\Gaussians\colmap_Ceres_2.3\vcpkg\packages\colmap_x64-windows\tools\colmap\colmap.exe` |

---

## Troubleshooting

### Issue: vcpkg build fails with "could not find cudss"

**Solution:**
- Verify cuDSS is installed
- Check that your cuDSS CMake path is correct
- Ensure you used forward slashes (/) not backslashes (\)
- Verify the path actually contains `cudss-config.cmake` or similar files

### Issue: CUDA not detected during build

**Solution:**
- Verify CUDA is in your PATH: `nvcc --version`
- Check CUDA_PATH environment variable
- Restart your terminal/PowerShell session
- Reboot if necessary

### Issue: Visual Studio not found

**Solution:**
- Install Visual Studio 2019 or later
- Ensure "Desktop development with C++" workload is installed
- Restart your terminal/PowerShell session

### Issue: Build takes too long or runs out of memory

**Solution:**
- Close other applications
- Consider building without `--editable` flag for production builds
- Use `--editable` only for development/debugging

---

## Summary Checklist

Before running the build scripts:

- [ ] cuDSS is installed
- [ ] cuDSS CMake path is identified and noted
- [ ] vcpkg is cloned and bootstrapped (✅ done by script)
- [ ] Ceres `vcpkg.json` version updated to "2.3.0"
- [ ] Ceres `portfile.cmake` updated with your cuDSS path
- [ ] Ready to run `build_ceres.ps1`

After Ceres builds:

- [ ] Run `build_colmap_initial.ps1` (initial build)
- [ ] Locate COLMAP source directory
- [ ] Edit COLMAP `CMakeLists.txt` with cuDSS path
- [ ] Run `build_colmap_final.ps1` (final build)
- [ ] Run `test_colmap_gpu.ps1` to verify

---

**Next Steps:** Return to the main build process and run the automated build scripts.

