{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.raspberry-pi.hardware.hifiberry-dacplusadc;
in {
  options.raspberry-pi.hardware.hifiberry-dacplusadc = {
    enable = lib.mkEnableOption ''
      support for the Raspberry Pi Hifiberry DAC + ADC HAT.
    '';
  };
  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = config.raspberry-pi.hardware.platform.type != "rpizero2";
        message = "The Hifiberry DAC+ ADC HAT is not compatible with the Raspberry Pi Zero 2.";
      }
    ];
    raspberry-pi.hardware.apply-overlays-dtmerge.enable = true;
    hardware.deviceTree = {
      overlays = [
        # Equivalent to: https://github.com/raspberrypi/linux/blob/rpi-6.1.y/arch/arm/boot/dts/overlays/hifiberry-dacplusadc-overlay.dts
        {
          name = "hifiberry-dacplusadc";
          dtsText = ''
            // Definitions for HiFiBerry DAC+ADC
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

                  pcm_codec: pcm5122@4d {
                    #sound-dai-cells = <0>;
                    compatible = "ti,pcm5122";
                    reg = <0x4d>;
                    clocks = <&dacpro_osc>;
                    AVDD-supply = <&vdd_3v3_reg>;
                    DVDD-supply = <&vdd_3v3_reg>;
                    CPVDD-supply = <&vdd_3v3_reg>;
                    status = "okay";
                  };
                };
              };

              fragment@3 {
                target-path = "/";
                __overlay__ {
                  dmic {
                    #sound-dai-cells = <0>;
                    compatible = "dmic-codec";
                    num-channels = <2>;
                    status = "okay";
                  };
                };
              };

              fragment@4 {
                target = <&sound>;
                hifiberry_dacplusadc: __overlay__ {
                  compatible = "hifiberry,hifiberry-dacplusadc";
                  i2s-controller = <&i2s>;
                  status = "okay";
                };
              };

              __overrides__ {
                24db_digital_gain =
                  <&hifiberry_dacplusadc>,"hifiberry,24db_digital_gain?";
                slave = <&hifiberry_dacplusadc>,"hifiberry-dacplusadc,slave?";
                leds_off = <&hifiberry_dacplusadc>,"hifiberry-dacplusadc,leds_off?";
              };
            };
          '';
        }
      ];
    };
  };
}
