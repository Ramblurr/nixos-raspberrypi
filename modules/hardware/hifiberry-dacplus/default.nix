{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.raspberry-pi.hardware.hifiberry-dacplus;
in {
  options.raspberry-pi.hardware.hifiberry-dacplus = {
    enable = lib.mkEnableOption ''
      support for the Raspberry Pi Hifiberry DAC + HAT.
    '';
  };
  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = config.raspberry-pi.hardware.platform.type != "rpizero2";
        message = "The Hifiberry DAC+ HAT is not compatible with the Raspberry Pi Zero 2.";
      }
    ];
    raspberry-pi.hardware.apply-overlays-dtmerge.enable = true;
    hardware.deviceTree = {
      overlays = [
        # Equivalent to: https://github.com/raspberrypi/linux/blob/rpi-6.1.y/arch/arm/boot/dts/overlays/hifiberry-dacplus-overlay.dts
        # but compatible changed from bcm2835 to bcm2711
        {
          name = "hifiberry-dacplus";
          dtsText = ''
            // Definitions for HiFiBerry DAC+
            /dts-v1/;
            /plugin/;

            / {
              compatible = "brcm,bcm2711";

              fragment@0 {
                target-path = "/";
                __overlay__ {
                  dacpro_osc: dacpro_osc {
                    compatible = "hifiberry,dacpro-clk";
                    #clock-cells = <0>;
                  };
                };
              };

              fragment@1 {
                target = <&i2s>;
                __overlay__ {
                  status = "okay";
                };
              };

              fragment@2 {
                target = <&i2c1>;
                __overlay__ {
                  #address-cells = <1>;
                  #size-cells = <0>;
                  status = "okay";

                  pcm5122@4d {
                    #sound-dai-cells = <0>;
                    compatible = "ti,pcm5122";
                    reg = <0x4d>;
                    clocks = <&dacpro_osc>;
                    AVDD-supply = <&vdd_3v3_reg>;
                    DVDD-supply = <&vdd_3v3_reg>;
                    CPVDD-supply = <&vdd_3v3_reg>;
                    status = "okay";
                  };
                  hpamp: hpamp@60 {
                    compatible = "ti,tpa6130a2";
                    reg = <0x60>;
                    status = "disabled";
                  };
                };
              };

              fragment@3 {
                target = <&sound>;
                hifiberry_dacplus: __overlay__ {
                  compatible = "hifiberry,hifiberry-dacplus";
                  i2s-controller = <&i2s>;
                  status = "okay";
                };
              };

              __overrides__ {
                24db_digital_gain =
                  <&hifiberry_dacplus>,"hifiberry,24db_digital_gain?";
                slave = <&hifiberry_dacplus>,"hifiberry-dacplus,slave?";
                leds_off = <&hifiberry_dacplus>,"hifiberry-dacplus,leds_off?";
              };
            };
          '';
        }
      ];
    };
  };
}
