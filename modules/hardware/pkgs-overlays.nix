# source: https://github.com/NixOS/nixos-hardware/blob/master/raspberry-pi/4/pkgs-overlays.nix
# License: Creative Commons Zero v1.0 Universal
{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.raspberry-pi.hardware.apply-overlays-dtmerge;
  dt_ao_overlay = _final: prev: {
    deviceTree.applyOverlays = prev.callPackage ./apply-overlays-dtmerge.nix {};
  };
in {
  options.raspberry-pi.hardware.apply-overlays-dtmerge = {
    enable = lib.mkEnableOption ''
      replace deviceTree.applyOverlays implementation to use dtmerge from libraspberrypi.
      this can resolve issues with applying dtbs for the pi.
    '';
  };

  config = lib.mkIf cfg.enable {
    nixpkgs.overlays = [dt_ao_overlay];
    hardware = {
      firmware = [pkgs.wireless-regdb];
      i2c.enable = true;
      deviceTree = {
        enable = true;
        filter = config.raspberry-pi.hardware.platform.deviceTreeFilter;
      };
    };
  };
}
