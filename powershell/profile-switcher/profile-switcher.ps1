# ================================================
# EQ Config + UI Switcher - eqclient.ini + Per-Character UI Toggle
# Now also switches UI_CHARACTERNAME_project1999.ini files for listed characters
# Run from desktop shortcut (set to "Run as administrator")
# ================================================

# ================== CONFIGURATION ==================
# Change this ONLY if your EverQuest folder is not the default location
$eqDir = "C:\Everquest"

# List of character names whose UI settings you want to auto-switch.
# Add or remove names here (e.g. "pivo", "myalt", "mainchar").
# Only these characters will have their UI files renamed/copied.
$characters = @("pivo")
# ==================================================

# Self-elevate to Administrator (UAC prompt if needed)
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    $scriptPath = $MyInvocation.MyCommand.Path
    Start-Process powershell.exe -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`""
    exit
}

# Ensure the EverQuest directory exists
if (-not (Test-Path $eqDir)) {
    Write-Host "ERROR: EverQuest directory not found at $eqDir" -ForegroundColor Red
    Write-Host "Please update the `$eqDir variable at the top of the script." -ForegroundColor Yellow
    Read-Host "`nPress Enter to exit"
    exit
}

# Set working directory
Set-Location $eqDir

# ================== HELPER FUNCTION ==================
function Switch-EQFile {
    param(
        [string]$BaseName,      # e.g. "eqclient.ini" or "UI_pivo_project1999.ini"
        [string]$BackupSuffix,  # ".laptop" or ".desktop"
        [string]$SourceSuffix   # ".desktop" or ".laptop"
    )

    $currentFile = Join-Path $eqDir $BaseName
    $backupFile  = Join-Path $eqDir "$BaseName$BackupSuffix"
    $sourceFile  = Join-Path $eqDir "$BaseName$SourceSuffix"

    if (-not (Test-Path $currentFile)) {
        Write-Host "  WARNING: $BaseName not found - skipping" -ForegroundColor Yellow
        return $false
    }
    if (-not (Test-Path $sourceFile)) {
        Write-Host "  WARNING: $BaseName$SourceSuffix not found - skipping (create it once manually)" -ForegroundColor Yellow
        return $false
    }

    # Remove old backup if it exists
    if (Test-Path $backupFile) {
        Remove-Item $backupFile -Force -ErrorAction SilentlyContinue
    }

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
Write-Host "   EverQuest Config + UI Switcher" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "1) Restore 1440p eqclient.ini + UI (Desktop / 34`" Ultrawide)" -ForegroundColor White
Write-Host "2) Restore laptop 2.5k eqclient.ini + UI (Laptop / 14`" display)" -ForegroundColor White
Write-Host "Q) Quit" -ForegroundColor White
Write-Host ""

$choice = Read-Host "Enter your choice (1, 2, or Q)"

# ================== PROCESS CHOICE ==================
switch ($choice.ToUpper()) {
    '1' {
        # Option 1: Switch to Desktop / 1440p Ultrawide
        $actionDesc   = "1440p Desktop (34`" Ultrawide)"
        $backupSuffix = ".laptop"
        $sourceSuffix = ".desktop"

        try {
            Write-Host "`nSwitching to $actionDesc..." -ForegroundColor Cyan

            $switched = 0

            # eqclient.ini
            if (Switch-EQFile "eqclient.ini" $backupSuffix $sourceSuffix) { $switched++ }

            # UI files for each character
            foreach ($char in $characters) {
                $uiBase = "UI_${char}_project1999.ini"
                if (Switch-EQFile $uiBase $backupSuffix $sourceSuffix) { $switched++ }
            }

            Write-Host "`nOVERALL SUCCESS: Switched $switched file(s) to $actionDesc" -ForegroundColor Green
        }
        catch {
            Write-Host "`nFAILURE: $($_.Exception.Message)" -ForegroundColor Red
        }
    }

    '2' {
        # Option 2: Switch to Laptop / 2.5k
        $actionDesc   = "2.5k Laptop (14`" display)"
        $backupSuffix = ".desktop"
        $sourceSuffix = ".laptop"

        try {
            Write-Host "`nSwitching to $actionDesc..." -ForegroundColor Cyan

            $switched = 0

            # eqclient.ini
            if (Switch-EQFile "eqclient.ini" $backupSuffix $sourceSuffix) { $switched++ }

            # UI files for each character
            foreach ($char in $characters) {
                $uiBase = "UI_${char}_project1999.ini"
                if (Switch-EQFile $uiBase $backupSuffix $sourceSuffix) { $switched++ }
            }

            Write-Host "`nOVERALL SUCCESS: Switched $switched file(s) to $actionDesc" -ForegroundColor Green
        }
        catch {
            Write-Host "`nFAILURE: $($_.Exception.Message)" -ForegroundColor Red
        }
    }

    'Q' {
        Write-Host "`nExiting..." -ForegroundColor Yellow
        exit
    }

    default {
        Write-Host "`nInvalid choice. Exiting..." -ForegroundColor Yellow
        exit
    }
}

# ================== EXIT PROMPT ==================
Write-Host "`nPress Q to exit the script..." -ForegroundColor Cyan
$null = Read-Host
Write-Host "Goodbye!" -ForegroundColor Cyan
