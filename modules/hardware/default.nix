{
  config,
  lib,
  pkgs,
  ...
}: {
  imports = [
    ./platform.nix
    ./kernel.nix
    ./pkgs-overlays.nix
    ./hifiberry-dacplusadc
  ];
}
