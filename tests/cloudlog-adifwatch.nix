{ nixpkgs, pkgs, self, ... }:
let
  test = import (nixpkgs + "/nixos/lib/testing-python.nix") {
    system = "x86_64-linux";
  };
in test.simpleTest {
  name = "cloudlog-adifwatch";
  machine = { ... }: {
    imports = [
      self.nixosModules.cloudlog-adifwatch
    ];
    services = {
      cloudlog-adifwatch = {
        enable = true;
        watchers = {
          wsjtx = "/etc/adif";
        };
        key = "/etc/cloudlog";
        host = "http://localhost/cloudlog";
      };
    };

    # Create some stub files to satisfy the service
    environment.etc.cloudlog.text = "key";
    environment.etc.adif.text = "";
  };
  testScript = ''
    machine.wait_for_unit('cloudlog-adifwatch-wsjtx.service')
  '';
}
