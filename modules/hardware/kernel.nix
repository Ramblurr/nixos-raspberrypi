{
  config,
  lib,
  pkgs,
  ...
}: let
  platformType = config.raspberry-pi.hardware.platform.type;
in {
  boot.kernelPackages =
    if platformType == "rpi3"
    then lib.mkForce pkgs.linuxPackages_rpi3
    else if platformType == "rpi4"
    then lib.mkForce pkgs.linuxPackages_rpi4
    else if platformType == "rpizero2"
    then lib.mkForce pkgs.linuxPackages
    else pkgs.linuxPackages_latest;
}
