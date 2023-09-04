# This module extends the official sd-image.nix with the following:
# - ability to add a swap partition to the built image
# - ability to add options to the config.txt firmware
# - fix the uboot bug with pi zero 2
# Related issue: https://github.com/NixOS/nixpkgs/issues/216886
# Original file: https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/installer/sd-card/sd-image.nix
{
  nixpkgs,
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  rootfsImage = pkgs.callPackage "${pkgs.path}/nixos/lib/make-ext4-fs.nix" ({
      inherit (config.sdImage) storePaths;
      compressImage = config.sdImage.compressImage;
      populateImageCommands = config.sdImage.populateRootCommands;
      volumeLabel = "NIXOS_SD";
    }
    // optionalAttrs (config.sdImage.rootPartitionUUID != null) {
      uuid = config.sdImage.rootPartitionUUID;
    });
in {
  options.sdImage = {
    swap = {
      enable = mkEnableOption "Create a swap partition.";
      partitionName = mkOption {
        type = types.str;
        default = "SWAP";
        description = lib.mdDoc ''
          Name of the partition which holds the swap.
        '';
      };
      size = mkOption {
        type = types.int;
        default = 2 * 1024;
        description = lib.mdDoc ''
          Size of the swap partition, in megabytes.
        '';
      };
    };

    extraFirmwareConfig = mkOption {
      type = types.attrs;
      default = {};
      description = lib.mdDoc ''
        Extra configuration to be added to config.txt.
      '';
    };
  };

  config = {
    # Override of the sd image build to optionally add a swap partition
    system.build.sdImage = lib.mkForce (pkgs.callPackage
      ({
        stdenv,
        dosfstools,
        e2fsprogs,
        mtools,
        libfaketime,
        util-linux,
        zstd,
      }:
        stdenv.mkDerivation {
          name = config.sdImage.imageName;

          nativeBuildInputs =
            [dosfstools e2fsprogs libfaketime mtools util-linux]
            ++ lib.optional config.sdImage.compressImage zstd;

          inherit (config.sdImage) imageName compressImage;

          buildCommand = ''
            mkdir -p $out/nix-support $out/sd-image
            export img=$out/sd-image/${config.sdImage.imageName}

            echo "${pkgs.stdenv.buildPlatform.system}" > $out/nix-support/system
            if test -n "$compressImage"; then
              echo "file sd-image $img.zst" >> $out/nix-support/hydra-build-products
            else
              echo "file sd-image $img" >> $out/nix-support/hydra-build-products
            fi

            root_fs=${rootfsImage}
            ${lib.optionalString config.sdImage.compressImage ''
              root_fs=./root-fs.img
              echo "Decompressing rootfs image"
              zstd -d --no-progress "${rootfsImage}" -o $root_fs
            ''}

            # Set swap size. Set it to 0 it swap is disabled.
            swapSize=${toString (
              if config.sdImage.swap.enable
              then config.sdImage.swap.size
              else 0
            )}
            # The root partition is #2 if there is no swap, but is #3 is there is one
            rootPartitionNumber=${toString (
              if config.sdImage.swap.enable
              then 3
              else 2
            )}

            # Gap in front of the first partition, in MiB
            gap=${toString config.sdImage.firmwarePartitionOffset}

            # Create the image file sized to fit /boot/firmware and /, plus slack for the gap.
            rootSizeBlocks=$(du -B 512 --apparent-size $root_fs | awk '{ print $1 }')
            firmwareSizeBlocks=$((${toString config.sdImage.firmwareSize} * 1024 * 1024 / 512))
            # Note: swap size is 0 if swap is disabled
            imageSize=$((rootSizeBlocks * 512 + firmwareSizeBlocks * 512 + gap * 1024 * 1024 + swapSize * 1024 * 1024))
            truncate -s $imageSize $img

            # type=b is 'W95 FAT32', type=82 is 'Linux swap / Solaris', type=83 is 'Linux'.
            # The "bootable" partition is where u-boot will look file for the bootloader
            # information (dtbs, extlinux.conf file).

            sfdisk $img <<EOF
                label: dos
                label-id: ${config.sdImage.firmwarePartitionID}

                start=''${gap}M, size=$firmwareSizeBlocks, type=b
                ${lib.optionalString config.sdImage.swap.enable ''
              start=$((gap + ${toString config.sdImage.firmwareSize}))M, size=''${swapSize}M, type=82
            ''}
                start=$((gap + ${toString config.sdImage.firmwareSize} + swapSize))M, type=83, bootable
            EOF
            # Copy the rootfs into the SD image
            eval $(partx $img -o START,SECTORS --nr $rootPartitionNumber --pairs)
            dd conv=notrunc if=$root_fs of=$img seek=$START count=$SECTORS

            # * Create the swap if it is enabled
            ${lib.optionalString config.sdImage.swap.enable ''
              # Create the swap
              eval $(partx $img -o START,SECTORS --nr 2 --pairs)
              dd if=/dev/zero of=swap.img bs=''${swapSize}M count=1
              mkswap -L "${config.sdImage.swap.partitionName}" swap.img
              dd conv=notrunc if=swap.img of=$img seek=$START count=$SECTORS
            ''}

            # Create a FAT32 /boot/firmware partition of suitable size into firmware_part.img
            eval $(partx $img -o START,SECTORS --nr 1 --pairs)
            truncate -s $((SECTORS * 512)) firmware_part.img

            mkfs.vfat --invariant -i ${config.sdImage.firmwarePartitionID} -n ${config.sdImage.firmwarePartitionName} firmware_part.img

            # Populate the files intended for /boot/firmware
            mkdir firmware
            ${config.sdImage.populateFirmwareCommands}

            find firmware -exec touch --date=2000-01-01 {} +
            # Copy the populated /boot/firmware into the SD image
            cd firmware
            # Force a fixed order in mcopy for better determinism, and avoid file globbing
            for d in $(find . -type d -mindepth 1 | sort); do
              faketime "2000-01-01 00:00:00" mmd -i ../firmware_part.img "::/$d"
            done
            for f in $(find . -type f | sort); do
              mcopy -pvm -i ../firmware_part.img "$f" "::/$f"
            done
            cd ..

            # Verify the FAT partition before copying it.
            fsck.vfat -vn firmware_part.img
            dd conv=notrunc if=firmware_part.img of=$img seek=$START count=$SECTORS

            ${config.sdImage.postBuildCommands}

            if test -n "$compressImage"; then
                zstd -T$NIX_BUILD_CORES --rm $img
            fi
          '';
        })
      {});

    swapDevices = lib.mkIf config.sdImage.swap.enable [
      {
        device = "/dev/disk/by-label/${config.sdImage.swap.partitionName}";
      }
    ];

    sdImage.populateFirmwareCommands =
      lib.mkIf ((lib.length (lib.attrValues config.sdImage.extraFirmwareConfig)) > 0)
      (
        let
          # Convert the set into a string of lines of "key=value" pairs.
          keyValueMap = name: value: name + "=" + toString value;
          keyValueList = lib.mapAttrsToList keyValueMap config.sdImage.extraFirmwareConfig;
          extraFirmwareConfigString = lib.concatStringsSep "\n" keyValueList;
        in
          lib.mkAfter
          ''
            config=firmware/config.txt
            # The initial file has just been created without write permissions. Add them to be able to append the file.
            chmod u+w $config
            echo "\n# Extra configuration" >> $config
            echo "${extraFirmwareConfigString}" >> $config
            chmod u-w $config
          ''
      );

    # Ugly hack to make it work with Pi Zero W
    sdImage.populateRootCommands = lib.mkForce ''
      mkdir -p ./files/boot
      ${config.boot.loader.generic-extlinux-compatible.populateCmd} -c ${config.system.build.toplevel} -d ./files/boot
      DTBS_DIR=$(ls -d ./files/boot/nixos/*-dtbs)/broadcom
      chmod u+w $DTBS_DIR
      cp ${config.system.build.toplevel}/dtbs/broadcom/bcm2835-rpi-zero-w.dtb $DTBS_DIR/bcm2835-rpi-zero-w.dtb
      chmod u-w $DTBS_DIR
    '';
  };
}
