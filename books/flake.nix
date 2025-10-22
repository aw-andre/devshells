{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-2505.url = "github:NixOS/nixpkgs/nixos-25.05";
  };

  outputs = { self, nixpkgs, nixpkgs-2505 }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      pkgs2505 = nixpkgs-2505.legacyPackages.${system};
    in {
      devShells.${system}.default = pkgs.mkShell {
        packages = [
          pkgs.libmtp
          pkgs.simple-mtpfs
          pkgs2505.k2pdfopt
          (pkgs.writeShellScriptBin "tokfx" ''
            simple-mtpfs kindle
            for BOOK in "$@"; do
              NAME="''${BOOK%.epub}"
              ebook-convert "$NAME.epub" "$NAME.kfx" --output-profile kindle  && \
              mkdir "$NAME"                                                   && \
              mv "$NAME.kfx" "$NAME"                                          && \
              mv "$NAME" kindle/documents
            done
          '')
        ];
      };
    };
}
