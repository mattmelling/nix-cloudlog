{ pkgs, lib, config, ... }:
with lib;
let
  cfg = config.services.cloudlog;
  listToString = value:
    "[ " + (concatStringsSep ", " (map valueToString value)) + "]";
  valueToString = value: with builtins;
    if typeOf value == "string" then "'${value}'"
    else (if typeOf value == "bool" then (if value then "true"
                                          else "false")
          else (if typeOf value == "list" then listToString value
                else toString value));
  setToString = name:
    let
      value = fullConfig."${name}";
    in concatStringsSep "\n"(map (nom: "$config['${name}'][${nom}] = ${valueToString fullConfig."${name}"."${nom}"};") (attrNames value));
  fullConfig = defaultConfig // cfg.config;
  cfgOptions = concatStringsSep "\n"
    (map (n: let
      value = fullConfig."${n}";
    in if builtins.typeOf value == "set" then setToString n
       else "$config['${n}'] = ${valueToString value};")
      (attrNames fullConfig));
  configFile = pkgs.writeText "config.php" ''
    <?php
    defined('BASEPATH') OR exit('No direct script access allowed');
    ${cfgOptions}
    date_default_timezone_set($config['time_reference']);
  '';
  databaseFile = pkgs.writeText "database.php" ''
    <?php
    defined('BASEPATH') OR exit('No direct script access allowed');
    $active_group = 'default';
    $query_builder = TRUE;
    $db['default'] = array(
      // The following values will probably need to be changed.
      'dsn' => "",
      'hostname' => '${cfg.mysql.host}',
      'username' => '${cfg.mysql.username}',
      'password' => "${cfg.mysql.password}",
      'database' => '${cfg.mysql.database}',
      // The following values can probably stay the same.
      'dbdriver' => 'mysqli',
      'dbprefix' => "",
      'pconnect' => TRUE,
      'db_debug' => (ENVIRONMENT !== 'production'),
      'cache_on' => FALSE,
      'cachedir' => "",
      'char_set' => 'utf8mb4',
      'dbcollat' => 'utf8mb4_general_ci',
      'swap_pre' => "",
      'encrypt' => FALSE,
      'compress' => FALSE,
      'stricton' => FALSE,
      'failover' => array(),
      'save_queries' => TRUE
    );'';
  defaultConfig = {
    app_name = "Cloudlog";
    app_version = "1.7";
    directory = "logbook";
    callbook = "hamqth";
    table_name = "TABLE_HRD_CONTACTS_V01";
    locator = "";
    display_freq = true;
    qrz_username = "";
    qrz_password = "";
    hamqth_username = "";
    hamqth_password = "";
    use_auth = true;
    auth_table = "users";
    auth_mode = "0";
    auth_level = {
      "0" = "Anonymous";
      "1" = "Viewer";
      "2" = "Editor";
      "3" = "API User";
      "99" = "Administrator";
    };
    base_url = "http://${cfg.virtualHost}/";
    index_page = "index.php";
    uri_protocol= "REQUEST_URI";
    url_suffix = "";
    language = "english";
    charset = "UTF-8";
    enable_hooks = false;
    subclass_prefix = "MY_";
    composer_autoload = false;
    permitted_uri_chars = "a-z 0-9~%.:_\-";
    enable_query_strings = false;
    controller_trigger = "c";
    function_trigger = "m";
    directory_trigger = "d";
    allow_get_array = true;
    log_threshold = 0;
    log_path = "";
    log_file_extension = "";
    log_file_permissions = 0644;
    log_date_format = "Y-m-d H:i:s";
    error_views_path = "";
    cache_path = "";
    cache_query_string = false;
    encryption_key = "flossie1234555541";
    sess_driver = "files";
    sess_cookie_name = "ci_cloudlog";
    sess_expiration = 0;
    sess_save_path = "/tmp";
    sess_match_ip = false;
    sess_time_to_update = 300;
    sess_regenerate_destroy = false;
    cookie_prefix	= "";
    cookie_domain	= "";
    cookie_path = "/";
    cookie_secure	= false;
    cookie_httponly 	= false;
    standardize_newlines = false;
    global_xss_filtering = false;
    csrf_protection = false;
    csrf_token_name = "csrf_test_name";
    csrf_cookie_name = "csrf_cookie_name";
    csrf_expire = 7200;
    csrf_regenerate = true;
    csrf_exclude_uris = [ ];
    compress_output = false;
    time_reference = "UTC";
    rewrite_short_tags = false;
    proxy_ips = "";
    datadir = cfg.dataDir + "/";
  };
  pkg = pkgs.stdenv.mkDerivation rec {
    pname = "cloudlog";
    version = src.version;
    src = config.services.cloudlog.package;
    installPhase = ''
      mkdir -p $out
      cp -r * $out/
      ln -s ${configFile} $out/application/config/config.php
      ln -s ${databaseFile} $out/application/config/database.php
      rm -rf $out/{updates,uploads}
      ln -s ${cfg.dataDir}/updates $out/updates
      ln -s ${cfg.dataDir}/uploads $out/uploads
      #rm -rf $out/install
    '';
  };
