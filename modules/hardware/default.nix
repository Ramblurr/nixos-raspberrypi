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
    ./respeaker-8mic
    ./respeaker-4mic
    ./respeaker-2mic
  ];
}
