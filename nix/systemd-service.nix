{ pkgs, lib, config }:
let
  # cfg = config.services.uv_nixpkgs;
in {
  enable = pkgs.mkEnableOption "UV Nixpkgs Demo";

  # package = pkgs.mkOption {
  #   type = types.path;
  #   default = self.packages.${system}.default;
  #   description = "Package to use for UV Nixpkgs Demo service.";
  # };

  # config = lib.mkIf cfg.enable {
  #   systemd.services = {
  #     serviceConfig = {
  #       Type = "notify";
  #       UMask = "0027";
  #       # SystemCallFilter = "@aio @basic-io @chown @file-system @io-event @network-io @sync";
  #       NoNewPrivileges = true;
  #       PrivateDevices = true;
  #       ProtectHostname = true;
  #       ProtectClock = true;
  #       ProtectKernelTunables = true;
  #       ProtectKernelModules = true;
  #       ProtectKernelLogs = true;
  #       ProtectControlGroups = true;
  #       MemoryDenyWriteExecute = true;
  #       ExecStart = "${cfg.package}/bin/uv-nixpkgs";
  #       Restart = "on-failure";
  #       User = "root";
  #       ProtectSystem = "strict";
  #     };
  #   };
  # };
}
