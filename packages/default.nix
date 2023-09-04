{pkgs}:
pkgs.lib.makeScope pkgs.newScope (self: let
  callPackage = self.callPackage;
in {
  seeed-voicecard = callPackage ./seeed-voicecard {};
})
