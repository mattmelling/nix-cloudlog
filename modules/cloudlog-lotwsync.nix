{ config, pkgs, lib, ... }:
let
  cfg = config.services.cloudlog-lotwsync;
in
{
  options = with lib.types; {
    services.cloudlog-lotwsync = {
      enable = lib.mkEnableOption "cloudlog-lotwsync";
      url = lib.mkOption {
        type = str;
        description = "Base URL of the Cloudlog instance.";
      };
      schedule = lib.mkOption {
        type = str;
        default = "*-*-* 00/3:00:00";
        description = "systemd-timer schedule for the synchronisation task.";
      };
    };
  };
  config = lib.mkIf cfg.enable {
    systemd = {
      services = {
        cloudlog-lotwsync = {
          description = "cloudlog lotw sync";
          enable = true;
          serviceConfig = {
            ExecStart = "${pkgs.curl}/bin/curl -s ${cfg.url}/lotw/lotw_upload";
          };
        };
      };
      timers = {
        cloudlog-lotwsync = {
          enable = true;
          wantedBy = [ "timers.target" ];
          partOf = [ "cloudlog-lotwsync.service" ];
          timerConfig = {
            OnCalendar = cfg.schedule;
            Persistent = true;
          };
        };
      };
    };
  };
}
