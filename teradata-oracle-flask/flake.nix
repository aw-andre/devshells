{
  description = "Teradata/Oracle Dev Shell";

  inputs.nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";

  outputs = { nixpkgs, ... }:
    let pkgs = nixpkgs.legacyPackages."x86_64-linux";
    in with pkgs;
    let
      teradata-jdbc = stdenv.mkDerivation {
        name = "teradata-jdbc";
        src = ./teradata-jdbc-20.tar;
        nativeBuildInputs = [ gnutar ];
        buildInputs = [ openjdk17 ];
        installPhase = ''
          mkdir -p $out/lib
          mkdir tmp
          tar -xf $src -C tmp --strip-components=1
          mv tmp/terajdbc4.jar $out/lib
        '';
      };
      teradata-odbc = stdenv.mkDerivation {
        name = "teradata-odbc";
        src = ./teradata-odbc-20.tar.gz;
        nativeBuildInputs = [ gnutar rpmextract ];
        installPhase = ''
          mkdir -p $out/lib
          mkdir tmp
          tar -xzf $src -C tmp --strip-components=1
          rpmextract tmp/*
          mv opt tmp
          mv tmp/opt/teradata/client/20.00/* $out/lib
        '';
      };
      oracle-instant-client = stdenv.mkDerivation {
        name = "oracle-instant-client";
        src = ./oracle;
        sourceRoot = ".";
        nativeBuildInputs = [ unzip ];
        installPhase = ''
          mkdir -p $out/lib
          mkdir tmp
          unzip -o $src/oracle-instantclient-23.26.zip -d tmp
          unzip -o $src/oracle-odbc-23.26.zip -d tmp
          mv tmp/instantclient_23_26/* $out/lib
        '';
      };
    in {
      devShells."x86_64-linux".default = pkgs.mkShell {
        packages = with pkgs; [
          python313Packages.python
          python313Packages.ipython
        ];
        buildInputs = [ teradata-jdbc teradata-odbc oracle-instant-client ];
        shellHook = ''
          export CLASSPATH=${teradata-jdbc}/lib/terajdbc4.jar:${oracle-instant-client}/lib/ojdbc17.jar
          export LD_LIBRARY_PATH=${teradata-odbc}/lib:${oracle-instant-client}/lib:$LD_LIBRARY_PATH
          export TNS_ADMIN=${oracle-instant-client}/lib/network/admin
        '';
      };
    };
}
