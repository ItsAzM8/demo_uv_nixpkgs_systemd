{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=release-25.05";
    flake-utils.url = "github:numtide/flake-utils";

    # Core pyproject-nix ecosystem tools
    pyproject-nix.url = "github:pyproject-nix/pyproject.nix";
    uv2nix.url = "github:pyproject-nix/uv2nix";
    pyproject-build-systems.url = "github:pyproject-nix/build-system-pkgs";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      pyproject-nix,
      uv2nix,
      pyproject-build-systems,
      ...
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs { inherit system; };
        python = pkgs.python312;

        demoUvNixpkgsDerivation = pkgs.callPackage ./nix/uv_nixpkgs_derivation.nix {
          inherit pyproject-nix uv2nix pyproject-build-systems python;
        };

      in
      rec {
        packages.demoUvNixpkgsDerivation = demoUvNixpkgsDerivation;
        packages.default = packages.demoUvNixpkgsDerivation;

        devShells.default = pkgs.mkShell {
          name = "demoUvNixpkgsDerivation-devshell";
          inputsFrom = [ packages.demoUvNixpkgsDerivation ];
          nativeBuildInputs = with pkgs; [ nixfmt-rfc-style ];
        };
      }
    )
    // flake-utils.lib.eachDefaultSystemPassThrough (
      system:
      let
        pkgs = import nixpkgs { inherit system; };
        systemdService = pkgs.callPackage ./nix/systemd-service.nix { inherit system; };
      in
      {
        nixosModules.demoUvNixpkgs =
          {
            pkgs,
            config,
            lib,
            ...
          }:
          let
            cfg = config.services.demoUvNixpkgs;
          in
          {
            options = pkgs.callPackage ./nix/systemd/options.nix {};
            
            # options = with lib; {
            #   services.demoUvNixpkgs = {
            #     enable = mkEnableOption "Demo UV Nixpkgs";

            #     package = mkOption {
            #       type = types.path;
            #       default = self.packages.${system}.default;
            #       description = "Package to use for UV Nixpkgs Demo service.";
            #     };
            #   };
            # };

            config = lib.mkIf cfg.enable {
              systemd.services.demoUvNixpkgs = {
                wants = [ "network-online.target" ];
                wantedBy = [ "multi-user.target" ];
                serviceConfig = {
                  Type = "simple";
                  Restart = "always";
                  DynamicUser = "yes";
                  ExecStart = "${cfg.package}/bin/uv-nixpkgs";
                };
              };
            };
          };
      }
    );
}
