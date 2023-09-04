{
  config,
  lib,
  pkgs,
  ...
}: {
  seeed-voicecard = pkgs.callPackage ./seeed-voicecard {};
}
