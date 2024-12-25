{ config
, lib
, pkgs
, ...
}:
let
  platformType = config.raspberry-pi.hardware.platform.type;
in
{
  imports = [
    ../hardware/platform.nix
  ];

  # "${nixpkgs}/nixos/modules/installer/sd-card/sd-image-aarch64.nix" creates a
  # disk with this label on first boot. Therefore, we need to keep it. It is the
  # only information from the installer image that we need to keep persistent
  fileSystems."/" = {
    device = "/dev/disk/by-label/NIXOS_SD";
    fsType = "ext4";
  };
  boot = {
    tmp.useTmpfs = true;
    loader = {
      generic-extlinux-compatible.enable = lib.mkDefault true;
      grub.enable = lib.mkDefault false;
    };

    initrd.availableKernelModules = [
      "usbhid"
      "usb_storage"
      "vc4"
      "pcie_brcmstb" # required for the pcie bus to work
      "reset-raspberrypi" # required for vl805 firmware to load
    ];

    kernelParams =
      #["console=tty0"]
      [ ]
      ++ (
        if platformType == "rpi3"
        then [ "cma=32M" ]
        else if platformType == "rpi4"
        then [ "cma=128M" ]
        else [ ]
      );
  };
  nix.settings = {
    experimental-features = lib.mkDefault "nix-command flakes";
    trusted-users = [ "root" "@wheel" ];
  };
  hardware.enableRedistributableFirmware = true;
  services.timesyncd.enable = lib.mkDefault true;
  networking = {
    useDHCP = lib.mkDefault true;
    interfaces.eth0.useDHCP = lib.mkDefault true;
    hostName = lib.mkDefault platformType;
  };

  # Source: https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/installer/sd-card/sd-image-aarch64-new-kernel-no-zfs-installer.nix
  # Makes `availableOn` fail for zfs, see <nixos/modules/profiles/base.nix>.
  # This is a workaround since we cannot remove the `"zfs"` string from `supportedFilesystems`.
  # The proper fix would be to make `supportedFilesystems` an attrset with true/false which we
  # could then `lib.mkForce false`
  nixpkgs.overlays = [
    (final: super: {
      zfs = super.zfs.overrideAttrs (_: {
        meta.platforms = [ ];
      });
    })

    # Workaround: https://github.com/NixOS/nixpkgs/issues/154163
    # modprobe: FATAL: Module sun4i-drm not found in directory
    (final: super: {
      makeModulesClosure = x:
        super.makeModulesClosure (x // { allowMissing = true; });
    })
  ];

  # Trim some fat
  # Limit the journal size to X MB or last Y days of logs
  services.journald.extraConfig = ''
    SystemMaxUse=1536M
    MaxFileSec=60day
  '';
  services.fwupd.enable = false;
  services.udisks2.enable = false;
  programs.command-not-found.enable = false;
  boot.enableContainers = false;
}
