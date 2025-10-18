{
  description = "A very basic flake";

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
        python = pkgs.python312;

        # The workspace (i.e., directory containing pyproject.toml and uv.lock).
        workspace = uv2nix.lib.workspace.loadWorkspace { workspaceRoot = ./.; };

        # Pulls in dependencies by reading your uv.lock and fetching wheels.
        uvLockedOverlay =
          workspace.mkPyprojectOverlay { sourcePreference = "wheel"; };

        # The attribute set containing your Python version and uv dependencies.
        pythonSet = (pkgs.callPackage pyproject-nix.build.packages {
          inherit python;
        }).overrideScope (nixpkgs.lib.composeManyExtensions [
          pyproject-build-systems.overlays.default
          uvLockedOverlay
        ]);

        # Must match package name in pyproject.toml.
        projectNameInToml = "uv-nixpkgs";
        wheelName = builtins.replaceStrings [ "-" ] [ "_" ] projectNameInToml;

        # Create a nix package containing this project to use
        # as a dependency
        thisProjectAsNixPkg = pythonSet.${projectNameInToml};

        # Creates final Python env with everything needed to run your
        # service.
        appPythonEnv =
          pythonSet.mkVirtualEnv (thisProjectAsNixPkg.pname + "-env")
          workspace.deps.default;

      in {

        nixosModules.uv_nixpkgs = { pkgs, lib, config }:
          let cfg = config.services.uv_nixpkgs;
          in {
            options = with lib; {
              services.uv_nixpkgs = let
              in {
                enable = mkEnableOption "UV Nixpkgs Demo";

                package = mkOption {
                  type = types.path;
                  default = self.pakcages.${system}.default;
                  description = "Package to use for UV Nixpkgs Demo service.";
                };
              };

              config = lib.mkIf cfg.enable {
                systemd.services = {
                  serviceConfig = {
                    Type = "notify";
                    UMask = "0027";
                    # SystemCallFilter = "@aio @basic-io @chown @file-system @io-event @network-io @sync";
                    NoNewPrivileges = true;
                    PrivateDevices = true;
                    ProtectHostname = true;
                    ProtectClock = true;
                    ProtectKernelTunables = true;
                    ProtectKernelModules = true;
                    ProtectKernelLogs = true;
                    ProtectControlGroups = true;
                    MemoryDenyWriteExecute = true;
                    ExecStart = "${cfg.package}/bin/uv-nixpkgs";
                    Restart = "on-failure";
                    User = "root";
                    ProtectSystem = "strict";
                  };
                };
              };

            };
          };

        # Packaging Python service as Nix derivation to be used elsewhere.
        packages.default = pkgs.stdenv.mkDerivation {
          pname = thisProjectAsNixPkg.pname;
          version = thisProjectAsNixPkg.version;
          src = ./.;

          nativeBuildInputs = [
            pkgs.makeWrapper
            pkgs.python312Packages.uv
            pkgs.python312Packages.uv-build
          ];

          buildInputs = [ appPythonEnv ];

          # Build with these args since Python and all dependencies
          # are already installed by previous steps.
          buildPhase = ''
            uv build --no-cache --no-build-isolation --no-managed-python
          '';

          installPhase = ''
            mkdir -p $out/bin
            cp dist/${wheelName}-${thisProjectAsNixPkg.version}-py3-none-any.whl $out/bin/${thisProjectAsNixPkg.pname}-script

            makeWrapper ${appPythonEnv}/bin/python $out/bin/${thisProjectAsNixPkg.pname} \
              --add-flags $out/bin/${thisProjectAsNixPkg.pname}-script/${wheelName}
          '';
        };

        packages.${thisProjectAsNixPkg.pname} = self.packages.${system}.default;

        # What will be run when using `nix run`.
        apps.default = {
          type = "app";
          program = "${
              self.packages.${system}.default
            }/bin/${thisProjectAsNixPkg.pname}";
        };
        apps.${thisProjectAsNixPkg.pname} = self.apps.${system}.default;
      });
}
