from app_scanner import get_installed_apps

apps = get_installed_apps()
for app in apps:  # erste 5 Apps
    print(app)

    from PySide6.QtGui import QIcon

# Icon aus Theme laden (automatisch!)
icon = QIcon.fromTheme("okular")

# Mit Fallback, falls Theme das Icon nicht hat
icon = QIcon.fromTheme("okular", QIcon("/usr/share/pixmaps/okular.png"))