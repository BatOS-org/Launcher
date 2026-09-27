{
  description = "BatOS Launcher — PySide6/QtQuick on Wayland";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};

      # PySide6 aus pip bringt sein eigenes Qt mit (inkl. libqwayland.so).
      # Hier nur die System-Bibliotheken, gegen die dieses Qt linkt —
      # bewusst OHNE nixpkgs-qt6, sonst kollidieren zwei Qt-Versionen.
      runtimeLibs = with pkgs; [
        stdenv.cc.cc.lib
        zlib
        zstd
        brotli
        krb5
        glib
        dbus
        libpulseaudio
        fontconfig
        freetype
        libGL
        libxkbcommon
        wayland
        # libQt6Gui linkt hart gegen X11, auch wenn wir auf Wayland laufen
        libx11
        libxcb
        libxext
        libxrender
        libxi
        libxrandr
        libxcursor
        libxfixes
        libsm
        libice
      ];
    in
    {
      devShells.${system}.default = pkgs.mkShell {
        packages = with pkgs; [
          python312
          gcc
          pkg-config
        ] ++ runtimeLibs;

        LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath runtimeLibs;

        QT_QPA_PLATFORM = "wayland";

        shellHook = ''
          # Die KDE/Plasma-Session exportiert diese global auf nixpkgs-Qt.
          # PySide6 aus pip würde dann fremde Plugins laden -> Symbol-Mismatch.
          unset QT_PLUGIN_PATH QML2_IMPORT_PATH QML_IMPORT_PATH QT_QPA_PLATFORM_PLUGIN_PATH

          if [ ! -d .venv ]; then
            python -m venv .venv
            .venv/bin/pip install -r requirements.txt
          fi

          source .venv/bin/activate
        '';
      };
    };
}
