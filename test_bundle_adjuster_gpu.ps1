# Test Bundle Adjuster with GPU/cuDSS Support
# This script runs bundle_adjuster and captures all output to verify GPU acceleration

Write-Host "======================================" -ForegroundColor Cyan
Write-Host "Bundle Adjuster GPU Test" -ForegroundColor Cyan
Write-Host "======================================`n" -ForegroundColor Cyan

# Paths
$colmapExe = "E:\Programs\Gaussians\colmap_Ceres_2.3\vcpkg\packages\colmap_x64-windows\tools\colmap\colmap.exe"
$inputPath = ".\testData\0"
$outputPath = ".\output"
$logFile = ".\bundle_adjuster_gpu_test.log"

# Ensure COLMAP tools directory is in PATH
$colmapToolsDir = Split-Path $colmapExe -Parent
$env:PATH = "$colmapToolsDir;$env:PATH"

# Check prerequisites
if (-not (Test-Path $colmapExe)) {
    Write-Host "❌ Error: COLMAP executable not found at:" -ForegroundColor Red
    Write-Host "  $colmapExe" -ForegroundColor Gray
    exit 1
}

if (-not (Test-Path $inputPath)) {
    Write-Host "❌ Error: Input path not found:" -ForegroundColor Red
    Write-Host "  $inputPath" -ForegroundColor Gray
    Write-Host "`nPlease ensure you have test data in the testData directory." -ForegroundColor Yellow
    exit 1
}

# Create output directory
New-Item -ItemType Directory -Path $outputPath -Force | Out-Null

Write-Host "Configuration:" -ForegroundColor White
Write-Host "  COLMAP: $colmapExe" -ForegroundColor Gray
Write-Host "  Input:  $inputPath" -ForegroundColor Gray
Write-Host "  Output: $outputPath" -ForegroundColor Gray
Write-Host "  Log:    $logFile`n" -ForegroundColor Gray

Write-Host "Running bundle_adjuster with GPU enabled..." -ForegroundColor Yellow
Write-Host "This may take several minutes. Please wait...`n" -ForegroundColor Yellow

# Run bundle_adjuster and capture output
$startTime = Get-Date

