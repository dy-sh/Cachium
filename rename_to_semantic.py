#!/usr/bin/env python3
"""
Automated script to rename FM-prefixed design system components to semantic names.

This script:
1. Renames all FM* widget classes to semantic names
2. Updates file names to match new class names
3. Updates all import statements across the codebase
4. Updates the barrel export file (design_system.dart)
5. Optionally runs flutter analyze for verification
"""

import os
import re
import shutil
import subprocess
import sys
from pathlib import Path
from typing import Dict, List, Tuple

# Special semantic renames (to avoid Material conflicts)
SPECIAL_RENAMES = {
    'FMCard': 'Surface',
    'FMTextField': 'InputField',
    'FMSwitch': 'Toggle',
    'FMIconButton': 'IconBtn',
    'FMScaffold': 'PageLayout',
}

# Standard renames (just remove FM prefix)
STANDARD_WIDGETS = [
    'FMPrimaryButton', 'FMCloseButton', 'FMSelectableCard',
    'FMChip', 'FMToggleChip', 'FMAmountInput', 'FMDatePicker',
    'FMDatePickerModal', 'FMDatePickerIconButton', 'FMDatePickerNavigationButton',
    'FMMonthYearPicker', 'FMCalendarGrid', 'FMWeekDayLabels', 'FMDayCell',
    'FMScreenHeader', 'FMFormHeader', 'FMBottomNavBar', 'FMBottomNavItem',
    'FMEmptyState', 'FMLoadingIndicator', 'FMLoadingDots',
    'FMNotification', 'FMNotificationOverlay',
    'FMInlineSelector', 'FMInlineSelectorItem',
]

# File rename mapping (special cases)
FILE_RENAME_MAP = {
    'fm_card.dart': 'surface.dart',
    'fm_text_field.dart': 'input_field.dart',
    'fm_switch.dart': 'toggle.dart',
    'fm_icon_button.dart': 'icon_btn.dart',
    'fm_scaffold.dart': 'page_layout.dart',
}


def get_class_name_mapping() -> Dict[str, str]:
    """Build complete mapping of old class names to new class names."""
    mapping = SPECIAL_RENAMES.copy()

    for widget in STANDARD_WIDGETS:
        # Remove FM prefix
        new_name = widget.replace('FM', '', 1)
        mapping[widget] = new_name

    return mapping


def get_file_name_mapping() -> Dict[str, str]:
    """Build complete mapping of old file names to new file names."""
    mapping = FILE_RENAME_MAP.copy()

    # For standard widgets, convert class name to snake_case file name
    for widget in STANDARD_WIDGETS:
        # Convert FMPrimaryButton -> primary_button
        old_file = camel_to_snake(widget) + '.dart'
        new_class = widget.replace('FM', '', 1)
        new_file = camel_to_snake(new_class) + '.dart'

        if old_file not in mapping:
            mapping[old_file] = new_file

    return mapping


def camel_to_snake(name: str) -> str:
    """Convert CamelCase to snake_case."""
    # Insert underscore before uppercase letters (except first)
    s1 = re.sub('(.)([A-Z][a-z]+)', r'\1_\2', name)
    # Insert underscore before uppercase followed by lowercase
    return re.sub('([a-z0-9])([A-Z])', r'\1_\2', s1).lower()


def find_dart_files(root_dir: Path) -> List[Path]:
    """Find all Dart files in the project."""
    dart_files = []
    for path in root_dir.rglob('*.dart'):
        # Skip generated files and test files for now
        if not any(part.startswith('.') for part in path.parts):
            dart_files.append(path)
    return dart_files


