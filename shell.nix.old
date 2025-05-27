{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  buildInputs = [
    (pkgs.python311.withPackages (ps: [
      ps.numpy
      ps.tensorflow-bin   # 2.13.0 pré-compilé
      ps.keras            # 2.13.x  ← indispensable pour tf.keras
      ps.scikit-learn     # sklearn
      ps.pip
    ]))
    pkgs.sqlite
  ];
}
