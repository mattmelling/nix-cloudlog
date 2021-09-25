{ pkgs, config, lib, ... }:
let
  cfg = config.services.cloudlog-adifwatch;
  services = lib.mapAttrsToList (name: path: {
    name = "cloudlog-adifwatch-${name}";
    value = {
      description = "cloudlog-adifwatch ${name}";
      enable = true;
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
      serviceConfig = {
        ExecStart = "${pkgs.cloudlog-adifwatch}/bin/cloudlog-adifwatch ${cfg.host} ${cfg.key} ${path}";
      };
    };
  }) cfg.watchers;
in
{
  options = with lib.types; {
    services.cloudlog-adifwatch = {
      enable = lib.mkEnableOption "cloudlog-adifwatch";
      watchers = lib.mkOption {
        type = attrsOf str;
        default = { };
        description = "Attrs of files to watch.";
        example = {
          wsjtx = "/home/user/wsjtx/wsjtx.adi";
        };
      };
      key = lib.mkOption {
        type = str;
        description = "Path to key for Cloudlog instance.";
      };
      host = lib.mkOption {
        type = str;
        description = "Hostname of Cloudlog instance.";
      };
    };
  };
  config = lib.mkIf cfg.enable {
    systemd.services = builtins.listToAttrs services;
  };
}
