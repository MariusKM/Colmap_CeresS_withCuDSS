# Clone GLOMAP Repository
# Clones GLOMAP from GitHub for building with GPU-enabled COLMAP

param(
    [string]$TargetDir = "..\..\glomap",
    [string]$Branch = "main"
)

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Clone GLOMAP Repository" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

$repoUrl = "https://github.com/colmap/glomap.git"

# Check if directory already exists
if (Test-Path $TargetDir) {
    Write-Host "⚠ Directory already exists: $TargetDir" -ForegroundColor Yellow
    $response = Read-Host "Do you want to (1) Use existing, (2) Delete and re-clone, or (3) Cancel? [1/2/3]"
    
    switch ($response) {
        "1" {
            Write-Host "`n✓ Using existing GLOMAP directory" -ForegroundColor Green
            Write-Host "Path: $(Resolve-Path $TargetDir)" -ForegroundColor Gray
            
            # Check if it's a git repo
            if (Test-Path "$TargetDir\.git") {
                Push-Location $TargetDir
                $currentBranch = git rev-parse --abbrev-ref HEAD 2>&1
                $latestCommit = git rev-parse --short HEAD 2>&1
                Pop-Location
                
                Write-Host "`nRepository Info:" -ForegroundColor White
                Write-Host "  Branch: $currentBranch" -ForegroundColor Gray
                Write-Host "  Commit: $latestCommit" -ForegroundColor Gray
            }
            
            Write-Host "`nYou can proceed with:" -ForegroundColor White
            Write-Host "  .\build_glomap.ps1" -ForegroundColor Cyan
            Write-Host "`n========================================`n" -ForegroundColor Cyan
            exit 0
        }
        "2" {
            Write-Host "`nRemoving existing directory..." -ForegroundColor Yellow
            Remove-Item -Recurse -Force $TargetDir
            Write-Host "✓ Removed" -ForegroundColor Green
        }
        "3" {
            Write-Host "`nOperation cancelled" -ForegroundColor Yellow
            exit 0
        }
        default {
            Write-Host "`nInvalid choice. Operation cancelled" -ForegroundColor Red
            exit 1
        }
    }
}

# Check if git is available
$gitCmd = Get-Command git -ErrorAction SilentlyContinue
if (-not $gitCmd) {
    Write-Host "❌ Git is not installed or not in PATH" -ForegroundColor Red
    Write-Host "Please install Git from: https://git-scm.com/" -ForegroundColor Yellow
    exit 1
}

Write-Host "Cloning GLOMAP..." -ForegroundColor Yellow
Write-Host "  Repository: $repoUrl" -ForegroundColor Gray
Write-Host "  Branch: $Branch" -ForegroundColor Gray
Write-Host "  Destination: $TargetDir" -ForegroundColor Gray
Write-Host "`nThis may take a few minutes...`n" -ForegroundColor Gray

try {
    $cloneOutput = git clone --branch $Branch --depth 1 $repoUrl $TargetDir 2>&1
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ Repository cloned successfully" -ForegroundColor Green
        
        # Get commit info
        Push-Location $TargetDir
        $latestCommit = git rev-parse --short HEAD 2>&1
        $commitMsg = git log -1 --pretty=%B 2>&1 | Select-Object -First 1
        Pop-Location
        
        Write-Host "`n========================================" -ForegroundColor Cyan
        Write-Host "✓ GLOMAP Cloned Successfully!" -ForegroundColor Green
        Write-Host "========================================`n" -ForegroundColor Cyan
        
        Write-Host "Location: $(Resolve-Path $TargetDir)" -ForegroundColor White
        Write-Host "Branch: $Branch" -ForegroundColor White
        Write-Host "Latest Commit: $latestCommit" -ForegroundColor White
        Write-Host "  $commitMsg" -ForegroundColor Gray
        
        Write-Host "`nNext Steps:" -ForegroundColor White
        Write-Host "  1. Review build configuration (optional)" -ForegroundColor Gray
        Write-Host "  2. Run: .\build_glomap.ps1" -ForegroundColor Cyan
        
        Write-Host "`n========================================`n" -ForegroundColor Cyan
    } else {
        Write-Host "❌ Git clone failed" -ForegroundColor Red
        Write-Host "Error output:" -ForegroundColor Yellow
        Write-Host $cloneOutput -ForegroundColor Gray
        exit 1
    }
} catch {
    Write-Host "❌ Error during clone: $_" -ForegroundColor Red
    exit 1
}

