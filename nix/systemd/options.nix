{ config, }:
let
in {
    options = with lib; {
        services.demoUvNixpkgs = {
            enable = mkEnableOption "Demo UI Nixpkgs";
        };
    };
}