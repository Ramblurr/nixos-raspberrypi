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
  raspberry-pi.hardware.platform.type = "rpi4";
  # Also increase the amount of CMA to ensure the virtual console on the RPi4 works.
  boot.kernelParams = ["cma=128M" "console=tty0"];
  raspberry-pi.hardware.hifiberry-dacplusadc.enable = true;
  raspberry-pi.hardware.respeaker-8mic.enable = true;
  raspberry-pi.hardware.respeaker-4mic.enable = true;
  raspberry-pi.hardware.respeaker-2mic.enable = true;
}
