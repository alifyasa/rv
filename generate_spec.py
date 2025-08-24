#!/usr/bin/env python3
"""Generate PyInstaller spec file with git commit hash."""

import subprocess
from pathlib import Path


def get_git_commit_hash() -> str:
    """Get the current git commit hash."""
    try:
        result = subprocess.run(
            ["git", "rev-parse", "--short", "HEAD"],
            capture_output=True,
            text=True,
            check=True,
        )
        return result.stdout.strip()
    except subprocess.CalledProcessError:
        return "unknown"


def generate_spec_content(commit_hash: str) -> str:
    """Generate the spec file content with commit hash."""
    return f"""# -*- mode: python ; coding: utf-8 -*-
# Auto-generated spec file with commit hash: {commit_hash}

block_cipher = None

a = Analysis(
    ['rv/__main__.py'],
    pathex=[],
    binaries=[],
    datas=[],
    hiddenimports=[],
    hookspath=[],
    hooksconfig={{}},
    runtime_hooks=[],
    excludes=[],
    win_no_prefer_redirects=False,
    win_private_assemblies=False,
    cipher=block_cipher,
    noarchive=False,
)

pyz = PYZ(a.pure, a.zipped_data, cipher=block_cipher)

exe = EXE(
    pyz,
    a.scripts,
    a.binaries,
    a.zipfiles,
    a.datas,
    [],
    name='rv',
    debug=False,
    bootloader_ignore_signals=False,
    strip=False,
    upx=True,
    upx_exclude=[],
    runtime_tmpdir=None,
    console=True,
    disable_windowed_traceback=False,
    argv_emulation=False,
    target_arch=None,
    codesign_identity=None,
    entitlements_file=None,
)
"""


def main() -> None:
    """Generate the spec file."""
    commit_hash = get_git_commit_hash()
    spec_content = generate_spec_content(commit_hash)

    spec_path = Path("rv.spec")
    spec_path.write_text(spec_content)

    print(f"Generated rv.spec with commit hash: {commit_hash}")


if __name__ == "__main__":
    main()
