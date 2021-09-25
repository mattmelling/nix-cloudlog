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
    cloudlog-adifwatch = {
      url = "github:illdefined/cloudlog-adifwatch?ref=07acf5989dd2bebaea41574bd67a467982d3f851";
      flake = false;
    };
  };
  outputs = { self, nixpkgs, cloudlog, cloudlog-rigctl-interface, cloudlog-adifwatch }: let
    systems = [ "x86_64-linux" "aarch64-linux" ];
    pkgs = import nixpkgs {
      system = "x86_64-linux";
    };
  in {
    checks = {
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
        cloudlog-adifwatch = pkgs.callPackage ./tests/cloudlog-adifwatch.nix {
          inherit self nixpkgs;
        };
      };
    };
    nixosModules = rec {
      all = {
        imports = [
          cloudlog
          cloudlog-lotwsync
          cloudlog-rigctl-interface
          cloudlog-lotwsync
          cloudlog-adifwatch
        ];
        nixpkgs.overlays = [ self.overlay ];
      };
      cloudlog = {
        imports = [
          ./modules/cloudlog.nix
          ./modules/cloudlog-lotwsync.nix
          ./modules/cloudlog-rigctl-interface.nix
          ./modules/cloudlog-adifwatch.nix
        ];
        nixpkgs.overlays = [ self.overlay ];
      };
    };
    hydraJobs = {
      inherit (self) packages checks;
    };
    overlay = (final: prev: {
      cloudlog = final.callPackage ./pkgs/cloudlog.nix {
        inherit cloudlog;
      };
      cloudlog-rigctl-interface = final.callPackage ./pkgs/cloudlog-rigctl-interface.nix {
        inherit cloudlog-rigctl-interface;
      };
      cloudlog-adifwatch = final.callPackage ./pkgs/cloudlog-adifwatch {
        inherit cloudlog-adifwatch;
      };
    });
    packages = pkgs.lib.genAttrs systems (system: let
      pkgs = import nixpkgs {
        inherit system;
        overlays = [ self.overlay ];
      };
    in {
      inherit (pkgs)
        cloudlog
        cloudlog-rigctl-interface
        cloudlog-adifwatch;
    });
  };
}
