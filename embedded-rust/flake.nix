{
  description = "Embedded Rust Dev Shell";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    rust-overlay.url = "github:oxalica/rust-overlay";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { nixpkgs, rust-overlay, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        overlays = [ (import rust-overlay) ];
        pkgs = import nixpkgs { inherit system overlays; };
        toolchain = pkgs.rust-bin.fromRustupToolchainFile ./toolchain.toml;
      in {
        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            gcc
            gdb
            cargo-binutils
            itm-tools
            minicom
            toolchain
          ];
          shellHook = ''
            export RUST_BACKTRACE=1
          '';
        };
      });
}
