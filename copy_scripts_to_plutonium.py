from pathlib import Path
import shutil

REPO_ROOT = Path(__file__).resolve().parent
SOURCE_DIR = REPO_ROOT / "mod_package"
TARGET_DIR = Path(r"C:\Users\brenn\AppData\Local\Plutonium\storage\t5")

if not SOURCE_DIR.exists():
    raise FileNotFoundError(f"Source directory not found: {SOURCE_DIR}")

TARGET_DIR.mkdir(parents=True, exist_ok=True)

for item in SOURCE_DIR.iterdir():
    destination = TARGET_DIR / item.name
    if item.is_dir():
        shutil.copytree(item, destination, dirs_exist_ok=True)
    else:
        shutil.copy2(item, destination)

print(f"Copied contents of {SOURCE_DIR} to {TARGET_DIR}")
