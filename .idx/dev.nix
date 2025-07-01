{pkgs}: {
  channel = "stable-24.05";
  packages = [
    pkgs.jdk17
    pkgs.unzip
    pkgs.sqlite
    pkgs.flutter # Add Flutter
    pkgs.dart    # Add Dart
    #pkgs.python311.withPackages (ps: [ # Add Python with packages
     # ps.numpy
     # ps.tensorflow-bin
     # ps.keras
     # ps.scikit-learn
     # ps.pip
    #])
    pkgs.cmake     # Add CMake
    pkgs.ninja     # Add Ninja
    pkgs.clang     # Add Clang
    pkgs.pkg-config # Add Pkg-config
    pkgs.gtk3      # Add GTK3
    pkgs.glib      # Add GLib
    pkgs.libepoxy  # Add Libepoxy
    pkgs.git       # Add Git
    pkgs.curl      # Add Curl
  ];
  idx.extensions = [
    
  ];
  idx.previews = {
    previews = {
      web = {
        command = [
          "flutter"
          "run"
          "--machine"
          "-d"
          "web-server"
          "--web-hostname"
          "0.0.0.0"
          "--web-port"
          "$PORT"
        ];
        manager = "flutter";
      };
      android = {
        command = [
          "flutter"
          "run"
          "--machine"
          "-d"
          "android"
          "-d"
          "localhost:5555"
        ];
        manager = "flutter";
      };
    };
  };
}