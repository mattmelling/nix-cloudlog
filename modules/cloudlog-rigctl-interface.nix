{ pkgs, config, lib, ... }:
let
  cfg = config.services.cloudlog-rigctl-interface;
in
{
  options = with lib.types; {
    services.cloudlog-rigctl-interface = {
      enable = lib.mkEnableOption "cloudlog-rigctl-interface";
      rigctl = {
        host = lib.mkOption {
          type = str;
          default = "127.0.0.1";
          description = "rigctl hostname";
        };
        port = lib.mkOption {
          type = int;
          default = 4532;
          description = "rigctl port";
        };
      };
      cloudlog = {
        url = lib.mkOption {
          type = str;
          default = "http://127.0.0.1";
          description = "Cloudlog base URL";
        };
        key = lib.mkOption {
          type = str;
          description = "Path to file containing Cloudlog API key";
        };
      };
      name = lib.mkOption {
        type = str;
        default = "radio";
      };
    };
  };
  config = lib.mkIf cfg.enable {
    systemd.services.cloudlog-rigctl-interface = {
      description = "cloudlog-rigctl-interface";
      enable = true;
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        ExecStart = "${pkgs.php}/bin/php ${pkgs.cloudlog-rigctl-interface}/rigctlCloudlogInterface.php";
      };
      environment = {
        RIGCTL_HOST = cfg.rigctl.host;
        RIGCTL_PORT = toString cfg.rigctl.port;
        CLOUDLOG_URL = cfg.cloudlog.url;
        CLOUDLOG_KEY = cfg.cloudlog.key;
        RADIO_NAME = cfg.name;
      };
    };
  };
}
