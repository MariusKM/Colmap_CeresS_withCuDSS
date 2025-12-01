# Environment Check Script for COLMAP with CUDA-enabled Ceres
# This script checks all prerequisites needed for building COLMAP with CUDA support

Write-Host "======================================" -ForegroundColor Cyan
Write-Host "COLMAP CUDA Build Environment Check" -ForegroundColor Cyan
Write-Host "======================================`n" -ForegroundColor Cyan

$allChecks = @()

# Check 1: CUDA Installation
Write-Host "1. Checking CUDA Installation..." -ForegroundColor Yellow
$cudaCheck = @{
    Name = "CUDA"
    Status = $false
    Details = ""
}

try {
    $nvccVersion = & nvcc --version 2>&1
    if ($LASTEXITCODE -eq 0) {
        $cudaCheck.Status = $true
        $versionMatch = $nvccVersion | Select-String -Pattern "release (\d+\.\d+)"
        if ($versionMatch) {
            $cudaVersion = $versionMatch.Matches[0].Groups[1].Value
            $cudaCheck.Details = "CUDA $cudaVersion installed"
            Write-Host "   ✓ CUDA is installed: Version $cudaVersion" -ForegroundColor Green
            
            # Check if version is 12.0 or higher
            $majorVersion = [int]($cudaVersion.Split('.')[0])
            if ($majorVersion -ge 12) {
                Write-Host "   ✓ CUDA version meets requirements (12.0+)" -ForegroundColor Green
            } else {
                Write-Host "   ✗ CUDA version $cudaVersion is below required 12.0+" -ForegroundColor Red
                $cudaCheck.Details += " (Version too old, need 12.0+)"
            }
        }
        
        # Check CUDA_PATH environment variable
        if ($env:CUDA_PATH) {
            Write-Host "   ✓ CUDA_PATH environment variable: $env:CUDA_PATH" -ForegroundColor Green
        } else {
            Write-Host "   ! CUDA_PATH environment variable not set" -ForegroundColor Yellow
        }
    }
} catch {
    $cudaCheck.Details = "CUDA not found or nvcc not in PATH"
    Write-Host "   ✗ CUDA not found or nvcc not in PATH" -ForegroundColor Red
}

$allChecks += $cudaCheck

# Check 2: cuDSS Installation
Write-Host "`n2. Checking cuDSS Installation..." -ForegroundColor Yellow
$cuDSSCheck = @{
    Name = "cuDSS"
    Status = $false
    Details = ""
    Path = ""
}

$possiblePaths = @(
    "C:\Program Files\NVIDIA cuDSS",
    "C:\Program Files\NVIDIA GPU Computing Toolkit\cuDSS",
    "${env:USERPROFILE}\Desktop\NVIDIA_cuDSS",
    "${env:USERPROFILE}\Desktop\NVIDIA cuDSS"
)

foreach ($path in $possiblePaths) {
    if (Test-Path $path) {
        $cuDSSCheck.Status = $true
        $cuDSSCheck.Path = $path
        Write-Host "   ✓ cuDSS found at: $path" -ForegroundColor Green
        
        # Look for cmake directory
        $cmakePath = Get-ChildItem -Path $path -Recurse -Filter "cmake" -Directory -ErrorAction SilentlyContinue | 
                     Where-Object { $_.FullName -like "*\lib\*\cmake\cudss" } | 
                     Select-Object -First 1
        
        if ($cmakePath) {
            $cuDSSCheck.Details = "CMake path: $($cmakePath.FullName)"
            Write-Host "   ✓ cuDSS CMake files found at: $($cmakePath.FullName)" -ForegroundColor Green
        } else {
            Write-Host "   ! Could not locate cuDSS cmake files" -ForegroundColor Yellow
        }
        break
    }
}

if (-not $cuDSSCheck.Status) {
    $cuDSSCheck.Details = "cuDSS not found in standard locations"
    Write-Host "   ✗ cuDSS not found in standard locations" -ForegroundColor Red
    Write-Host "   Searched: " -NoNewline
    $possiblePaths | ForEach-Object { Write-Host "`n     - $_" -ForegroundColor Gray }
}

$allChecks += $cuDSSCheck

# Check 3: Git
Write-Host "`n3. Checking Git Installation..." -ForegroundColor Yellow
$gitCheck = @{
    Name = "Git"
    Status = $false
    Details = ""
}

try {
    $gitVersion = & git --version 2>&1
    if ($LASTEXITCODE -eq 0) {
        $gitCheck.Status = $true
        $gitCheck.Details = $gitVersion.ToString().Trim()
        Write-Host "   ✓ Git is installed: $($gitCheck.Details)" -ForegroundColor Green
    }
} catch {
    $gitCheck.Details = "Git not found"
    Write-Host "   ✗ Git not found in PATH" -ForegroundColor Red
}

$allChecks += $gitCheck

# Check 4: CMake
Write-Host "`n4. Checking CMake Installation..." -ForegroundColor Yellow
$cmakeCheck = @{
    Name = "CMake"
    Status = $false
    Details = ""
}

