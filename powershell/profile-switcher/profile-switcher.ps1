# ================================================
# EQ + nParse Config Switcher (Improved Elevation)
# Now handles direct "Open with PowerShell" more gracefully
# ================================================

# ================== CONFIGURATION ==================
$eqDir     = "C:\Everquest"
$nparseDir = "C:\nparse"

$characters = @("pivo")
# ==================================================

# ================== SELF-ELEVATION (IMPROVED) ==================
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    $scriptPath = $PSCommandPath
    Write-Host "Requesting Administrator privileges..." -ForegroundColor Yellow
    Start-Process powershell.exe -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -NoExit -File `"$scriptPath`""
    exit
}

# Ensure directories exist
if (-not (Test-Path $eqDir)) {
    Write-Host "ERROR: EverQuest directory not found at $eqDir" -ForegroundColor Red
    Write-Host "Update `$eqDir at the top of the script." -ForegroundColor Yellow
    Read-Host "`nPress Enter to exit"
    exit
}

if (-not (Test-Path $nparseDir)) {
    Write-Host "WARNING: nParse directory not found at $nparseDir" -ForegroundColor Yellow
}

Set-Location $eqDir

# ================== HELPER FUNCTION (unchanged) ==================
function Switch-ConfigFile {
    param(
        [string]$Directory,
        [string]$BaseName,
        [string]$BackupSuffix,
        [string]$SourceSuffix
    )

    $currentFile = Join-Path $Directory $BaseName
    $backupFile  = Join-Path $Directory "$BaseName$BackupSuffix"
    $sourceFile  = Join-Path $Directory "$BaseName$SourceSuffix"

    if (-not (Test-Path $currentFile)) {
        Write-Host "  WARNING: $BaseName not found - skipping" -ForegroundColor Yellow
        return $false
    }
    if (-not (Test-Path $sourceFile)) {
        Write-Host "  WARNING: $BaseName$SourceSuffix not found - skipping (create it once manually)" -ForegroundColor Yellow
        return $false
    }

    if (Test-Path $backupFile) { Remove-Item $backupFile -Force -ErrorAction SilentlyContinue }

    try {
        Rename-Item -Path $currentFile -NewName "$BaseName$BackupSuffix" -ErrorAction Stop
        Copy-Item -Path $sourceFile -Destination $currentFile -ErrorAction Stop
        Write-Host "  SUCCESS: Switched $BaseName" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Host "  FAILURE on $BaseName: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# ================== MENU ==================
Clear-Host
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "   EverQuest + nParse Config Switcher" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "1) Restore 1440p (Desktop / 34`" Ultrawide)" -ForegroundColor White
Write-Host "2) Restore 2.5k (Laptop / 14`" display)" -ForegroundColor White
Write-Host "Q) Quit" -ForegroundColor White
Write-Host ""

$choice = Read-Host "Enter your choice (1, 2, or Q)"

# ================== PROCESS CHOICE ==================
$switched = 0
switch ($choice.ToUpper()) {
    '1' {
        $actionDesc   = "1440p Desktop (34`" Ultrawide)"
        $backupSuffix = ".laptop"
        $sourceSuffix = ".desktop"
        Write-Host "`nSwitching to $actionDesc..." -ForegroundColor Cyan

        if (Switch-ConfigFile $eqDir "eqclient.ini" $backupSuffix $sourceSuffix) { $switched++ }
        foreach ($char in $characters) {
            $uiBase = "UI_${char}_project1999.ini"
            if (Switch-ConfigFile $eqDir $uiBase $backupSuffix $sourceSuffix) { $switched++ }
        }
        if (Switch-ConfigFile $nparseDir "nparse.config.json" $backupSuffix $sourceSuffix) { $switched++ }
    }
    '2' {
        $actionDesc   = "2.5k Laptop (14`" display)"
        $backupSuffix = ".desktop"
        $sourceSuffix = ".laptop"
        Write-Host "`nSwitching to $actionDesc..." -ForegroundColor Cyan

        if (Switch-ConfigFile $eqDir "eqclient.ini" $backupSuffix $sourceSuffix) { $switched++ }
        foreach ($char in $characters) {
            $uiBase = "UI_${char}_project1999.ini"
            if (Switch-ConfigFile $eqDir $uiBase $backupSuffix $sourceSuffix) { $switched++ }
        }
        if (Switch-ConfigFile $nparseDir "nparse.config.json" $backupSuffix $sourceSuffix) { $switched++ }
    }
    'Q' { exit }
    default {
        Write-Host "`nInvalid choice." -ForegroundColor Yellow
        exit
    }
}

Write-Host "`nOVERALL SUCCESS: Switched $switched file(s) to $actionDesc" -ForegroundColor Green

# ================== EXIT PROMPT ==================
Write-Host "`nPress Q to exit the script..." -ForegroundColor Cyan
$null = Read-Host
Write-Host "Goodbye!" -ForegroundColor Cyan