try {
    # Run the command and capture both stdout and stderr
    $output = & $colmapExe bundle_adjuster `
        --input_path $inputPath `
        --output_path $outputPath `
        --BundleAdjustment.use_gpu=1 `
        --log_level 0 `
        2>&1
    
    $exitCode = $LASTEXITCODE
    $endTime = Get-Date
    $duration = $endTime - $startTime
    
    # Save to log file
    @"
======================================
Bundle Adjuster GPU Test Log
======================================
Date: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
Command: colmap bundle_adjuster --input_path $inputPath --output_path $outputPath --BundleAdjustment.use_gpu=1
Exit Code: $exitCode
Duration: $($duration.ToString())

======================================
Output:
======================================
$($output | Out-String)

======================================
Analysis:
======================================
"@ | Out-File -FilePath $logFile -Encoding UTF8
    
    # Display output to console
    Write-Host "--- Command Output ---" -ForegroundColor Cyan
    $output | ForEach-Object { Write-Host $_ }
    Write-Host "`n--- End Output ---`n" -ForegroundColor Cyan
    
    # Analyze output for GPU/cuDSS indicators
    Write-Host "`n======================================" -ForegroundColor Cyan
    Write-Host "Analysis" -ForegroundColor Cyan
    Write-Host "======================================`n" -ForegroundColor Cyan
    
    $outputString = $output | Out-String
    
    # Check for CUDA device detection
    if ($outputString -match "Found \d+ CUDA device") {
        Write-Host "✓ CUDA device detected!" -ForegroundColor Green
        $cudaMatch = [regex]::Match($outputString, "Found \d+ CUDA device.*")
        if ($cudaMatch.Success) {
            Write-Host "  $($cudaMatch.Value)" -ForegroundColor Gray
        }
        Add-Content -Path $logFile -Value "`n✓ CUDA device detected!"
    } else {
        Write-Host "⚠ No CUDA device detection message found" -ForegroundColor Yellow
        Add-Content -Path $logFile -Value "`n⚠ No CUDA device detection message found"
    }
    
    # Check for cuDSS support
    if ($outputString -match "cuDSS") {
        Write-Host "✓ cuDSS mentioned in output!" -ForegroundColor Green
        $cudssMatches = [regex]::Matches($outputString, ".*cuDSS.*")
        foreach ($match in $cudssMatches) {
            Write-Host "  $($match.Value.Trim())" -ForegroundColor Gray
        }
        Add-Content -Path $logFile -Value "✓ cuDSS mentioned in output!"
    } elseif ($outputString -match "compiled without cuDSS") {
        Write-Host "❌ Ceres was compiled WITHOUT cuDSS support!" -ForegroundColor Red
        $errorMatch = [regex]::Match($outputString, ".*compiled without cuDSS.*")
        if ($errorMatch.Success) {
            Write-Host "  $($errorMatch.Value.Trim())" -ForegroundColor Red
        }
        Add-Content -Path $logFile -Value "`n❌ Ceres was compiled WITHOUT cuDSS support!"
    } else {
        Write-Host "⚠ No cuDSS-related messages found" -ForegroundColor Yellow
        Write-Host "  (This may be normal - cuDSS is used silently if available)" -ForegroundColor Gray
        Add-Content -Path $logFile -Value "`n⚠ No cuDSS-related messages found (may be normal)"
    }
    
    # Check for GPU-related warnings
    if ($outputString -match "Falling back to CPU") {
        Write-Host "❌ GPU acceleration failed - falling back to CPU!" -ForegroundColor Red
        $fallbackMatch = [regex]::Match($outputString, ".*Falling back to CPU.*")
        if ($fallbackMatch.Success) {
            Write-Host "  $($fallbackMatch.Value.Trim())" -ForegroundColor Red
        }
        Add-Content -Path $logFile -Value "`n❌ Falling back to CPU!"
    }
    
    # Check completion
    if ($outputString -match "Bundle adjustment report") {
        Write-Host "`n✓ Bundle adjustment completed successfully!" -ForegroundColor Green
        
        # Extract statistics
        if ($outputString -match "Residuals\s*:\s*(\d+)") {
            Write-Host "  Residuals: $($matches[1])" -ForegroundColor Gray
        }
        if ($outputString -match "Iterations\s*:\s*(\d+)") {
            Write-Host "  Iterations: $($matches[1])" -ForegroundColor Gray
        }
        if ($outputString -match "Time\s*:\s*([\d.]+)") {
            Write-Host "  Time: $($matches[1]) seconds" -ForegroundColor Gray
        }
        if ($outputString -match "Elapsed time:\s*([\d.]+)\s*\[minutes\]") {
            Write-Host "  Total: $($matches[1]) minutes" -ForegroundColor Gray
        }
        Add-Content -Path $logFile -Value "`n✓ Bundle adjustment completed successfully!"
    } else {
        Write-Host "`n⚠ Bundle adjustment may not have completed" -ForegroundColor Yellow
        Add-Content -Path $logFile -Value "`n⚠ Bundle adjustment may not have completed"
    }
    
    Write-Host "`nDuration: $($duration.ToString())" -ForegroundColor White
    Write-Host "Exit Code: $exitCode" -ForegroundColor White
    
    Write-Host "`n======================================" -ForegroundColor Cyan
    Write-Host "✓ Full log saved to: $logFile" -ForegroundColor Green
    Write-Host "======================================`n" -ForegroundColor Cyan
    
} catch {
    Write-Host "❌ Error running bundle_adjuster: $_" -ForegroundColor Red
    "Error: $_" | Out-File -FilePath $logFile -Append -Encoding UTF8
    exit 1
}


