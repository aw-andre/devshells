{
  description = "Rust Dev Shell";

  inputs.nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";

  outputs = { nixpkgs, ... }:
    let pkgs = nixpkgs.legacyPackages."x86_64-linux";
    in {
      devShells."x86_64-linux".default = pkgs.mkShell rec {
        packages = with pkgs; [
          gcc
          gdb
          rustc
          clippy
          cargo
          cargo-binutils
          itm-tools
          minicom
        ];
        shellHook = ''
          export RUST_BACKTRACE=1
        '';
      };
    };
}
