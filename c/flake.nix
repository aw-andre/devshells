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
          conform-nvim.settings.formatters_by_ft.c = [ "clang-format" ];
          dap-lldb.enable = true;
          lint.lintersByFt.c = [ "cppcheck" ];
          lsp.servers.clangd.enable = true;
        };
        extraPackages = with pkgs; [
          llvmPackages_19.clang-unwrapped
          cppcheck
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
          gdb
          valgrind
        ];
      };
    };
}
