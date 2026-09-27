# This Python file uses the following encoding: utf-8
import sys
from pathlib import Path
import os, tempfile

from PySide6.QtCore import QObject, Property, Signal, Slot, QUrl, QProcess, QStandardPaths, Qt
from PySide6.QtGui import QGuiApplication, QIcon, QPixmap
from PySide6.QtQml import QQmlApplicationEngine, qmlRegisterType

from app_scanner import get_installed_apps

# app data dictionary
APPS = get_installed_apps()

class ImageModel(QObject):
    """Model to hold image data from Python dictionary"""
    
    def __init__(self, parent=None):
        super().__init__(parent)
        self._data = APPS
        self.process = QProcess()
        self._icon_paths = []

        for app in self._data:
            icon_name = app.get("icon", "")
            qicon = QIcon.fromTheme(icon_name)
            if qicon.isNull():
                # Fallback: leeres Icon oder Standardbild
                pixmap = QPixmap(256, 256)
                pixmap.fill(Qt.transparent)
            else:
                pixmap = qicon.pixmap(256, 256)

            # Temporäre Datei für dieses Icon
            tmp = tempfile.NamedTemporaryFile(delete=False, suffix=".png")
            tmp.close()
            pixmap.save(tmp.name)
            self._icon_paths.append(tmp.name)
    
    @Property(int, constant=True)
    def count(self):
        """Return number of images"""
        return len(self._data)
    
    @Slot(int, result=str)
    def getName(self, index):
        """Get name by index"""
        if 0 <= index < len(self._data):
            return self._data[index]["name"]
        return ""
    
    @Slot(int, result=str)
    def getIcon(self, index):
        if 0 <= index < len(self._icon_paths):
            return "file://" + self._icon_paths[index]
        return ""
    
    @Slot(int, result=str)
    def getDescription(self, index):
        """Get description by index"""
        if 0 <= index < len(self._data):
            return self._data[index]["description"]
        return ""

    @Slot(int, result=str)
    def execApp(self, index):
        """Get image path by index"""
        self.process.startDetached(self._data[index]["path"])
        return ""

if __name__ == "__main__":
    app = QGuiApplication(sys.argv)

    engine = QQmlApplicationEngine()
    image_model = ImageModel()
    engine.rootContext().setContextProperty("imageModel", image_model)
    qml_file = Path(__file__).resolve().parent / "main.qml"
    engine.load(qml_file)
    if not engine.rootObjects():
        sys.exit(-1)

    sys.exit(app.exec())
