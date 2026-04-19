# EQ Config + UI Switcher

A simple, interactive PowerShell script that instantly switches your **eqclient.ini** resolution settings **and** per-character UI layout files (`UI_CHARACTERNAME_project1999.ini`) between:

- **Desktop mode** – 1440p / 34" ultrawide monitor (`.desktop` files)
- **Laptop mode** – Native 2.5k resolution on a 14" laptop display (`.laptop` files)

---

## Features

- One-click switching via an interactive menu
- Automatically handles both:
  - `eqclient.ini` (graphics/resolution settings)
  - `UI_*.ini` files for any characters you specify
- Safe rename + copy logic (never loses your current config)
- Runs as Administrator (required for file operations in the EverQuest folder)
- Fully configurable character list and install path
- Clear success/failure feedback
- Works with a desktop shortcut for instant access

---

## Requirements

- Windows 10 or 11
- PowerShell 5.1+ (pre-installed on Windows)
- EverQuest installed (default path: `C:\Everquest`)
- Administrator rights when running the script

---

## Installation

1. Download `EQ-Config-Switcher.ps1` and place it anywhere on your PC (recommended: `C:\Scripts\EQ-Config-Switcher.ps1` or your Documents folder).

2. **Create a desktop shortcut** (highly recommended):
   - Right-click on your desktop → **New** → **Shortcut**
   - Target:
     ```
     powershell.exe -NoProfile -ExecutionPolicy Bypass -File "C:\Scripts\EQ-Config-Switcher.ps1"
     ```
   - Name it something like `Switch EQ Config`
   - Right-click the shortcut → **Properties** → **Advanced** → check **"Run as administrator"** → OK

3. **Configure the script** (edit the top of the `.ps1` file):
   ```powershell
   $eqDir = "C:\Everquest"          # Change only if your EQ folder is elsewhere
   $characters = @("pivo")          # Add your character names here, e.g. @("pivo", "main", "alt")
   ```

---

## Usage

1. Double-click the desktop shortcut.
2. A UAC prompt will appear — click **Yes**.
3. Choose:
   - `1` → Switch to **1440p Desktop / Ultrawide**
   - `2` → Switch to **2.5k Laptop**
   - `Q` → Quit
4. Press **Q** to exit when finished.

The script will rename your current files to the appropriate backup and copy the correct version into place.

---

## One-Time UI File Setup (Important!)

Before the script can switch UI layouts, you must create the `.desktop` and `.laptop` versions:

1. **On your laptop** (native 2.5k resolution):
   - Launch EverQuest and arrange your UI exactly how you want it.
   - Copy `UI_CHARACTERNAME_project1999.ini` → `UI_CHARACTERNAME_project1999.ini.laptop`

2. **On your desktop** (1440p ultrawide):
   - Launch EverQuest and rearrange the UI for the big screen.
   - Copy the new `UI_CHARACTERNAME_project1999.ini` → `UI_CHARACTERNAME_project1999.ini.desktop`

Repeat for every character listed in `$characters`.

The script will automatically manage these files from now on.

---

## How It Works (High-Level)

- Renames the active `eqclient.ini` to a backup (`.laptop` or `.desktop`)
- Copies the matching pre-saved version into the active `eqclient.ini` slot
- Does the exact same thing for every UI file you listed
- Gracefully skips missing files with warnings
- All operations happen inside your EverQuest folder

---

## Troubleshooting

| Issue                     | Solution                                                           |
| ------------------------- | ------------------------------------------------------------------ |
| "Directory not found"     | Update `$eqDir` at the top of the script                           |
| "File not found" warnings | Create the missing `.desktop` or `.laptop` versions (see UI Setup) |
| Script doesn't run        | Make sure the shortcut has "Run as administrator" enabled          |
| UAC prompt every time     | This is normal and required for file access in the game folder     |

---

## Notes

- This script **only** touches the files you explicitly configure. Other characters' UI files are left untouched.
- For many characters or complex setups, maintaining two separate EverQuest installations can be cleaner.
- Feel free to fork and customize!

---
