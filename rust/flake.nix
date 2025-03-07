{
  description = "C Dev Shell";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    nixvim-master = {
      url = "github:nix-community/nixvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixvim-config = {
      url = "github:aw-andre/nixvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      nixpkgs,
      nixvim-config,
      ...
    }:
    let
      pkgs = nixpkgs.legacyPackages."x86_64-linux";
      module-added = {
        plugins = {
          dap-lldb.enable = true;
          lsp.servers.rust_analyzer = {
            enable = true;
            installCargo = true;
            installRustc = true;
            installRustfmt = true;
            settings.check.command = "clippy";
          };
        };
        extraPackages = with pkgs; [
          clippy
        ];
      };
      nixvim-old = nixvim-config.packages."x86_64-linux".default;
      nixvim-modified = nixvim-old.extend module-added;
    in
    {
      devShells."x86_64-linux".default = pkgs.mkShell {
        buildInputs = [ nixvim-modified ];
        packages = with pkgs; [
          gcc
          rustc
          cargo
        ];
        shellHook = ''
          export RUST_BACKTRACE=1
        '';
      };
    };
}
