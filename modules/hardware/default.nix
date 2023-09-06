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
    ./hifiberry-dacplusdsp
    ./hifiberry-dacplus
    ./respeaker-8mic
    ./respeaker-4mic
    ./respeaker-2mic
  ];
}
