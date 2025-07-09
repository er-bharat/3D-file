import sys
import os
from PySide6.QtCore import QObject, Slot, Signal, QUrl
from PySide6.QtQml import QQmlApplicationEngine
from PySide6.QtGui import QGuiApplication

# Resolve the base directory (where main.py is located)
BASE_DIR = os.path.dirname(os.path.abspath(__file__))

# Add base directory to sys.path to ensure local modules can be imported from anywhere
sys.path.insert(0, BASE_DIR)

# Import local modules
from FileModel import FileModel
from thumbnail import generate_thumbnail
# from thumbnail_worker import ThumbnailWorker  # if you use threading later

class FileManager(QObject):
    thumbnailGenerated = Signal(str)

    def __init__(self):
        super().__init__()
        self.file_model = FileModel()

        # Set thumbnail cache directory
        self.thumb_cache_dir = os.path.expanduser("~/.local/share/3dthumb")
        if not os.path.exists(self.thumb_cache_dir):
            os.makedirs(self.thumb_cache_dir)

    @Slot(str, result=str)
    def generate_thumbnail(self, file_path):
        try:
            # Compose thumbnail cache file path:
            # use filename + extension, but sanitize filename
            base_name = os.path.basename(file_path)
            safe_name = base_name.replace("/", "_").replace("\\", "_")
            thumb_path = os.path.join(self.thumb_cache_dir, safe_name + ".png")

            if os.path.exists(thumb_path):
                # Reuse cached thumbnail
                return thumb_path

            # Generate and save thumbnail to cache
            thumbnail_path = generate_thumbnail(file_path, thumb_path)
            if thumbnail_path:
                self.thumbnailGenerated.emit(thumbnail_path)
                return thumbnail_path
            else:
                return ""
        except Exception as e:
            print(f"Thumbnail generation error: {e}")
            return ""

# # Block external theme control via qt6ct or system theme injection
# os.environ.pop("QT_QPA_PLATFORMTHEME", None)
# os.environ.pop("QT_STYLE_OVERRIDE", None)
# os.environ.pop("QT_QUICK_CONTROLS_STYLE", None)
# os.environ["QT_QPA_PLATFORMTHEME"] = ""  # Disable qt6ct


if __name__ == "__main__":
    app = QGuiApplication(sys.argv)
    engine = QQmlApplicationEngine()

    file_manager = FileManager()
    engine.rootContext().setContextProperty("fileManager", file_manager)
    engine.rootContext().setContextProperty("fileModel", file_manager.file_model)

    # Load the QML file using an absolute path
    qml_file = os.path.join(BASE_DIR, "ui", "main.qml")
    engine.load(QUrl.fromLocalFile(qml_file))

    if not engine.rootObjects():
        sys.exit(-1)

    sys.exit(app.exec())
