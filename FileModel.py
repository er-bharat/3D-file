import os
import shutil
import subprocess
import platform
import hashlib
from PySide6.QtCore import QObject, Slot, Property, Signal

from thumbnail import generate_thumbnail  # your custom thumbnail generator

class FileModel(QObject):
    filesChanged = Signal()

    def __init__(self):
        super().__init__()
        self._current_path = os.path.expanduser("~")
        self._clipboard = {"mode": None, "path": None}
        self._show_hidden = False
        self._thumb_cache_dir = os.path.expanduser("~/.local/share/3dthumb")
        os.makedirs(self._thumb_cache_dir, exist_ok=True)

    @Property('QStringList', notify=filesChanged)
    def files(self):
        try:
            entries = os.listdir(self._current_path)
            if not self._show_hidden:
                entries = [e for e in entries if not e.startswith(".")]

            folders = sorted([e for e in entries if os.path.isdir(os.path.join(self._current_path, e))])
            files = sorted([e for e in entries if not os.path.isdir(os.path.join(self._current_path, e))])

            items = [".."] + folders + files
            return items
        except Exception as e:
            print(f"Error reading directory: {e}")
            return [".."]

    @Slot(bool)
    def setShowHidden(self, show):
        self._show_hidden = show
        self.filesChanged.emit()

    @Slot(result=str)
    def currentPath(self):
        return self._current_path

    @Slot(int, result=str)
    def filePathAt(self, index):
        try:
            entries = os.listdir(self._current_path)
            if not self._show_hidden:
                entries = [e for e in entries if not e.startswith(".")]
            folders = sorted([e for e in entries if os.path.isdir(os.path.join(self._current_path, e))])
            files = sorted([e for e in entries if not os.path.isdir(os.path.join(self._current_path, e))])
            items = [".."] + folders + files
            return os.path.join(self._current_path, items[index])
        except Exception as e:
            print(f"Error resolving file path: {e}")
            return ""

    @Slot(int)
    def openItem(self, index):
        try:
            path = self.filePathAt(index)
            if os.path.isdir(path):
                self._current_path = os.path.abspath(path)
                self.filesChanged.emit()
            else:
                system = platform.system()
                if system == "Windows":
                    os.startfile(path)
                elif system == "Darwin":
                    subprocess.Popen(["open", path])
                else:
                    subprocess.Popen(["xdg-open", path])
        except Exception as e:
            print(f"Failed to open item: {e}")

    @Slot(str)
    def openPath(self, path):
        try:
            path = os.path.abspath(os.path.expanduser(path))
            if os.path.isdir(path):
                self._current_path = path
                self.filesChanged.emit()
            else:
                system = platform.system()
                if system == "Windows":
                    os.startfile(path)
                elif system == "Darwin":
                    subprocess.Popen(["open", path])
                else:
                    subprocess.Popen(["xdg-open", path])
        except Exception as e:
            print(f"Failed to open path: {e}")

    @Slot(int, str)
    def renameItem(self, index, new_name):
        try:
            entries = os.listdir(self._current_path)
            if not self._show_hidden:
                entries = [e for e in entries if not e.startswith(".")]
            folders = sorted([e for e in entries if os.path.isdir(os.path.join(self._current_path, e))])
            files = sorted([e for e in entries if not os.path.isdir(os.path.join(self._current_path, e))])
            items = [".."] + folders + files

            old_path = os.path.join(self._current_path, items[index])
            new_path = os.path.join(self._current_path, new_name)

            if platform.system() != "Linux":
                print("Rename via 'mv' is only supported on Linux in this method.")
                return

            subprocess.run(["mv", old_path, new_path], check=True)
            self.filesChanged.emit()
        except Exception as e:
            print(f"Failed to rename using mv: {e}")

    @Slot(int)
    def copyItem(self, index):
        try:
            self._clipboard = {
                "mode": "copy",
                "path": self.filePathAt(index)
            }
        except Exception as e:
            print(f"Failed to copy item: {e}")

    @Slot(int)
    def cutItem(self, index):
        try:
            self._clipboard = {
                "mode": "cut",
                "path": self.filePathAt(index)
            }
        except Exception as e:
            print(f"Failed to cut item: {e}")

    @Slot()
    def pasteItem(self):
        try:
            src = self._clipboard.get("path")
            mode = self._clipboard.get("mode")

            if not src or not os.path.exists(src):
                print("Clipboard is empty or invalid.")
                return

            dest = os.path.join(self._current_path, os.path.basename(src))

            if os.path.exists(dest):
                print("File already exists at destination.")
                return

            if mode == "copy":
                if os.path.isdir(src):
                    shutil.copytree(src, dest)
                else:
                    shutil.copy2(src, dest)
            elif mode == "cut":
                shutil.move(src, dest)

            self._clipboard = {"mode": None, "path": None}
            self.filesChanged.emit()

        except Exception as e:
            print(f"Failed to paste item: {e}")

    @Slot(int, result=bool)
    def isDir(self, index):
        try:
            entries = os.listdir(self._current_path)
            if not self._show_hidden:
                entries = [e for e in entries if not e.startswith(".")]
            folders = sorted([e for e in entries if os.path.isdir(os.path.join(self._current_path, e))])
            files = sorted([e for e in entries if not os.path.isdir(os.path.join(self._current_path, e))])
            items = [".."] + folders + files
            return os.path.isdir(os.path.join(self._current_path, items[index]))
        except Exception as e:
            print(f"Failed to check isDir: {e}")
            return False

    @Slot(int, result=str)
    def thumbnailAt(self, index):
        try:
            path = self.filePathAt(index)
            if not os.path.exists(path) or os.path.isdir(path):
                return ""  # no thumbnails for dirs or invalid paths

            cached_thumb = self._thumbnail_cache_path(path)
            if os.path.exists(cached_thumb):
                return cached_thumb

            # Generate and cache thumbnail
            thumb_path = generate_thumbnail(path, cached_thumb)
            if thumb_path:
                return thumb_path
            else:
                return ""
        except Exception as e:
            print(f"Failed to get thumbnail: {e}")
            return ""

    def _thumbnail_cache_path(self, file_path):
        abs_path = os.path.abspath(file_path)
        h = hashlib.md5(abs_path.encode('utf-8')).hexdigest()
        return os.path.join(self._thumb_cache_dir, f"{h}.png")

    # ✅ New method for Drag and Drop support
    @Slot(str, str)
    def moveFileTo(self, source, destinationFolder):
        try:
            print(f"Requested move: {source} → {destinationFolder}")
            if not os.path.exists(source):
                print("Source does not exist.")
                return
            if not os.path.isdir(destinationFolder):
                print("Destination is not a folder.")
                return

            target_path = os.path.join(destinationFolder, os.path.basename(source))
            if os.path.exists(target_path):
                print("File already exists at destination.")
                return

            shutil.move(source, target_path)
            self.filesChanged.emit()
            print(f"Moved {source} to {target_path}")
        except Exception as e:
            print(f"Failed to move file: {e}")
