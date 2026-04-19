# EQ + nParse Config Switcher

A simple, interactive PowerShell script that instantly switches your **eqclient.ini**, per-character UI layout files, **and** nParse configuration between:

- **Desktop mode** – 1440p / 34" ultrawide monitor (`.desktop` files)
- **Laptop mode** – Native 2560×1600 (2.5K) on a 14" ASUS TUF Gaming A14 display (`.laptop` files)

---

## Features

- One-click switching via an interactive menu
- Automatically handles **three** types of files:
  - `eqclient.ini` (graphics/resolution settings)
  - `UI_CHARACTERNAME_project1999.ini` files for any characters you specify
  - `nparse.config.json` (nParse overlay settings)
- Safe rename + copy logic (never loses your current config)
- Fully configurable paths for EverQuest and nParse folders
- Runs as Administrator (required for file operations)
- Clear success/failure feedback with per-file status
- Works with a desktop shortcut for instant access

---

## Requirements

- Windows 10 or 11
- PowerShell 5.1+ (pre-installed on Windows)
- EverQuest installed (default path: `C:\Everquest`)
- nParse installed (default path: `C:\nparse`)
- Administrator rights when running the script

---

## Installation

1. Download `profile-switcher.ps1` and place it anywhere on your PC (recommended: `C:\Scripts\profile-switcher.ps1` or your Documents folder).

2. **Create a desktop shortcut** (highly recommended):
   - Right-click on your desktop → **New** → **Shortcut**
   - Target:
     ```
     powershell.exe -NoProfile -ExecutionPolicy Bypass -File "C:\Scripts\profile-switcher.ps1"
     ```
   - Name it something like `Switch EQ + nParse Config`
   - Right-click the shortcut → **Properties** → **Advanced** → check **"Run as administrator"** → OK

3. **Configure the script** (edit the top of the `.ps1` file):
   ```powershell
   $eqDir     = "C:\Everquest"          # Change only if your EQ folder is elsewhere
   $nparseDir = "C:\nparse"             # Change only if nParse is installed elsewhere
   $characters = @("pivo")              # Add your character names here, e.g. @("pivo", "main", "alt")
   ```

---

## Usage

1. Double-click the desktop shortcut.
2. A UAC prompt will appear — click **Yes**.
3. Choose:
   - `1` → Switch to **1440p Desktop / Ultrawide** (eqclient + UI + nParse)
   - `2` → Switch to **2.5k Laptop** (eqclient + UI + nParse)
   - `Q` → Quit
4. Press **Q** to exit when finished.

The script will rename your current files to the appropriate backup and copy the correct version into place for **all three** config types.

---

## One-Time Setup (Important!)

### 1. UI Files (`UI_CHARACTERNAME_project1999.ini`)

Before the script can switch UI layouts:

1. **On your laptop** (native 2560×1600):
   - Launch EverQuest and arrange your UI exactly how you want it.
   - Copy `UI_CHARACTERNAME_project1999.ini` → `UI_CHARACTERNAME_project1999.ini.laptop`

2. **On your desktop** (1440p ultrawide):
   - Launch EverQuest and rearrange the UI for the big screen.
   - Copy the new `UI_CHARACTERNAME_project1999.ini` → `UI_CHARACTERNAME_project1999.ini.desktop`

Repeat for every character listed in `$characters`.

### 2. nParse Configuration (`nparse.config.json`)

1. **On your laptop** (2.5k):
   - Configure nParse overlays exactly how you want them for the smaller screen.
   - Copy `nparse.config.json` → `nparse.config.json.laptop`

2. **On your desktop** (1440p ultrawide):
   - Configure nParse overlays for the large ultrawide monitor.
   - Copy the new `nparse.config.json` → `nparse.config.json.desktop`

The script will automatically manage these files from now on.

---

## How It Works (High-Level)

- For each file type (`eqclient.ini`, UI files, `nparse.config.json`):
  - Renames the active file to a backup (`.laptop` or `.desktop`)
  - Copies the matching pre-saved version into the active slot
- Gracefully skips missing files with warnings
- All operations happen inside your configured EverQuest and nParse folders

---

## Troubleshooting

| Issue                                | Solution                                                                 |
| ------------------------------------ | ------------------------------------------------------------------------ |
| "Directory not found" (EverQuest)    | Update `$eqDir` at the top of the script                                 |
| "Directory not found" (nParse)       | Update `$nparseDir` or create the folder                                 |
| "File not found" warnings            | Create the missing `.desktop` or `.laptop` versions (see One-Time Setup) |
| Script doesn't run / no admin rights | Make sure the shortcut has "Run as administrator" enabled                |
| UAC prompt every time                | This is normal and required                                              |

---

## Notes

- The script **only** touches the characters you list in `$characters`. Other UI files are left untouched.
- For many characters or very complex setups, maintaining two separate EverQuest installations can be cleaner.
- Feel free to fork and customize!

---
