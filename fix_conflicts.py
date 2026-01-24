#!/usr/bin/env python3
"""Fix the two remaining Material conflicts: CloseButton and Chip"""

import os
import re
from pathlib import Path


def update_file_content(file_path: Path, old_class: str, new_class: str, old_file: str, new_file: str) -> int:
    """Update class names and import paths in a file."""
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            original_content = f.read()
    except Exception as e:
        print(f"  ⚠️  Error reading {file_path}: {e}")
        return 0

    content = original_content
    changes = 0

    # Replace class names (use word boundaries)
    pattern = r'\b' + re.escape(old_class) + r'\b'
    new_content = re.sub(pattern, new_class, content)
    if new_content != content:
        count = len(re.findall(pattern, content))
        changes += count
        content = new_content
        print(f"    Replaced {count} occurrences of {old_class}")

    # Update import paths
    for quote in ["'", '"']:
        old_import = f"{quote}{old_file}{quote}"
        new_import = f"{quote}{new_file}{quote}"
        if old_import in content:
            content = content.replace(old_import, new_import)
            changes += 1
            print(f"    Updated import path")

    # Update relative imports with paths
    pattern_import = rf"(['\"].*?/){re.escape(old_file)}(['\"])"
    new_content = re.sub(pattern_import, rf"\1{new_file}\2", content)
    if new_content != content:
        changes += 1
        content = new_content

    # Write back if changed
    if content != original_content:
        with open(file_path, 'w', encoding='utf-8') as f:
            f.write(content)

    return changes


def main():
    root_dir = Path(__file__).parent.resolve()

    # Fix 1: CloseButton → CircularButton
    print("🔧 Fix 1: CloseButton → CircularButton")
    old_file_1 = root_dir / 'lib/design_system/components/buttons/close_button.dart'
    new_file_1 = root_dir / 'lib/design_system/components/buttons/circular_button.dart'

    if old_file_1.exists():
        os.rename(old_file_1, new_file_1)
        print(f"  ✓ Renamed file: close_button.dart → circular_button.dart")

    # Fix 2: Chip → SelectionChip
    print("\n🔧 Fix 2: Chip → SelectionChip")
    old_file_2 = root_dir / 'lib/design_system/components/chips/chip.dart'
    new_file_2 = root_dir / 'lib/design_system/components/chips/selection_chip.dart'

    if old_file_2.exists():
        os.rename(old_file_2, new_file_2)
        print(f"  ✓ Renamed file: chip.dart → selection_chip.dart")

    # Update all Dart files
    print("\n📝 Updating all Dart files...")
    dart_files = list((root_dir / 'lib').rglob('*.dart'))

    total_changes = 0
    files_modified = 0

    for dart_file in dart_files:
        changes = 0

        # Fix CloseButton references
        c1 = update_file_content(dart_file, 'CloseButton', 'CircularButton',
                                 'close_button.dart', 'circular_button.dart')
        # Fix Chip references
        c2 = update_file_content(dart_file, 'Chip', 'SelectionChip',
                                 'chip.dart', 'selection_chip.dart')

        changes = c1 + c2

        if changes > 0:
            total_changes += changes
            files_modified += 1
            print(f"  ✓ Updated: {dart_file.relative_to(root_dir)} ({changes} changes)")

    print(f"\n✅ Complete!")
    print(f"  • {files_modified} files modified")
    print(f"  • {total_changes} total changes")


if __name__ == '__main__':
    main()
