{ pkgs, stdenv, cloudlog-rigctl-interface, ... }:
stdenv.mkDerivation rec {
  name = "cloudlog-rigctl-interface";
  version = "master";
  src = cloudlog-rigctl-interface;
  installPhase = ''
    # Rewrite config to use env
    substitute config.php config.php \
        --replace '"127.0.0.1"' '$_ENV["RIGCTL_HOST"]' \
        --replace '4532' '$_ENV["RIGCTL_PORT"]' \
        --replace '"https://log.tbspace.de"' '$_ENV["CLOUDLOG_URL"]' \
        --replace '"p1fgZhGPbWMRaD4Iz5xm"' 'trim(file_get_contents($_ENV["CLOUDLOG_KEY"]))' \
        --replace '"FT-991a"' '$_ENV["RADIO_NAME"]'
    mkdir $out
    cp -R ./* $out
  '';
}
