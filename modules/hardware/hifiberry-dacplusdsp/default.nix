{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.raspberry-pi.hardware.hifiberry-dacplusdsp;
in {
  options.raspberry-pi.hardware.hifiberry-dacplusdsp = {
    enable = lib.mkEnableOption ''
      support for the Raspberry Pi Hifiberry DAC + DSP HAT.
    '';
  };
  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = config.raspberry-pi.hardware.platform.type != "rpizero2";
        message = "The Hifiberry DAC+ DSP HAT is not compatible with the Raspberry Pi Zero 2.";
      }
    ];
    raspberry-pi.hardware.apply-overlays-dtmerge.enable = true;
    hardware.deviceTree = {
      overlays = [
        # Equivalent to: https://github.com/raspberrypi/linux/blob/rpi-6.1.y/arch/arm/boot/dts/overlays/hifiberry-dacplusdsp-overlay.dts
        # but compatible changed from bcm2835 to bcm2711
        {
          name = "hifiberry-dacplusdsp";
          dtsText = ''
            // Definitions for hifiberry DAC+DSP soundcard overlay
            /dts-v1/;
            /plugin/;

            / {
              compatible = "brcm,bcm2711";

              fragment@0 {
                target = <&i2s>;
                __overlay__ {
                  status = "okay";
                };
              };

              fragment@1 {
                target-path = "/";
                __overlay__ {
                  dacplusdsp-codec {
                    #sound-dai-cells = <0>;
                    compatible = "hifiberry,dacplusdsp";
                    status = "okay";
                  };
                };
              };

              fragment@2 {
                target = <&sound>;
                __overlay__ {
                  compatible = "hifiberrydacplusdsp,hifiberrydacplusdsp-soundcard";
                  i2s-controller = <&i2s>;
                  status = "okay";
                };
              };
            };
          '';
        }
      ];
    };
  };
}
