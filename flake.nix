{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };
  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs {
          inherit system;
        };
      in
      {
        packages.picoquic = pkgs.stdenv.mkDerivation {
          name = "picoquic";
          src = self;
          buildInputs = with pkgs; [
            cmake
            pkg-config
            openssl
          ];
          dontUseCmakeConfigure = true; # build manually without nix magic
          buildPhase = ''
            mkdir -p $out/lib
            mkdir -p $out/include
            mkdir -p $out/bin
            cd $TMP/source/submodules/picotls
            cmake -S . -B ./build
            cmake --build ./build -- -j 10
            cp ./build/*.a $out/lib/
            cp -r ./include/* $out/include/
            cd $TMP/source
            cmake -S . -B ./build -DPTLS_PREFIX=$out -DCMAKE_INSTALL_PREFIX=$out
            cmake --build ./build -- -j 10
            cmake --install ./build
            cp ./build/picoquic_ct $out/bin/
            cp ./build/picohttp_ct $out/bin/
            cp ./build/pico_baton $out/bin/
            cp ./build/picoquic_sample $out/bin/
            cp ./build/thread_test $out/bin/
          '';
        };
        packages.default = self.packages.${system}.picoquic;
      }
    );
}
