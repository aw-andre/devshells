{
  description = "C Dev Shell";

  inputs.nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";

  outputs = { nixpkgs, ... }:
    let pkgs = nixpkgs.legacyPackages."x86_64-linux";
    in {
      devShells."x86_64-linux".default = pkgs.mkShell rec {
        nativeBuildInputs = with pkgs; [ pkg-config ];
        buildInputs = with pkgs; [
          udev
          alsa-lib
          vulkan-loader
          xorg.libX11
          xorg.libXcursor
          xorg.libXi
          xorg.libXrandr # To use the x11 feature
          libxkbcommon
          wayland # To use the wayland feature
        ];
        LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath buildInputs;
        packages = with pkgs; [ gcc rustc clippy cargo ];
        shellHook = ''
          export RUST_BACKTRACE=1
        '';
      };
    };
}
