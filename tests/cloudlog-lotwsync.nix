{ nixpkgs, pkgs, self, ... }:
let
  test = import (nixpkgs + "/nixos/lib/testing-python.nix") {
    system = "x86_64-linux";
  };
in test.simpleTest {
  name = "cloudlog-lotwsync";
  machine = { ... }: {
    imports = [
      self.nixosModules.cloudlog-lotwsync
    ];
    services = {
      cloudlog-lotwsync = {
        enable = true;
        url = "http://localhost/cloudlog";
      };
    };
  };
  testScript = ''
    machine.wait_for_unit('cloudlog-lotwsync.timer')
  '';
}
