{ nixpkgs, pkgs, self, ... }:
let
  test = import (nixpkgs + "/nixos/lib/testing-python.nix") {
    system = "x86_64-linux";
  };
in test.simpleTest {
  name = "cloudlog";
  machine = { ... }: {
    imports = [
      self.nixosModules.cloudlog
    ];
    services = {
      cloudlog = {
        enable = true;
        virtualHost = "localhost";
        mysql = {
          enable = true;
          database = "cloudlog_db";
        };
      };
      mysql = {
        enable = true;
        package = pkgs.mariadb;
      };
    };
  };
  testScript = ''
    machine.wait_for_unit('mysql.service')
    machine.wait_for_unit('nginx.service')
    machine.wait_for_unit('phpfpm-cloudlog.service')
    machine.wait_for_unit('cloudlog-create-database.service')

    # ensure db is created with name defined in configuration
    machine.succeed("echo 'use cloudlog_db;' | sudo -u cloudlog mysql")

    # ensure the web application is running
    machine.succeed("curl -s localhost | grep '<title>Dashboard - Cloudlog</title>'")
  '';
}