def update_file_content(file_path: Path, class_mapping: Dict[str, str],
                       file_mapping: Dict[str, str], dry_run: bool = False) -> int:
    """Update class names and import paths in a file. Returns number of changes."""
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            original_content = f.read()
    except Exception as e:
        print(f"  ⚠️  Error reading {file_path}: {e}")
        return 0

    content = original_content
    changes = 0

    # Replace class names (use word boundaries to avoid partial matches)
    for old_name, new_name in class_mapping.items():
        pattern = r'\b' + re.escape(old_name) + r'\b'
        new_content = re.sub(pattern, new_name, content)
        if new_content != content:
            count = len(re.findall(pattern, content))
            changes += count
            content = new_content

    # Update import paths
    for old_file, new_file in file_mapping.items():
        # Handle both single and double quotes
        for quote in ["'", '"']:
            old_import = f"{quote}{old_file}{quote}"
            new_import = f"{quote}{new_file}{quote}"
            if old_import in content:
                content = content.replace(old_import, new_import)
                changes += 1

        # Also update relative imports with paths
        pattern = rf"(['\"].*?/){re.escape(old_file)}(['\"])"
        new_content = re.sub(pattern, rf"\1{new_file}\2", content)
        if new_content != content:
            changes += 1
            content = new_content

    # Write back if content changed
    if content != original_content and not dry_run:
        try:
            with open(file_path, 'w', encoding='utf-8') as f:
                f.write(content)
        except Exception as e:
            print(f"  ⚠️  Error writing {file_path}: {e}")
            return 0

    return changes


def rename_files(root_dir: Path, file_mapping: Dict[str, str], dry_run: bool = False) -> List[Tuple[Path, Path]]:
    """Rename design system component files. Returns list of (old_path, new_path) tuples."""
    renamed = []
    design_system_dir = root_dir / 'lib' / 'design_system' / 'components'

    if not design_system_dir.exists():
        print(f"  ⚠️  Design system directory not found: {design_system_dir}")
        return renamed

    # Find all files to rename
    for old_filename, new_filename in file_mapping.items():
        # Search recursively in design_system/components
        for old_path in design_system_dir.rglob(old_filename):
            new_path = old_path.parent / new_filename

            if dry_run:
                print(f"  Would rename: {old_path.relative_to(root_dir)}")
                print(f"           to: {new_path.relative_to(root_dir)}")
            else:
                try:
                    shutil.move(str(old_path), str(new_path))
                    print(f"  ✓ Renamed: {old_path.relative_to(root_dir)} → {new_filename}")
                except Exception as e:
                    print(f"  ⚠️  Error renaming {old_path}: {e}")
                    continue

            renamed.append((old_path, new_path))

    return renamed


def update_barrel_export(root_dir: Path, class_mapping: Dict[str, str],
                        file_mapping: Dict[str, str], dry_run: bool = False) -> bool:
    """Update the design_system.dart barrel export file."""
    barrel_file = root_dir / 'lib' / 'design_system' / 'design_system.dart'

    if not barrel_file.exists():
        print(f"  ⚠️  Barrel file not found: {barrel_file}")
        return False

    changes = update_file_content(barrel_file, class_mapping, file_mapping, dry_run)

    if changes > 0:
        if dry_run:
            print(f"  Would update barrel export: {changes} changes")
        else:
            print(f"  ✓ Updated barrel export: {changes} changes")
        return True

    return False


def run_flutter_analyze(root_dir: Path) -> bool:
    """Run flutter analyze to verify no errors."""
    print("\n🔍 Running flutter analyze...")
    try:
        result = subprocess.run(
            ['flutter', 'analyze'],
            cwd=root_dir,
            capture_output=True,
            text=True,
            timeout=60
        )

        if result.returncode == 0:
            print("✅ Flutter analyze passed with no errors")
            return True
        else:
            print("❌ Flutter analyze found issues:")
            print(result.stdout)
            print(result.stderr)
            return False
    except subprocess.TimeoutExpired:
        print("⚠️  Flutter analyze timed out")
        return False
    except FileNotFoundError:
        print("⚠️  Flutter command not found. Skipping analyze.")
        return False
    except Exception as e:
        print(f"⚠️  Error running flutter analyze: {e}")
        return False


