{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.raspberry-pi.hardware.platform;
in {
  options.raspberry-pi.hardware.platform = {
    type = lib.mkOption {
      type = lib.types.enum ["rpi3" "rpi4" "rpizero2"];
      default = null;
      description = lib.mdDoc ''
        The Raspberry Pi Platform the build is targeting.
      '';
    };
    deviceTreeFilter = lib.mkOption {
      type = lib.types.str;
      default = null;
      description = lib.mdDoc ''
        A string to filter the device tree files by.
      '';
    };
  };
  config = {
    raspberry-pi.hardware.platform.deviceTreeFilter =
      if cfg.type == "rpi4"
      then "bcm2711-rpi-4-*.dtb"
      else if cfg.type == "rpi3"
      then "bcm*-rpi-3-*.dtb"
      else if cfg.type == "rpizero2"
      then "bcm2837-rpi-zero-2-w.dtb"
      else "";
  };
}
