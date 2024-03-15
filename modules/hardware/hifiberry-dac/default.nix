{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.raspberry-pi.hardware.hifiberry-dac;
in {
  options.raspberry-pi.hardware.hifiberry-dac = {
    enable = lib.mkEnableOption ''
      support for the Raspberry Pi Hifiberry HATs: DAC+ Light/DAC Zero/MiniAmp/Beocreate/DAC+ DSP/DAC+ RTC
    '';
  };
  config = lib.mkIf cfg.enable {
    raspberry-pi.hardware.apply-overlays-dtmerge.enable = true;
    hardware.deviceTree = {
      overlays = [
        # Equivalent to: https://github.com/raspberrypi/linux/blob/rpi-6.6.y/arch/arm/boot/dts/overlays/hifiberry-dac-overlay.dts
        #
        # changes
        # - modified top-level "compatible" field from bcm2835 to bcm2711
        # - s/i2s_clk_producer/i2s/ (name on bcm2711 platform)
        {
          name = "hifiberry-dac";
          dtsText = ''
            // Definitions for HiFiBerry DAC
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
                  pcm5102a-codec {
                    #sound-dai-cells = <0>;
                    compatible = "ti,pcm5102a";
                    status = "okay";
                  };
                };
              };

              fragment@2 {
                target = <&sound>;
                __overlay__ {
                  compatible = "hifiberry,hifiberry-dac";
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