def main():
    import argparse

    parser = argparse.ArgumentParser(
        description='Rename FM-prefixed widgets to semantic names'
    )
    parser.add_argument(
        '--dry-run',
        action='store_true',
        help='Preview changes without applying them'
    )
    parser.add_argument(
        '--skip-analyze',
        action='store_true',
        help='Skip running flutter analyze after renaming'
    )
    parser.add_argument(
        '--commit',
        action='store_true',
        help='Create a git commit after successful renaming'
    )

    args = parser.parse_args()

    # Get project root
    root_dir = Path(__file__).parent.resolve()
    print(f"📁 Project root: {root_dir}")

    # Build mappings
    class_mapping = get_class_name_mapping()
    file_mapping = get_file_name_mapping()

    print(f"\n📊 Renaming {len(class_mapping)} widget classes")
    print(f"📊 Renaming {len(file_mapping)} component files")

    if args.dry_run:
        print("\n⚠️  DRY RUN MODE - No changes will be made\n")
    else:
        print("\n🚀 Starting renaming process...\n")

    # Step 1: Rename files
    print("📝 Step 1: Renaming component files...")
    renamed_files = rename_files(root_dir, file_mapping, args.dry_run)
    print(f"   Renamed {len(renamed_files)} files\n")

    # Step 2: Update all Dart files
    print("📝 Step 2: Updating class names and imports in all Dart files...")
    dart_files = find_dart_files(root_dir / 'lib')
    total_changes = 0
    files_modified = 0

    for dart_file in dart_files:
        changes = update_file_content(dart_file, class_mapping, file_mapping, args.dry_run)
        if changes > 0:
            total_changes += changes
            files_modified += 1
            if args.dry_run:
                print(f"  Would update: {dart_file.relative_to(root_dir)} ({changes} changes)")

    print(f"   {total_changes} replacements in {files_modified} files\n")

    # Step 3: Update barrel export
    print("📝 Step 3: Updating barrel export file...")
    update_barrel_export(root_dir, class_mapping, file_mapping, args.dry_run)

    if args.dry_run:
        print("\n✅ Dry run complete. Review the changes above.")
        print("   Run without --dry-run to apply changes.")
        return

    # Step 4: Verify with flutter analyze
    if not args.skip_analyze:
        print("\n📝 Step 4: Verifying with flutter analyze...")
        if not run_flutter_analyze(root_dir):
            print("\n⚠️  Warning: Flutter analyze found issues.")
            print("   Please review and fix any errors.")
            sys.exit(1)

    # Step 5: Git commit (optional)
    if args.commit:
        print("\n📝 Step 5: Creating git commit...")
        try:
            subprocess.run(['git', 'add', '.'], cwd=root_dir, check=True)
            subprocess.run([
                'git', 'commit', '-m',
                'refactor: rename FM-prefixed widgets to semantic names\n\n'
                f'- Renamed {len(class_mapping)} widget classes\n'
                f'- Renamed {len(file_mapping)} component files\n'
                f'- Updated {files_modified} files with {total_changes} replacements\n'
                '- Special renames: Card→Surface, TextField→InputField, Switch→Toggle, '
                'IconButton→IconBtn, Scaffold→PageLayout'
            ], cwd=root_dir, check=True)
            print("   ✓ Git commit created")
        except subprocess.CalledProcessError as e:
            print(f"   ⚠️  Error creating git commit: {e}")

    print("\n" + "="*60)
    print("✅ Renaming complete!")
    print("="*60)
    print(f"\nSummary:")
    print(f"  • {len(renamed_files)} files renamed")
    print(f"  • {files_modified} files modified")
    print(f"  • {total_changes} class name/import replacements")
    print(f"\nSpecial semantic renames:")
    for old, new in SPECIAL_RENAMES.items():
        print(f"  • {old} → {new}")
    print(f"\nNext steps:")
    print(f"  1. Run: flutter run")
    print(f"  2. Test all screens and components")
    print(f"  3. Update CLAUDE.md documentation")


if __name__ == '__main__':
    main()
