{ pkgs, config, lib, ... }:
{
  imports = [
    ../../modules/base
  ];
  boot.kernelParams = [ "cma=32M" ];
}
