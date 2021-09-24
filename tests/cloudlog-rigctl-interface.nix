{ nixpkgs, pkgs, self, ... }:
let
  test = import (nixpkgs + "/nixos/lib/testing-python.nix") {
    system = "x86_64-linux";
  };
in test.simpleTest {
  name = "cloudlog-lotwsync";
  machine = { ... }: {
    imports = [
      self.nixosModules.cloudlog
    ];
    services = {
      cloudlog-rigctl-interface = {
        enable = true;
        cloudlog = {
          url = "http://localhost/cloudlog";
          key = "/tmp/cloudlog";
        };
      };
    };
  };
  testScript = ''
    machine.wait_for_unit('cloudlog-rigctl-interface.service')
  '';
}
