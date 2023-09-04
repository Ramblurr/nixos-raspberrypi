{
  pkgs,
  config,
  lib,
  ...
}: {
  imports = [
    ../../modules/base
  ];
  # Also increase the amount of CMA to ensure the virtual console on the RPi3 works.
  boot.kernelParams = ["cma=32M" "console=tty0"];
}
