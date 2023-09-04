{
  pkgs,
  config,
  lib,
  ...
}: {
  imports = [
    ../../modules/base
    ../../modules/hardware
  ];
  raspberry-pi.hardware.hifiberry-dacplusadc.enable = true;
  raspberry-pi.hardware.platform.type = "rpi4";
}
