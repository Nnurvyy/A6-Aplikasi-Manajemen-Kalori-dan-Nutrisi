import os
import re
import shutil

project_root = r"c:\Tugas\Proyek 4\NutriTrack_app"
lib_dir = os.path.join(project_root, "lib")
features_dir = os.path.join(lib_dir, "features")

# Mapping of old relative paths (from lib/) to new relative paths (from lib/)
moves = {
    "features/user_main_view.dart": "features/user/user_main_view.dart",
    "features/auth": "features/general/auth",
    "features/dashboard": "features/user/dashboard",
    "features/food": "features/general/food",
    "features/profile": "features/user/profile",
    "features/progress": "features/user/progress",
    "features/scan": "features/user/scan",
    "features/screen/food_database_screen.dart": "features/admin/food/admin_food_list_view.dart",
    "features/screen/food_item_model.dart": "features/general/food/models/food_item_model.dart",
    "features/screen/FormTambahMakananManual.dart": "features/user/manual_food/manual_food_form_view.dart",
    "features/screen/PilihMakananManual.dart": "features/user/manual_food/manual_food_selection_view.dart",
    "features/screen/submission": "features/general/submission",
    "features/shared/widgets": "features/general/widgets",
    "features/widgets/submission": "features/general/submission/widgets",
}

def get_files_recursively(directory):
    file_paths = []
    for root, _, files in os.walk(directory):
        for file in files:
            file_paths.append(os.path.join(root, file))
    return file_paths

old_to_new_file = {}

# Build old_to_new_file mapping
for old_rel, new_rel in moves.items():
    old_full = os.path.join(lib_dir, os.path.normpath(old_rel))
    new_full = os.path.join(lib_dir, os.path.normpath(new_rel))
    if os.path.isdir(old_full):
        for file in get_files_recursively(old_full):
            rel_path_inside = os.path.relpath(file, old_full)
            new_file_full = os.path.join(new_full, rel_path_inside)
            old_to_new_file[file] = new_file_full
    elif os.path.isfile(old_full):
        old_to_new_file[old_full] = new_full

# Print mapping to check
print("File mappings:")
for k, v in list(old_to_new_file.items())[:5]:
    print(f"{os.path.relpath(k, lib_dir)} -> {os.path.relpath(v, lib_dir)}")

# Move files
print("Moving files...")
for old_full, new_full in old_to_new_file.items():
    os.makedirs(os.path.dirname(new_full), exist_ok=True)
    if os.path.exists(old_full):
        shutil.copy2(old_full, new_full) # copy first

# Update imports
print("Updating imports...")
all_new_files = get_files_recursively(lib_dir)

def resolve_import(source_file, import_path):
    if import_path.startswith("package:"):
        return import_path
    # resolve relative import
    source_dir = os.path.dirname(source_file)
    target_full = os.path.normpath(os.path.join(source_dir, import_path))
    return target_full

def get_new_relative_import(new_source_file, new_target_file):
    rel_path = os.path.relpath(new_target_file, os.path.dirname(new_source_file))
    return rel_path.replace(os.sep, '/')

import_pattern = re.compile(r"""(import\s+['"])(.*?)(['"]\s*;)""")

for file_path in all_new_files:
    if not file_path.endswith('.dart'): continue
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    def replacer(match):
        prefix = match.group(1)
        imp = match.group(2)
        suffix = match.group(3)
        
        if imp.startswith("package:") or imp.startswith("dart:"):
            return match.group(0)
            
        # Figure out what old file this file was
        old_source_file = None
        for old, new in old_to_new_file.items():
            if new == file_path:
                old_source_file = old
                break
        if not old_source_file:
            old_source_file = file_path # not moved
            
        # Target's old full path
        old_target_full = resolve_import(old_source_file, imp)
        
        # What is the new target full path?
        new_target_full = old_to_new_file.get(old_target_full, old_target_full)
        
        # Calculate new relative import from file_path to new_target_full
        new_imp = get_new_relative_import(file_path, new_target_full)
        
        if not new_imp.startswith('.'):
            new_imp = './' + new_imp
            
        return f"{prefix}{new_imp}{suffix}"
        
    new_content = import_pattern.sub(replacer, content)
    
    if new_content != content:
        with open(file_path, 'w', encoding='utf-8') as f:
            f.write(new_content)

# Delete old directories
print("Cleaning up old directories...")
for old_rel in moves.keys():
    old_full = os.path.join(lib_dir, os.path.normpath(old_rel))
    if os.path.isdir(old_full):
        shutil.rmtree(old_full, ignore_errors=True)
    elif os.path.isfile(old_full):
        try:
            os.remove(old_full)
        except OSError:
            pass
            
# Clean up empty screen, shared, widgets in features
shutil.rmtree(os.path.join(features_dir, "screen"), ignore_errors=True)
shutil.rmtree(os.path.join(features_dir, "shared"), ignore_errors=True)
shutil.rmtree(os.path.join(features_dir, "widgets"), ignore_errors=True)

print("Done!")
