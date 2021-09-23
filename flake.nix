{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/release-21.05";
    cloudlog = {
      url = "github:magicbug/Cloudlog";
      flake = false;
    };
  };
  outputs = { self, nixpkgs, cloudlog }: let
    systems = [ "x86_64-linux" "aarch64-linux" ];
    pkgs = import nixpkgs {
      system = "x86_64-linux";
    };
    tests = {
      x86_64-linux = let
        pkgs = import nixpkgs { system = "x86_64-linux"; };
      in {
        cloudlog = pkgs.callPackage ./tests/cloudlog.nix {
          inherit self nixpkgs;
        };
      };
    };
  in rec {
    nixosModules = {
      cloudlog = {
        imports = [ ./modules/cloudlog.nix ];
        nixpkgs.overlays = [ overlay ];
      };
    };
    hydraJobs = {
      inherit packages tests;
    };
    overlay = (final: prev: {
      cloudlog = final.callPackage ./pkgs/cloudlog.nix {
        inherit cloudlog;
      };
    });
    packages = pkgs.lib.genAttrs systems (system: let
      pkgs = import nixpkgs {
        inherit system;
        overlays = [ overlay ];
      };
    in {
      inherit (pkgs) cloudlog;
    });
  };
}
