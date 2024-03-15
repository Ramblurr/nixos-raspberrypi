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
    ./audio.nix
    ./hifiberry-dac
    ./hifiberry-dacplusadc
    ./hifiberry-dacplusdsp
    ./hifiberry-dacplus
    ./respeaker-8mic
    ./respeaker-4mic
    ./respeaker-2mic
    ./spi0-1cs.nix
  ];
}
