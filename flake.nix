{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/release-21.05";
    cloudlog = {
      url = "github:magicbug/Cloudlog";
      flake = false;
    };
    cloudlog-rigctl-interface = {
      url = "github:Manawyrm/cloudlog-rigctl-interface";
      flake = false;
    };
  };
  outputs = { self, nixpkgs, cloudlog, cloudlog-rigctl-interface }: let
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
        cloudlog-lotwsync = pkgs.callPackage ./tests/cloudlog-lotwsync.nix {
          inherit self nixpkgs;
        };
        cloudlog-rigctl-interface = pkgs.callPackage ./tests/cloudlog-rigctl-interface.nix {
          inherit self nixpkgs;
        };
      };
    };
  in rec {
    nixosModules = {
      cloudlog = {
        imports = [
          ./modules/cloudlog.nix
          ./modules/cloudlog-lotwsync.nix
          ./modules/cloudlog-rigctl-interface.nix
        ];
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
      cloudlog-rigctl-interface = final.callPackage ./pkgs/cloudlog-rigctl-interface.nix {
        inherit cloudlog-rigctl-interface;
      };
    });
    packages = pkgs.lib.genAttrs systems (system: let
      pkgs = import nixpkgs {
        inherit system;
        overlays = [ overlay ];
      };
    in {
      inherit (pkgs)
        cloudlog
        cloudlog-rigctl-interface;
    });
  };
}
