{
  description = "C Dev Shell";

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
      module-added = nixpkgs.lib.mkForce {
        plugins = {
          conform-nvim.settings.formatters_by_ft.c = [ "rustfmt" ];
          dap = {
            adapters.executables.lldb.command = "${pkgs.lldb_19}/bin/lldb-dap";
            configurations.rust = [
              {
                name = "lldb";
                type = "lldb";
                request = "launch";
                program.__raw = ''
                  function()
                      return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. '/', "file")
                  end'';
              }
            ];
          };
          lint.lintersByFt.rust = [ "clippy" ];
          lsp.servers.rust_analyzer = {
            enable = true;
            installCargo = true;
            installRustc = true;
            installRustfmt = true;
          };
        };
        extraPackages = with pkgs; [
          rustfmt
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
          cargo
        ];
      };
    };
}
