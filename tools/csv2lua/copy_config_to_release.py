import os
import shutil

import os
import shutil

import os
import shutil


def copy_files_recursive(src_folder, dst_folder, exclude_files=None, exclude_folders=None):
    if not os.path.exists(dst_folder):
        os.makedirs(dst_folder)  # Ensure the destination folder exists

    for root, dirs, files in os.walk(src_folder):
        # Modify `dirs` in-place to exclude folders (prevents walking into them)
        if exclude_folders:
            dirs[:] = [d for d in dirs if d not in exclude_folders]

        # Create corresponding folder in destination
        relative_path = os.path.relpath(root, src_folder)
        dest_path = os.path.join(dst_folder, relative_path)
        if not os.path.exists(dest_path):
            os.makedirs(dest_path)

        for filename in files:
            if exclude_files and filename in exclude_files:
                continue  # Skip excluded files

            src_file = os.path.join(root, filename)
            dest_file = os.path.join(dest_path, filename)
            shutil.copy2(src_file, dest_file)  # Copy file with metadata


# Example Usage
source = "config"
destination = "F:/103.naruto/client_v2/src/config"
exclude_files = ["draw_items_lib.lua"]  # Files to exclude
exclude_folders  = ["yunying"]

copy_files_recursive(source, destination, exclude_files, exclude_folders)
print("Files copied successfully!")