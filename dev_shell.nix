# dev_shell.nix
{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  name = "taxasge-dev-env";

  buildInputs = [
    (pkgs.python311.withPackages (ps: [
      ps.numpy
      ps.tensorflow-bin   # 2.13.0 pré-compilé
      ps.keras            # 2.13.x  ← indispensable pour tf.keras
      ps.scikit-learn     # sklearn
      ps.pip
    ]))
    # Dart & Flutter dependencies
    pkgs.flutter
    pkgs.dart

    # Pour les tests FFI (libsqlite3)
    pkgs.sqlite


    # CMake pour les builds Linux
    pkgs.cmake
    pkgs.ninja
    pkgs.pkg-config


    # Dépendances Linux pour Flutter
    pkgs.gtk3
    pkgs.glib
    pkgs.libepoxy



    # Outils optionnels utiles
    pkgs.git
    pkgs.curl
    pkgs.unzip
  ];

  shellHook = ''
    export LD_LIBRARY_PATH=${pkgs.sqlite.out}/lib:$LD_LIBRARY_PATH
    echo "✅ Environnement de développement TaxasGE prêt"
    echo "➡️  Utilise 'flutter pub get' pour installer les dépendances."
    echo "➡️  Lance tes tests avec : flutter test test/integration/database_test.dart"
  '';
}
