# ================================================
# EQ Config + UI + nParse Switcher
# Now also switches nparse.config.json between desktop and laptop versions
# Run from desktop shortcut (set to "Run as administrator")
# ================================================

# ================== CONFIGURATION ==================
# Change these ONLY if your folders are in a different location
$eqDir     = "C:\Everquest"
$nparseDir = "C:\nparse"                  # ← nParse config folder

# List of character names whose UI settings you want to auto-switch.
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

# Optional: Warn if nParse folder is missing (but still continue)
if (-not (Test-Path $nparseDir)) {
    Write-Host "WARNING: nParse directory not found at $nparseDir" -ForegroundColor Yellow
    Write-Host "nParse config switching will be skipped until the folder exists." -ForegroundColor Yellow
}

# Set working directory to EQ (for consistency)
Set-Location $eqDir

# ================== HELPER FUNCTION ==================
function Switch-ConfigFile {
    param(
        [string]$Directory,     # Folder where the file lives
        [string]$BaseName,      # e.g. "eqclient.ini", "UI_pivo_project1999.ini", "nparse.config.json"
        [string]$BackupSuffix,  # ".laptop" or ".desktop"
        [string]$SourceSuffix   # ".desktop" or ".laptop"
    )

    $currentFile = Join-Path $Directory $BaseName
    $backupFile  = Join-Path $Directory "$BaseName$BackupSuffix"
    $sourceFile  = Join-Path $Directory "$BaseName$SourceSuffix"

    if (-not (Test-Path $currentFile)) {
        Write-Host "  WARNING: $BaseName not found in $Directory - skipping" -ForegroundColor Yellow
        return $false
    }
    if (-not (Test-Path $sourceFile)) {
        Write-Host "  WARNING: $BaseName$SourceSuffix not found in $Directory - skipping (create it once manually)" -ForegroundColor Yellow
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
Write-Host "   EverQuest + nParse Config Switcher" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "1) Restore 1440p (Desktop / 34`" Ultrawide) - eqclient + UI + nParse" -ForegroundColor White
Write-Host "2) Restore 2.5k (Laptop / 14`" display) - eqclient + UI + nParse" -ForegroundColor White
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

        Write-Host "`nSwitching to $actionDesc..." -ForegroundColor Cyan
        $switched = 0

        # eqclient.ini
        if (Switch-ConfigFile $eqDir "eqclient.ini" $backupSuffix $sourceSuffix) { $switched++ }

        # UI files for each character
        foreach ($char in $characters) {
            $uiBase = "UI_${char}_project1999.ini"
            if (Switch-ConfigFile $eqDir $uiBase $backupSuffix $sourceSuffix) { $switched++ }
        }

        # nparse.config.json
        if (Switch-ConfigFile $nparseDir "nparse.config.json" $backupSuffix $sourceSuffix) { $switched++ }

        Write-Host "`nOVERALL SUCCESS: Switched $switched file(s) to $actionDesc" -ForegroundColor Green
    }

    '2' {
        # Option 2: Switch to Laptop / 2.5k
        $actionDesc   = "2.5k Laptop (14`" display)"
        $backupSuffix = ".desktop"
        $sourceSuffix = ".laptop"

        Write-Host "`nSwitching to $actionDesc..." -ForegroundColor Cyan
        $switched = 0

        # eqclient.ini
        if (Switch-ConfigFile $eqDir "eqclient.ini" $backupSuffix $sourceSuffix) { $switched++ }

        # UI files for each character
        foreach ($char in $characters) {
            $uiBase = "UI_${char}_project1999.ini"
            if (Switch-ConfigFile $eqDir $uiBase $backupSuffix $sourceSuffix) { $switched++ }
        }

        # nparse.config.json
        if (Switch-ConfigFile $nparseDir "nparse.config.json" $backupSuffix $sourceSuffix) { $switched++ }

        Write-Host "`nOVERALL SUCCESS: Switched $switched file(s) to $actionDesc" -ForegroundColor Green
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
