from PySide6.QtWidgets import QApplication, QMainWindow, QListWidget, QListWidgetItem, QVBoxLayout, QWidget
from PySide6.QtGui import QIcon
from PySide6.QtCore import Qt, QProcess

from app_scanner import get_installed_apps

class AppLauncher(QMainWindow):
    def __init__(self):
        super().__init__()
        self.app_list = QListWidget()
        
        # Beispiel-Apps (wie deine Daten)
        apps = get_installed_apps()

        process = QProcess()
        
        for app in apps:
            item = QListWidgetItem(app['name'])
            
            # Icon aus Theme laden
            icon = QIcon.fromTheme(app['icon'])
            
            # Optional: Fallback-Icon, falls Theme es nicht hat
            if icon.isNull():
                print(f"Icon '{app['icon']}' nicht im Theme gefunden!")
                # Hier könntest du ein Standard-Icon setzen
                # icon = QIcon.fromTheme("application-x-executable")
            
            item.setIcon(icon)
            self.app_list.addItem(item)
        
        layout = QVBoxLayout()
        layout.addWidget(self.app_list)
        self.app_list.itemClicked.connect(process.startDetached("okular"))
        
        central = QWidget()
        central.setLayout(layout)
        self.setCentralWidget(central)

if __name__ == "__main__":
    app = QApplication([])
    window = AppLauncher()
    window.show()
    app.exec()