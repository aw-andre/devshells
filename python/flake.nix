{
  description = "Python Dev Shell";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    nixvim = {
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
      self,
      nixpkgs,
      nixvim,
      nixvim-config,
    }:
    let
      pkgs = nixpkgs.legacyPackages."x86_64-linux";
      module-added = {
        plugins = {
          conform-nvim.settings.formatters_by_ft.python = [ "black" ];
          dap-python.enable = true;
          lint.lintersByFt.python = [ "ruff" ];
          lsp.servers.pyright.enable = true;
        };
        extraPackages = with pkgs; [
          black
          ruff
        ];
      };
      nixvim-old = nixvim-config.packages."x86_64-linux".default;
      nixvim-modified = nixvim-old.extend module-added;
    in
    {
      devShells."x86_64-linux".default = pkgs.mkShell {
        buildInputs = [ nixvim-modified ];
        packages = with pkgs; [
          python3Full
        ];
      };
    };
}
