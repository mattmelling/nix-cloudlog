{ rustPlatform, cloudlog-adifwatch }:
rustPlatform.buildRustPackage {
  pname = "cloudlog-adifwatch";
  version = "9563e79";
  src = cloudlog-adifwatch;
  cargoPatches = [
    ./cargo-lock.patch
    ./path.patch
  ];
  cargoSha256 = "sha256-5PedW6Fhdc+qYfnbzkqwWvTogeoFf76QENxjX+JBWew=";
}
