{
  description = "Plasma: ANIMIST's libLoam and libPlasma";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    { self, nixpkgs }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
      forAllSystems =
        f:
        nixpkgs.lib.genAttrs systems (
          system: f system nixpkgs.legacyPackages.${system}
        );
    in
    {
      packages = forAllSystems (
        system: pkgs: {
          plasma = pkgs.callPackage ./package.nix { };
          default = self.packages.${system}.plasma;
        }
      );

      checks = forAllSystems (
        system: pkgs: {
          plasma = self.packages.${system}.plasma;
        }
      );

      devShells = forAllSystems (
        system: pkgs: {
          default = pkgs.mkShell {
            inputsFrom = [ self.packages.${system}.plasma ];
          };
        }
      );
    };
}
