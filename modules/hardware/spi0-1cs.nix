{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.raspberry-pi.hardware.spi0-1cs;
in {
  options.raspberry-pi.hardware.spi0-1cs = {
    enable =
      lib.mkEnableOption ''
      '';
  };
  config = lib.mkIf cfg.enable {
    raspberry-pi.hardware.apply-overlays-dtmerge.enable = true;
    hardware.deviceTree = {
      overlays = [
        # Equivalent to: https://github.com/raspberrypi/linux/blob/rpi-6.6.y/arch/arm/boot/dts/overlays/spi0-1cs-overlay.dts
        {
          name = "spi0-1cs-overlay";
          dtsText = ''
            /dts-v1/;
            /plugin/;


            / {
                compatible = "brcm,bcm2835";

                fragment@0 {
                    target = <&spi0_cs_pins>;
                    frag0: __overlay__ {
                        brcm,pins = <8>;
                    };
                };

                fragment@1 {
                    target = <&spi0>;
                    frag1: __overlay__ {
                        cs-gpios = <&gpio 8 1>;
                        status = "okay";
                    };
                };

                fragment@2 {
                    target = <&spidev1>;
                    __overlay__ {
                        status = "disabled";
                    };
                };

                fragment@3 {
                    target = <&spi0_pins>;
                    __dormant__ {
                        brcm,pins = <10 11>;
                    };
                };

                __overrides__ {
                    cs0_pin  = <&frag0>,"brcm,pins:0",
                           <&frag1>,"cs-gpios:4";
                    no_miso = <0>,"=3";
                };
            };
          '';
        }
      ];
    };
  };
}
