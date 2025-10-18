{ pkgs, lib, pyproject-nix, uv2nix, pyproject-build-systems }:
let
  python = pkgs.python312;

  # Must match package name in pyproject.toml.
  projectNameInToml = "uv-nixpkgs";
  wheelName = builtins.replaceStrings [ "-" ] [ "_" ] projectNameInToml;

  # Create a nix package containing this project to use
  # as a dependency
  thisProjectAsNixPkg = pythonSet.${projectNameInToml};

  # The workspace (i.e., directory containing pyproject.toml and uv.lock).
  workspace = uv2nix.lib.workspace.loadWorkspace { workspaceRoot = ../.; };

  # Pulls in dependencies by reading your uv.lock and fetching wheels.
  uvLockedOverlay =
    workspace.mkPyprojectOverlay { sourcePreference = "wheel"; };

  # The attribute set containing your Python version and uv dependencies.
  pythonSet = (pkgs.callPackage pyproject-nix.build.packages {
    inherit python;
  }).overrideScope (lib.composeManyExtensions [
    pyproject-build-systems.overlays.default
    uvLockedOverlay
  ]);

  # Creates final Python env with everything needed to run your
  # service.
  appPythonEnv = pythonSet.mkVirtualEnv (thisProjectAsNixPkg.pname + "-env")
    workspace.deps.default;
in pkgs.stdenv.mkDerivation {
  pname = thisProjectAsNixPkg.pname;
  version = thisProjectAsNixPkg.version;
  src = ../.;

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
}
