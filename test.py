import os
import sys

from PySide6.QtGui import QGuiApplication

print("QT_QPA_PLATFORM =", os.environ.get("QT_QPA_PLATFORM"))
print("WAYLAND_DISPLAY =", os.environ.get("WAYLAND_DISPLAY"))
print("XDG_SESSION_TYPE =", os.environ.get("XDG_SESSION_TYPE"))

app = QGuiApplication(sys.argv)

print("QPA platform =", app.platformName())

app.quit()