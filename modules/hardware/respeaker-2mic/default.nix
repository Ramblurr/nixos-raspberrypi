{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.raspberry-pi.hardware.respeaker-2mic;
  seeed-voicecard = pkgs.callPackage ../../../packages/seeed-voicecard {kernel = config.boot.kernelPackages.kernel;};
in {
  options.raspberry-pi.hardware.respeaker-2mic = {
    enable = lib.mkEnableOption ''
      support for the Seeed Studio ReSpeaker 2-Mic Array for Raspberry Pi
    '';
  };
  config = lib.mkIf cfg.enable {
    raspberry-pi.hardware.apply-overlays-dtmerge.enable = true;
    hardware.deviceTree = {
      enable = true;
      overlays = [
        {
          name = "respeaker-2mic";
          dtsFile = "${seeed-voicecard}/lib/dts/seeed-2mic-voicecard-overlay.dts";
        }
        {
          name = "spi";
          dtsText = ''
            /dts-v1/;
            /plugin/;

            / {
              compatible = "raspberrypi";
              fragment@0 {
                target = <&spi>;
                __overlay__ {
                  cs-gpios = <&gpio 8 1>, <&gpio 7 1>;
                  status = "okay";
                  pinctrl-names = "default";
                  pinctrl-0 = <&spi0_pins &spi0_cs_pins>;
                  #address-cells = <1>;
                  #size-cells = <0>;
                  spidev@0 {
                    reg = <0>;  // CE0
                    spi-max-frequency = <500000>;
                    compatible = "spidev";
                  };

                  spidev@1 {
                    reg = <1>;  // CE1
                    spi-max-frequency = <500000>;
                    compatible = "spidev";
                  };
                };
              };
                    fragment@1 {
                target = <&alt0>;
                __overlay__ {
                  // Drop GPIO 7, SPI 8-11
                  brcm,pins = <4 5>;
                };
              };

              fragment@2 {
                target = <&gpio>;
                __overlay__ {
                  spi0_pins: spi0_pins {
                    brcm,pins = <9 10 11>;
                    brcm,function = <4>; // alt0
                  };
                  spi0_cs_pins: spi0_cs_pins {
                    brcm,pins = <8 7>;
                    brcm,function = <1>; // out
                  };
                };
              };
            };
          '';
        }
      ];
    };
  };
}
