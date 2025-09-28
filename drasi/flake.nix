{
  description = "Drasi Dev Shell";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let pkgs = import nixpkgs { inherit system; };
      in {
        devShells.default = (pkgs.buildFHSEnv {
          name = "drasi-dev-env";
          targetPkgs = pkgs:
            with pkgs; [
              # building
              cargo
              docker
              gnumake
              go
              kubectl
              nodejs_latest

              # running
              dapr-cli
              k3d
              kind

              # committing
              rustfmt

              # testing
              clang
              cryptsetup
              pkg-config
              protobuf
              (buildEnv {
                name = "combinedSdk";
                paths = [
                  (with dotnetCorePackages; combinePackages [ sdk_8_0 sdk_9_0 ])
                ];
              })
            ];
          runScript = "zsh";
          profile = ''
            export RUST_BACKTRACE=1
            export LIBCLANG_PATH="${pkgs.llvmPackages.libclang.lib}/lib"
          '';
        }).env;
      });
}