try {
    $cmakeVersion = & cmake --version 2>&1
    if ($LASTEXITCODE -eq 0) {
        $cmakeCheck.Status = $true
        $versionLine = ($cmakeVersion | Select-Object -First 1).ToString()
        $cmakeCheck.Details = $versionLine
        Write-Host "   ✓ CMake is installed: $versionLine" -ForegroundColor Green
    }
} catch {
    $cmakeCheck.Details = "CMake not found in PATH"
    Write-Host "   ✗ CMake not found in PATH" -ForegroundColor Red
    Write-Host "   Note: CMake will be installed by vcpkg if not present" -ForegroundColor Yellow
}

$allChecks += $cmakeCheck

# Check 5: Visual Studio / Build Tools
Write-Host "`n5. Checking Visual Studio / Build Tools Installation..." -ForegroundColor Yellow
$vsCheck = @{
    Name = "Visual Studio"
    Status = $false
    Details = ""
    HasCppTools = $false
}

$vswherePath = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
if (Test-Path $vswherePath) {
    try {
        # Query for all instances (IDE and Build Tools)
        $vsInstances = & $vswherePath -all -prerelease -products * -format json | ConvertFrom-Json
        
        if ($vsInstances) {
            $foundInstalls = @()
            $hasCppBuildTools = $false
            
            foreach ($instance in $vsInstances) {
                $displayName = $instance.displayName
                $version = $instance.installationVersion
                $majorVersion = [int]($version.Split('.')[0])
                $installPath = $instance.installationPath
                
                # Check if it has C++ build tools by looking for various indicators
                $hasDesktopCpp = $false
                if ($instance.packages) {
                    $cppPackages = $instance.packages | Where-Object { 
                        $_.id -match "Microsoft.VisualStudio.Component.VC.Tools" -or
                        $_.id -match "Microsoft.VisualStudio.Workload.VCTools" -or
                        $_.id -match "Microsoft.VisualStudio.Workload.NativeDesktop" -or
                        $_.id -match "Microsoft.VisualStudio.Component.VC" -or
                        $_.id -match "Microsoft.VisualStudio.ComponentGroup.NativeDesktop.Core" -or
                        $_.id -match "Microsoft.Component.MSBuild"
                    }
                    if ($cppPackages) {
                        $hasDesktopCpp = $true
                        $hasCppBuildTools = $true
                    }
                }
                
                # Alternative check: Look for cl.exe (MSVC compiler) in the installation
                if (-not $hasDesktopCpp -and $installPath) {
                    $clExePath = Get-ChildItem -Path $installPath -Recurse -Filter "cl.exe" -ErrorAction SilentlyContinue | Select-Object -First 1
                    if ($clExePath) {
                        $hasDesktopCpp = $true
                        $hasCppBuildTools = $true
                    }
                }
                
                $foundInstalls += @{
                    Name = $displayName
                    Version = $version
                    MajorVersion = $majorVersion
                    HasCpp = $hasDesktopCpp
                    Path = $installPath
                }
            }
            
            if ($foundInstalls.Count -gt 0) {
                $vsCheck.Status = $true
                
                foreach ($install in $foundInstalls) {
                    $versionName = switch ($install.MajorVersion) {
                        17 { "2022" }
                        16 { "2019" }
                        15 { "2017" }
                        default { "v$($install.MajorVersion)" }
                    }
                    
                    $cppStatus = if ($install.HasCpp) { "✓ C++ tools" } else { "✗ No C++ tools" }
                    $cppColor = if ($install.HasCpp) { "Green" } else { "Yellow" }
                    
                    Write-Host "   ✓ Found: $($install.Name) ($versionName)" -ForegroundColor Green
                    Write-Host "     Version: $($install.Version)" -ForegroundColor White
                    Write-Host "     $cppStatus" -ForegroundColor $cppColor
                    
                    if ($install.HasCpp) {
                        $vsCheck.HasCppTools = $true
                    }
                }
                
                # Check if we have suitable version
                $latestVersion = ($foundInstalls | Sort-Object -Property MajorVersion -Descending | Select-Object -First 1).MajorVersion
                if ($latestVersion -ge 16) {
                    Write-Host "`n   ✓ Latest version is 2019 or later (suitable for CUDA)" -ForegroundColor Green
                } else {
                    Write-Host "`n   ! Latest version is older than 2019" -ForegroundColor Yellow
                }
                
                if ($vsCheck.HasCppTools) {
                    Write-Host "   ✓ C++ build tools are installed" -ForegroundColor Green
                    $vsCheck.Details = "Build Tools available"
                } else {
                    Write-Host "   ⚠ Warning: C++ Desktop Development workload not detected" -ForegroundColor Yellow
                    Write-Host "     This is required for building C++ projects" -ForegroundColor Yellow
                    $vsCheck.Details = "C++ tools missing"
                    $vsCheck.Status = $false
                }
            }
        } else {
            Write-Host "   ✗ No Visual Studio or Build Tools installations found" -ForegroundColor Red
            $vsCheck.Details = "Not installed"
        }
    } catch {
        Write-Host "   ⚠ Warning: Could not query Visual Studio details: $_" -ForegroundColor Yellow
        Write-Host "   vswhere.exe may not be working properly" -ForegroundColor Gray
        $vsCheck.Details = "Query failed"
    }
} else {
    Write-Host "   ✗ vswhere.exe not found at: $vswherePath" -ForegroundColor Red
    Write-Host "   Visual Studio or Build Tools may not be installed" -ForegroundColor Red
    $vsCheck.Details = "vswhere not found"
}

