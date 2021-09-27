{
  description = "SearXR aframe frontend";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs";
  inputs.aframe-searxr = { url = "gitlab:SearXR/aframe-searxr"; flake = false; };

  outputs = { self, nixpkgs, ... }@inputs:
    let
      supportedSystems = [ "x86_64-linux" ];

      forAllSystems = f: nixpkgs.lib.genAttrs supportedSystems (system: f system);

      nixpkgsFor = forAllSystems (
        system:
          import nixpkgs {
            inherit system;
            overlays = [ self.overlay ];
          }
      );
    in
      {
        overlay = final: prev: with prev; {
          aframe-searxr = stdenv.mkDerivation {
            pname = "aframe-searxr";
            version = "unstable-2021-09-01";

            src = inputs.aframe-searxr;

            buildPhase = ''
              cd src
              patchShebangs build.sh
              ./build.sh
            '';

            postBuild = ''
              cp build.html index.html
            '';
          };
        };

        packages = forAllSystems (
          system: {
            inherit (nixpkgsFor.${system}) aframe-searxr;
          }
        );

        defaultPackage = forAllSystems (
          system:
            self.packages.${system}.aframe-searxr
        );

        devShell = self.defaultPackage;
      };
}
