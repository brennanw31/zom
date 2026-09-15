import zipfile
from pathlib import Path

# Embedded install.bat contents
BAT_CONTENT = """@echo off
title Plutonium BO1 Mod Installer

set "PLUTONIUM_DIR=%LOCALAPPDATA%\\Plutonium"
set "TARGET_DIR=%LOCALAPPDATA%\\Plutonium\\storage\\t5\\scripts\\sp\\zom"
set "SOURCE_DIR=%~dp0scripts\\sp\\zom"

if not exist "%SOURCE_DIR%" (
    echo Error: Could not find scripts\\sp\\zom in this directory.
    echo Make sure you extracted the ZIP archive before running install.bat.
    echo.
    pause
    exit /b 1
)

if not exist "%PLUTONIUM_DIR%" (
    echo Error: Plutonium is not installed or this script is targeting the wrong directory.
    echo %PLUTONIUM_DIR% was expected to exist.
    echo.
    pause
    exit /b 1
)

if not exist "%TARGET_DIR%" (
    mkdir "%TARGET_DIR%"
)

echo Copying mod scripts into Plutonium...
xcopy "%SOURCE_DIR%\\*.gsc" "%TARGET_DIR%\\" /S /Y /I >nul

if %errorlevel% equ 0 (
    echo.
    echo Success! Mod scripts installed to:
    echo %TARGET_DIR%
) else (
    echo.
    echo Installation failed. Check folder permissions.
)

rem Auto-configure Plutonium BO1 path in config.json if not already set
powershell -NoProfile -ExecutionPolicy Bypass -Command "^
$configPath = '$env:LOCALAPPDATA\\Plutonium\\config.json';" ^
"$pathx86 = 'C:\\Program Files (x86)\\Steam\\steamapps\\common\\Call of Duty Black Ops';" ^
"$pathx64 = 'C:\\Program Files\\Steam\\steamapps\\common\\Call of Duty Black Ops';" ^
"$gameDir = $null;" ^
"if (Test-Path $pathx86) { $gameDir = $pathx86 } elseif (Test-Path $pathx64) { $gameDir = $pathx64 };" ^
"if ($gameDir) {" ^
"  $json = [PSCustomObject]@{};" ^
"  if (Test-Path $configPath) { $json = Get-Content $configPath -Raw | ConvertFrom-Json -ErrorAction SilentlyContinue };" ^
"  if (-not $json) { $json = [PSCustomObject]@{} };" ^
"  if (-not $json.t5Path) {" ^
"    $json | Add-Member -NotePropertyName 't5Path' -NotePropertyValue $gameDir -Force;" ^
"    $json | ConvertTo-Json | Set-Content $configPath -Encoding UTF8;" ^
"    Write-Host '`nAuto-configured Plutonium BO1 path: ' $gameDir -ForegroundColor Green;" ^
"  }" ^
"}"

echo.
pause
"""

def build_mod_package():
    repo_root = Path(__file__).parent.resolve()
    mod_package_dir = repo_root / "mod_package"
    output_zip = repo_root / "BO1_Mod_Installer.zip"
    mod_dir = mod_package_dir / "scripts" / "sp" / "zom"
    
    if not mod_dir.exists():
        print(f"Error: Target directory not found: {mod_dir}")
        return

    with zipfile.ZipFile(output_zip, "w", zipfile.ZIP_DEFLATED) as zipf:
        # 1. Dynamically write install.bat into the root of the zip archive
        zipf.writestr("install.bat", BAT_CONTENT)
        print("Generated and added: install.bat")

        # 2. Add all .gsc files maintaining repo relative structure
        gsc_count = 0
        for gsc_path in mod_dir.rglob("*.gsc"):
            arcname = gsc_path.relative_to(mod_package_dir)
            zipf.write(gsc_path, arcname=arcname)
            print(f"Added: {arcname}")
            gsc_count += 1

    print(f"\nCreated {output_zip.name} containing {gsc_count} script(s).")

if __name__ == "__main__":
    build_mod_package()