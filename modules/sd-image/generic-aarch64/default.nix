{
  modulesPath,
  config,
  lib,
  pkgs,
  ...
}: {
  imports = [
    (modulesPath + "/installer/sd-card/sd-image-aarch64-installer.nix")
    ../../base
  ];
  sdImage = {
    # bzip2 compression takes loads of time with emulation, skip it. Enable this if you're low on space.
    compressImage = lib.mkDefault false;
  };
  hardware.enableRedistributableFirmware = true;
}
