{ stdenv, cloudlog, ... }:
stdenv.mkDerivation {
  name = "Cloudlog";
  version = "master";
  src = cloudlog;
  installPhase = ''
    mkdir $out/
    cp -R ./* $out
  '';
}
