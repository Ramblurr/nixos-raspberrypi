{modulesPath, ...}: {
  imports = [
    ../generic-aarch64
  ];
  raspberry-pi.hardware.platform.type = "rpi3";
}