in
{
  options.services.cloudlog = {
    enable = mkEnableOption "cloudlog";
    package = mkOption {
      type = types.package;
      default = pkgs.cloudlog;
      description = "Which cloudlog package to use.";
    };
    user = mkOption {
      type = types.str;
      default = "cloudlog";
      description = ''
        User account under which Cloudlog runs.
      '';
    };
    group = mkOption {
      type = types.str;
      default = config.services.nginx.group;
      description = ''
        Group under which Cloudlog runs.
      '';
    };
    pool = mkOption {
      type = types.str;
      default = "cloudlog";
      description = ''
        Name of existing phpfpm pool that is used to run Cloudlog.
        If not specified a pool will be created automatically with
        default values.
      '';
    };
    virtualHost = mkOption {
      type = types.nullOr types.str;
      default = "localhost";
      description = ''
        Name of the nginx virtualhost to use and setup. If null, do not setup any virtualhost, nginx must be set up separately.
      '';
    };
    dataDir = mkOption {
      type = types.str;
      default = "/var/lib/cloudlog";
      description = "Cloudlog data directory.";
    };
    config = mkOption {
      default = defaultConfig;
      type =  with lib.types; let
        valueType = nullOr (oneOf [
          bool
          int
          float
          str
          (lazyAttrsOf valueType)
          (listOf valueType)
        ]) // {
          description = "Yaml value";
          emptyValue.value = {};
        };
      in valueType;
      example = literalExample ''
          {
            app_name = "cloudlog";
            directory = "logbook";
          }
      '';
    };
    mysql = {
      enable = mkEnableOption "cloudlog.mysql"; # todo: Make this clear that this enables mysql configuration, and to leave false
      host = mkOption {
        type = types.str;
        description = "MySQL database host";
        default = "localhost";
      };
      database = mkOption {
        type = types.str;
        description = "MySQL database name";
        default = "cloudlog";
      };
      username = mkOption {
        type = types.str;
        description = "MySQL user name";
        default = "cloudlog";
      };
      password = mkOption {
        type = types.str;
        description = "MySQL user password";
        default = "";
      };
      passwordFile = mkOption {
        type = types.str;
        description = "MySQL user password file";
        default = null;
      };
    };
  };
  config = mkIf cfg.enable {
    systemd.tmpfiles.rules = [
      "d '${cfg.dataDir}/updates' 0750 ${cfg.user} ${cfg.group} - -"
      "d '${cfg.dataDir}/uploads' 0750 ${cfg.user} ${cfg.group} - -"
      "d '${cfg.dataDir}/backup' 0750 ${cfg.user} ${cfg.group} - -"
    ];
    services.phpfpm.pools = {
      "${cfg.pool}" = {
        user = cfg.user;
        group = config.services.nginx.group;
        settings = mapAttrs (name: mkDefault) {
          "listen.owner" = config.services.nginx.user;
          "listen.mode" = "0600";
          "pm" = "dynamic";
          "pm.max_children" = 75;
          "pm.start_servers" = 10;
          "pm.min_spare_servers" = 5;
          "pm.max_spare_servers" = 20;
          "pm.max_requests" = 500;
          "catch_workers_output" = 1;
        };
      };
    };
    services.nginx = mkIf (cfg.virtualHost != null) {
      enable = true;
      virtualHosts = {
        "${cfg.virtualHost}" = {
          locations."/".extraConfig = ''
            rewrite ^ /index.php;
          '';
          locations."~ \\.php$".extraConfig = ''
            include ${config.services.nginx.package}/conf/fastcgi_params;
            fastcgi_index index.php;
            fastcgi_split_path_info ^(.+\.php)(/.+)$;
            fastcgi_pass unix:${config.services.phpfpm.pools.${cfg.pool}.socket};
            fastcgi_param SCRIPT_FILENAME ${pkg}/index.php;

            # fastcgi_split_path_info ^(.+\.php)(/.+)$;
            # fastcgi_pass unix:${config.services.phpfpm.pools.${cfg.pool}.socket};
            # fastcgi_index index.php;
            # fastcgi_param SCRIPT_FILENAME ${pkg}/index.php;
            # include ${config.services.nginx.package}/conf/fastcgi.conf;
            # include ${config.services.nginx.package}/conf/fastcgi_params;
          '';
          # locations."/" = {
          #   root = "${pkg}";
          #   index = "index.php";
          #   extraConfig = ''
          #     include ${pkgs.nginx}/conf/fastcgi_params;
          #     
          #     
          #     fastcgi_pass unix:${config.services.phpfpm.pools.${cfg.pool}.socket};
          #     fastcgi_param SCRIPT_FILENAME ${pkg}/index.php;
            


          # };
          # locations."~ ^/index.php(/|$)" = {
          #   extraConfig = ''
          #     include ${pkgs.nginx}/conf/fastcgi_params;
          #     fastcgi_index index.php;
          #     fastcgi_split_path_info ^(.+\.php)(/.+)$;
          #     fastcgi_pass unix:${config.services.phpfpm.pools.${cfg.pool}.socket};
          #     fastcgi_param SCRIPT_FILENAME ${pkg}/index.php;
          #   '';
          # };
        };
      };
    };
    services.mysql = mkIf cfg.mysql.enable {
      enable = true;
      ensureDatabases = [
        cfg.mysql.database
      ];
      ensureUsers = [
        {
          name = cfg.mysql.username;
          ensurePermissions = {
            # https://github.com/NixOS/nixpkgs/issues/83549
            "\\`${cfg.mysql.database}\\`.*" = "all privileges";
          };
        }
      ];
    };
    systemd.services.cloudlog-create-database = mkIf cfg.mysql.enable {
      description = "Set up cloudlog database";
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      wantedBy = [ "multi-user.target" ];
      after = [ "mysql.service" ];
      script = let
        mysql = "${config.services.mysql.package}/bin/mysql";
      in ''
        if [ $(echo "show tables;" | ${mysql} ${cfg.mysql.database} | grep options | wc -l) -eq 0 ]; then
           echo "Initialising Cloudlog database..."
           ${mysql} ${cfg.mysql.database} < ${cfg.package}/install/assets/install.sql
        fi
    '';
    };
    users = {
      users."${cfg.user}" = {
        isSystemUser = true;
        group = config.services.nginx.group;
      };
    };
  };
}
