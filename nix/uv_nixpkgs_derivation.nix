{
  pkgs,
  lib,
  python,
  pyproject-nix,
  uv2nix,
  pyproject-build-systems,
}:
let
  # The name of your project as seen in pyproject.toml. Must match exactly.
  projectNameInPyproject = "uv-nixpkgs";

  # The uv2nix representation of your uv workspace.
  workspace = uv2nix.lib.workspace.loadWorkspace { workspaceRoot = ../.; };

  # An overlay containing all dependencies for the project contained in uv.lock.
  overlay = workspace.mkPyprojectOverlay { sourcePreference = "wheel"; };

  # A package set containing the appropriate build system, the correct version
  # of Python with dependencies from uv.lock overlayed over top. 
  pythonSet = (pkgs.callPackage pyproject-nix.build.packages { inherit python; }).overrideScope (
    lib.composeManyExtensions [
      pyproject-build-systems.overlays.wheel
      overlay
    ]
  );

  inherit (pkgs.callPackages pyproject-nix.build.util { }) mkApplication;

in
mkApplication rec {
  venv = pythonSet.mkVirtualEnv (projectNameInPyproject + "-env") workspace.deps.default;
  package = pythonSet.${projectNameInPyproject};
}
