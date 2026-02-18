#!/usr/bin/env python3
"""
Automated color system updater for Flutter pages.
Converts all static AppColors properties to dynamic getXxx(context) functions.
"""

import re
import os

# Color mapping - static to dynamic function names
COLOR_MAPPINGS = {
    'pageGradient': 'getPageGradient',
    'gradientStart': 'getGradientStart',
    'gradientMiddle': 'getGradientMiddle',
    'gradientEnd': 'getGradientEnd',
    'textPrimary': 'getTextPrimary',
    'textSecondary': 'getTextSecondary',
    'subtleText': 'getSubtleText',
    'cardBg': 'getCardBg',
    'cardGreen': 'getCardGreen',
    'cardOrange': 'getCardOrange',
    'cardPurple': 'getCardPurple',
    'inputBg': 'getInputBg',
    'surface': 'getSurface',
    'surfaceVariant': 'getSurfaceVariant',
    'sidebar': 'getSidebar',
    'sidebarBorder': 'getSidebarBorder',
    'divider': 'getDivider',
    'dialogBg': 'getDialogBg',
    'tableHeader': 'getTableHeader',
    'hintText': 'getHintText',
    'success': 'getSuccess',
    'warning': 'getWarning',
    'error': 'getError',
    'info': 'getInfo',
    'accent': 'getAccent',
    'orange': 'getOrange',
    'primary': 'getPrimary',
    'chartBlue': 'getChartBlue',
    'chartGreen': 'getChartGreen',
    'chartOrange': 'getChartOrange',
    'chartRed': 'getChartRed',
    'chartPurple': 'getChartPurple',
    'statBg': 'getStatBg',
    'statBorder': 'getStatBorder',
    'badgeBg': 'getBadgeBg',
    'badgeBorder': 'getBadgeBorder',
    'iconDefault': 'getIconDefault',
    'cardShadow': 'getCardShadow',
}

def update_file(file_path):
    """Update a single file with dynamic color functions."""
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        original_content = content
        
        # Replace AppColors.PROPERTY with AppColors.getProperty(context)
        # But skip properties that already have (context)
        for static_prop, dynamic_func in COLOR_MAPPINGS.items():
            # Pattern: AppColors.textPrimary (but not AppColors.textPrimary_something)
            pattern = rf'AppColors\.{static_prop}(?!\w)'
            replacement = f'AppColors.{dynamic_func}(context)'
            content = re.sub(pattern, replacement, content)
        
        # Check if file was modified
        if content != original_content:
            with open(file_path, 'w', encoding='utf-8') as f:
                f.write(content)
            return True
        return False
    except Exception as e:
        print(f"Error updating {file_path}: {e}")
        return False

# Main execution
pages_dir = r'd:\program flutter\sahara-fuel-project\sahara_fuel_app_fixed last updata\lib\pages'

# Files to skip (already updated)
skip_files = {'activation_page.dart', 'audit_trail_page.dart', 'admin_license_page.dart', 'Deserty_eye.dart'}

files_updated = []
files_skipped = []

for filename in os.listdir(pages_dir):
    if filename.endswith('.dart') and filename not in skip_files:
        file_path = os.path.join(pages_dir, filename)
        if update_file(file_path):
            files_updated.append(filename)
            print(f"✓ Updated: {filename}")
        else:
            files_skipped.append(filename)

print(f"\n✓ Successfully updated {len(files_updated)} files")
print(f"⊘ Skipped {len(files_skipped)} files (no changes needed)")
print(f"\nUpdated files:")
for f in sorted(files_updated):
    print(f"  - {f}")