$allChecks += $vsCheck

# Check 6: vcpkg
Write-Host "`n6. Checking vcpkg Installation..." -ForegroundColor Yellow
$vcpkgCheck = @{
    Name = "vcpkg"
    Status = $false
    Details = ""
}

$vcpkgPaths = @(
    ".\vcpkg",
    "C:\vcpkg",
    "${env:USERPROFILE}\vcpkg"
)

foreach ($path in $vcpkgPaths) {
    if (Test-Path "$path\vcpkg.exe") {
        $vcpkgCheck.Status = $true
        $vcpkgCheck.Details = "Found at $path"
        Write-Host "   ✓ vcpkg found at: $path" -ForegroundColor Green
        break
    }
}

if (-not $vcpkgCheck.Status) {
    $vcpkgCheck.Details = "vcpkg not found (will be cloned later)"
    Write-Host "   - vcpkg not found (will be cloned and bootstrapped)" -ForegroundColor Yellow
} else {
    # If vcpkg exists and VS is installed, verify vcpkg can see the build tools
    if ($vsCheck.Status) {
        Write-Host "`n   Verifying vcpkg can detect build tools..." -ForegroundColor Gray
        try {
            $vcpkgPath = $vcpkgPaths | Where-Object { Test-Path "$_\vcpkg.exe" } | Select-Object -First 1
            $vcpkgVersion = & "$vcpkgPath\vcpkg.exe" version 2>&1
            if ($vcpkgVersion -match "version") {
                Write-Host "   ✓ vcpkg is functional and should detect build tools" -ForegroundColor Green
            }
        } catch {
            Write-Host "   ! Could not verify vcpkg functionality" -ForegroundColor Yellow
        }
    }
}

$allChecks += $vcpkgCheck

# Summary
Write-Host "`n======================================" -ForegroundColor Cyan
Write-Host "Summary" -ForegroundColor Cyan
Write-Host "======================================`n" -ForegroundColor Cyan

$passedChecks = ($allChecks | Where-Object { $_.Status -eq $true }).Count
$totalChecks = $allChecks.Count

Write-Host "Passed: $passedChecks / $totalChecks checks`n" -ForegroundColor Cyan

# Critical requirements
$criticalFailed = @()
if (-not ($allChecks | Where-Object { $_.Name -eq "CUDA" }).Status) {
    $criticalFailed += "CUDA"
}
if (-not ($allChecks | Where-Object { $_.Name -eq "cuDSS" }).Status) {
    $criticalFailed += "cuDSS"
}
$vsCheckResult = $allChecks | Where-Object { $_.Name -eq "Visual Studio" }
if (-not $vsCheckResult.Status) {
    $criticalFailed += "Visual Studio / Build Tools"
} elseif ($vsCheckResult.HasCppTools -eq $false) {
    $criticalFailed += "Visual Studio C++ Build Tools (installed but C++ workload missing)"
}
if (-not ($allChecks | Where-Object { $_.Name -eq "Git" }).Status) {
    $criticalFailed += "Git"
}

if ($criticalFailed.Count -gt 0) {
    Write-Host "⚠ CRITICAL: The following required components are missing:" -ForegroundColor Red
    $criticalFailed | ForEach-Object { Write-Host "   - $_" -ForegroundColor Red }
    Write-Host "`nYou must install these manually before proceeding.`n" -ForegroundColor Red
} else {
    Write-Host "✓ All critical components are installed!" -ForegroundColor Green
    Write-Host "You can proceed with the build process.`n" -ForegroundColor Green
}

# Export cuDSS path if found
if ($cuDSSCheck.Status -and $cuDSSCheck.Path) {
    # Try to find the cmake path
    $cmakePath = Get-ChildItem -Path $cuDSSCheck.Path -Recurse -Filter "cudss" -Directory -ErrorAction SilentlyContinue | 
                 Where-Object { $_.FullName -like "*\lib\*\cmake\cudss" } | 
                 Select-Object -First 1
    
    if ($cmakePath) {
        $cmakePathFormatted = $cmakePath.FullName -replace '\\', '/'
        Write-Host "cuDSS CMake Path (for configuration files):" -ForegroundColor Cyan
        Write-Host "   $cmakePathFormatted" -ForegroundColor White
        Write-Host "`nYou will need to use this path in:" -ForegroundColor Yellow
        Write-Host "   - Ceres portfile.cmake (lines 60 and 68)" -ForegroundColor Yellow
        Write-Host "   - COLMAP CMakeLists.txt" -ForegroundColor Yellow
    }
}

Write-Host "`n======================================`n" -ForegroundColor Cyan

# Return status for scripting
if ($criticalFailed.Count -eq 0) {
    exit 0
} else {
    exit 1
}

