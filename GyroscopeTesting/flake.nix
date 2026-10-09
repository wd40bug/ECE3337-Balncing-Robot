{
  description = "Clean Python virtual environment with Fish and Apio";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      nixpkgs,
      flake-utils,
      ...
    }:

    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs { inherit system; };
      in
      {
        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            python3
            python3Packages.pip
            python3Packages.virtualenv
            fish
            openfpgaloader
          ];

          buildInputs = with pkgs; [
            udev
          ];

          LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath (with pkgs; [ udev ]);

          shellHook = ''
            export GIO_MODULE_DIR="$(mktemp -d)"
            export GSETTINGS_BACKEND=memory
            export GDK_BACKEND=x11

            VENV=.venv

            if [ ! -d "$VENV" ]; then
              echo "Creating virtual environment..."
              python -m venv "$VENV"
            fi

            source ./$VENV/bin/activate
          '';
        };
      }
    );
}
