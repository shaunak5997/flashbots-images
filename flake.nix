{
  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
  let
    forAllSystems = f: {
      x86_64-linux = f "x86_64-linux";
      aarch64-linux = f "aarch64-linux";
    };
  in {
    devShells = forAllSystems (system:
      let
        pkgs = import nixpkgs { inherit system; };

        reprepro = pkgs.stdenv.mkDerivation rec {
          name = "reprepro-${version}";
          version = "4.16.0";

          src = pkgs.fetchurl {
            url = "https://alioth.debian.org/frs/download.php/file/4109/reprepro_${version}.orig.tar.gz";
            sha256 = "14gmk16k9n04xda4446ydfj8cr5pmzsmm4il8ysf69ivybiwmlpx";
          };

          nativeBuildInputs = [ pkgs.makeWrapper ];
          buildInputs = pkgs.lib.singleton (pkgs.gpgme.override { gnupg = pkgs.gnupg; })
                    ++ (with pkgs; [ db libarchive bzip2 xz zlib ]);

          postInstall = ''
            wrapProgram "$out/bin/reprepro" --prefix PATH : "${pkgs.gnupg}/bin"
          '';
        };

        mkosi = pkgs.mkosi.override {
          extraDeps = with pkgs; [
            apt dpkg gnupg debootstrap
            squashfsTools dosfstools e2fsprogs mtools mustache-go
            cryptsetup util-linux zstd which qemu-utils
          ] ++ [ reprepro ];
        };
      in {
        default = pkgs.mkShell {
          nativeBuildInputs = [ pkgs.qemu mkosi ];
          shellHook = ''
            mkdir -p mkosi.packages mkosi.cache mkosi.builddir ~/.cache/mkosi
          '';
        };
      }
    );
  };
}
