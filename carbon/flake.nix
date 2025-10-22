{
  description = "C++ Dev Shell with Custom LLVM Toolchain";

  inputs.nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};

      # Custom LLVM toolchain definition
      customToolchain = pkgs.callPackage ({ lib, llvmPackages_21, overrideCC
        , stdenv, targetPackages, useMoldLinker, wrapCCWith }:
        let
          # Adapted from clangUseLLVM.
          # See: https://github.com/NixOS/nixpkgs/blob/master/pkgs/development/compilers/llvm/common/default.nix
          clangVersion = "21";
          targetLlvmLibraries = targetPackages.llvmPackages_21.libraries;

          mkExtraBuildCommands0 = cc: ''
            rsrc="$out/resource-root"
            mkdir "$rsrc"
            ln -s "${lib.getLib cc}/lib/clang/${clangVersion}/include" "$rsrc"
            echo "-resource-dir=$rsrc" >> $out/nix-support/cc-cflags
          '';
          mkExtraBuildCommands = cc:
            mkExtraBuildCommands0 cc + ''
              ln -s "${targetLlvmLibraries.compiler-rt.out}/lib" "$rsrc/lib"
              ln -s "${targetLlvmLibraries.compiler-rt.out}/share" "$rsrc/share"
            '';

          toolchain' = wrapCCWith (rec {
            cc = llvmPackages_21.clang-unwrapped;
            inherit (targetLlvmLibraries) libcxx;
            inherit (llvmPackages_21) bintools;
            extraPackages =
              [ targetLlvmLibraries.compiler-rt targetLlvmLibraries.libunwind ];
            extraBuildCommands = mkExtraBuildCommands cc;
          } // {
            nixSupport.cc-cflags = [
              "-rtlib=compiler-rt"
              "-Wno-unused-command-line-argument"
              "-B${targetLlvmLibraries.compiler-rt}/lib"
              "-stdlib=libc++"
            ] ++ lib.optional stdenv.targetPlatform.isLinux "-fuse-ld=mold"
              ++ lib.optional (!stdenv.targetPlatform.isWasm
                && !stdenv.targetPlatform.isFreeBSD) "--unwindlib=libunwind"
              ++ lib.optional (!stdenv.targetPlatform.isWasm
                && !stdenv.targetPlatform.isFreeBSD
                && stdenv.targetPlatform.useLLVM or false) [
                  "-lunwind"
                  "-lc++"
                ]
              ++ lib.optional stdenv.targetPlatform.isWasm "-fno-exceptions";
            nixSupport.cc-ldflags = lib.optionals (!stdenv.targetPlatform.isWasm
              && !stdenv.targetPlatform.isFreeBSD) [
                "-L${targetLlvmLibraries.libunwind}/lib"
                "-rpath"
                "${targetLlvmLibraries.libunwind}/lib"
                "-L${targetLlvmLibraries.libcxx}/lib"
                "-rpath"
                "${targetLlvmLibraries.libcxx}/lib"
              ];
          });

          stdenv' = overrideCC llvmPackages_21.libcxxStdenv toolchain';

          toolchain = if stdenv.targetPlatform.isDarwin then
            stdenv' # Mold doesn't support darwin.
          else
            useMoldLinker stdenv';
          # This toolchain uses Clang as compiler, Mold as linker, libc++ as C++
          # standard library and compiler-rt as compiler runtime. Resulting rust
          # binaries depend dynamically linked on the nixpkgs distribution of glibc.
          # C++ binaries additionally depend dynamically on libc++, libunwind and
          # libcompiler-rt. Due to a bug we also depend on libgcc_s.
          #
          # At the moment this toolchain is only used for the Cargo
          # build. The Bazel build uses a different mostly hermetic LLVM toolchain. We
          # should merge the two by generating the Bazel cc_toolchain from this stdenv.
          # This likely requires a rewrite of
          # https://github.com/bazelbuild/bazel-toolchains as the current implementation
          # has poor compatibility with custom container images and doesn't support
          # generating toolchain configs from image archives.
          #
          # Due to various issues in the nixpkgs LLVM toolchains
          # we're not getting a pure Clang/LLVM toolchain here. My guess is that the
          # runtimes were not built with the degenerate LLVM toolchain but with the
          # regular GCC stdenv from nixpkgs.
          #
          # For instance, outputs depend on libgcc_s since libcxx seems to have been was
          # built with a GCC toolchain. We're also not using builtin atomics, or at
          # least we're redundantly linking libatomic.
          #
          # Fix this as it fixes a large number of issues, including better
          # cross-platform compatibility, reduced closure size, and
          # static-linking-friendly licensing. This requires building the llvm project
          # with the correct multistage bootstrapping process.
        in toolchain) { };

    in {
      devShells.${system}.default =
        pkgs.mkShell.override { stdenv = customToolchain; } {
          buildInputs = with pkgs; [
            # Build tools
            bazelisk
            (symlinkJoin {
              name = "coreutils";
              paths = with pkgs; [ bash coreutils ];
            })
            cmake
            ninja
            pkg-config

            # Development tools
            gdb
            lldb
            valgrind

            # Language support
            python3
          ];

          shellHook = ''
            echo "Custom LLVM/Clang toolchain environment activated"
            echo "Clang version: $(clang --version | head -1)"
            echo "Linker: mold (on Linux) or default (on Darwin)"
            echo "C++ stdlib: libc++"
            echo "Runtime: compiler-rt"
          '';
        };
    };
}
