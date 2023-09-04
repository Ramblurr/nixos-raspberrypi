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
  raspberry-pi.hardware.platform.type = "rpizero2";
  #raspberry-pi.hardware.hifiberry-dacplusadc.enable = true;
  #raspberry-pi.hardware.respeaker-8mic.enable = true;
  #raspberry-pi.hardware.respeaker-4mic.enable = true;
  #raspberry-pi.hardware.respeaker-2mic.enable = true;
}
