# NixOS on the Raspberry PI

[![MIT Licensed](https://img.shields.io/github/license/ramblurr/nixos-raspberrypi)](./LICENSE)

> A NixOS Flake providing bare bones (but ready to go!) configurations for Raspberry Pi devices.

* Build sd-card images with your own configuration
* Easily pull in fixes for various Raspberry Pi hardware variations and HATs


## Supported Hardware

See the table below for a list of supported and unsupported hardware

| Board                 | Arch    | Supported |
|-----------------------|---------|-----------|
| Raspberry Pi 4        | aarch64 | Yes       |
| Raspberry Pi 3        | aarch64 | Yes       |
| Raspberry Pi Zero W 2 | aarch64 | Yes       |
| Raspberry Pi 2        | armv7   | No        |
| Raspberry Pi 1        | armv6   | No        |
| Raspberry Pi Zero W   | armv6   | No        |

As you can tell only aarch64 is supported, this is because Nix provides public caches for this architecture.

In theory it should be possible to build for non-aarch64 hardware, but there are
no publicly available caches and the author hasn't yet tried to build them
(though I do have several RPI 1s and RPI0W1s lying around...).

[Read more about ARM on NixOS.](https://nixos.wiki/wiki/NixOS_on_ARM#Binary_cache)


## Workaround and other Shenanigans

This repo provides workarounds for the following issues:

- [Aarch64 SD images missing pi-zero-2.dtb file require to boot](https://github.com/NixOS/nixpkgs/issues/216886)
- [modprobe: FATAL: Module sun4i-drm not found in directory](https://github.com/NixOS/nixpkgs/issues/154163)
- [Raspberry Pi device tree overlays do not apply on 21.05 (or later)](https://github.com/NixOS/nixpkgs/issues/125354)

## Prerequisites

* You are already running NixOS on your build machine

If your build-machine isn't aarch64-linux, then you will need to add the
following to your build machine's NixOS configuration to emulate aarch64 (arm64)
so you can cross-build.

```nix
{
  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];
}
```

## Example Usage

Using this flake you can create Raspberry PI SD card images with your own configuration.

<details>
  <summary>Example flake.nix (click me)</summary>

```nix
# flake.nix
{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixos-raspberrypi.url = "github:ramblurr/nixos-raspberrypi";
  };
  outputs = {
    self,
    nixpkgs,
    nixos-raspberrypi,
  }: {
    images = {
      rpi4 =
        (nixos-raspberrypi.nixosConfigurations.rpi4.extendModules {
          modules = [
            nixos-raspberrypi.nixosModules.sd-image-rpi4
            ./configuration.nix # <--- put your configuration here, see below for an example
          ];
        })
        .config
        .system
        .build
        .sdImage;
    };
  };
}

```
</details>

<details>
  <summary>Example configuration.nix (click me)</summary>


```nix
# configuration.nix
{ pkgs, config, lib, ... }:
{
  system.stateVersion = "23.11";
  environment.systemPackages = with pkgs; [ vim git ];
  services.openssh.enable = true;
  networking.hostName = "pi";
  users = {
    users.YOUR_USERNAME = {
      password = "YOUR_PASSWORD";
      isNormalUser = true;
      extraGroups = [ "wheel" ];
    };
  };
  networking = {
    interfaces."wlan0".useDHCP = true;
    wireless = {
      interfaces = [ "wlan0" ];
      enable = true;
      networks = {
        "YOUR_WIFI_SSID".psk = "YOUR_WIFI_PASSWORD";
      };
    };
  };
}
```

</details>

Then run `nix build .#images.rpi4`. After a while your sd-image will appear in `result/sd-image/nixos-sd-image*.img`

Some things to keep in mind for your config:

* Don't forget to add a `system.stateVersion` do your configuration.
* If you have a wifi only pi (e.g., Raspberry Pi Zero W 2), don't forget to configure the wireless network.

## List of Options

| Module                                                      | Purpose                                   |
|-------------------------------------------------------------|-------------------------------------------|
| `raspberry-pi.hardware.hifiberry-dacplusadc.enable = true;` | Enable support for the Hifiberry DAC+ ADC |

# License

Copyright (c) 2023 Casey Link. This flake is made available under the [MIT License](./LICENSE) (just like NixOS).
