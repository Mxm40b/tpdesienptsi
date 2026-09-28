{
  description = "Flutter FHS Development Environment";

  inputs = {
    # nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      # let
      #   pkgs = nixpkgs.legacyPackages.${system};

      #   fhs = pkgs.buildFHSEnv {
      #     name = "flutter-fhs-dev";
      #     targetPkgs = pkgs: (with pkgs; [
      #       # Flutter SDK & Linux build chain
      #       flutter
      #       clang
      #       gcc
      #       cmake
      #       ninja
      #       pkg-config

      #       # Core UI & Fonts
      #       gtk3
      #       fontconfig
      #       roboto
      #     ]);

      #     # Drops you into your default interactive shell ($SHELL)
      #     # runScript = "bash -c 'export SHELL=$(getent passwd $USER | cut -d: -f7); exec $SHELL'";


      #     runScript = pkgs.writeShellScript "flutter-shell" ''
      #       export CC="${pkgs.gcc}/bin/gcc"
      #       export CXX="${pkgs.gcc}/bin/g++"

      #       exec bash
      #     '';
      #   };
      # in
      let
        pkgs = nixpkgs.legacyPackages.${system};

        clangForFlutter = pkgs.writeShellScriptBin "clang++-flutter" ''
          gcc_crt="$(gcc -print-file-name=crtbeginS.o)"

          if [ ! -f "$gcc_crt" ]; then
            echo "error: cannot find GCC crtbeginS.o" >&2
            exit 1
          fi

          exec clang++ -B"$(dirname "$gcc_crt")" "$@"
        '';

        fhs = pkgs.buildFHSEnv {
          name = "flutter-fhs-dev";

          targetPkgs = pkgs: with pkgs; [
            flutter
            clangForFlutter
            clang
            gcc
            cmake
            ninja
            pkg-config

            gtk3
            fontconfig
            roboto
          ];

          runScript = pkgs.writeShellScript "flutter-shell" ''
            export CXX="${clangForFlutter}/bin/clang++-flutter"
            # exec bash
           bash -c 'export SHELL=$(getent passwd $USER | cut -d: -f7); exec $SHELL'
          '';
        };
      in
      {
        devShells.default = fhs.env;
      }
    );
}
