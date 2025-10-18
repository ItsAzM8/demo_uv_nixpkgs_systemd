{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=release-25.05";
    flake-utils.url = "github:numtide/flake-utils";

    # Core pyproject-nix ecosystem tools
    pyproject-nix.url = "github:pyproject-nix/pyproject.nix";
    uv2nix.url = "github:pyproject-nix/uv2nix";
    pyproject-build-systems.url = "github:pyproject-nix/build-system-pkgs";
  };

  outputs = { self, nixpkgs, flake-utils, pyproject-nix, uv2nix
    , pyproject-build-systems, ... }:
    flake-utils.lib.eachDefaultSystem (system:

      let
        pkgs = import nixpkgs { inherit system; };
        systemdService = import ./nix/systemd-service.nix;
        demoUvNixpkgsSystemd =
          pkgs.callPackage ./nix/uv_nixpkgs_derivation.nix {
            inherit pyproject-nix uv2nix pyproject-build-systems;
          };

      in {
        # Configuration for the systemd service.
        nixosModules.uv_nixpkgs = systemdService;
        nixosModules.default = systemdService;

        # The built application for this Flake.
        # What gets build with `nix flake build`.
        packages.default = demoUvNixpkgsSystemd;

        # Registering as a package within the
        # `packages` attribute set.
        packages.${demoUvNixpkgsSystemd.pname} =
          self.packages.${system}.default;

        # The configuration for what gets run when
        # using `nix flake run`.
        apps.default = {
          type = "app";
          program = "${
              self.packages.${system}.default
            }/bin/${demoUvNixpkgsSystemd.pname}";
        };


        # Registering as a package within the
        # `apps` attribute set.
        apps.${demoUvNixpkgsSystemd.pname} = self.apps.${system}.default;
      });
}
