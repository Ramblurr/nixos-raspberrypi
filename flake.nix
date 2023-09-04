{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixos-hardware.url = "github:nixos/nixos-hardware";
  };
  outputs = {
    self,
    nixpkgs,
    nixos-hardware,
  }: {
    nixosModules = {
      sd-image-rpizero2 = import ./modules/sd-image/rpizero2;
      sd-image-rpi3 = import ./modules/sd-image/rpi3;
      sd-image-rpi4 = import ./modules/sd-image/rpi4;
    };
    images = {
      rpi4 =
        (self.nixosConfigurations.rpi4.extendModules {
          modules = [./modules/sd-image/rpi4];
        })
        .config
        .system
        .build
        .sdImage;
      rpi3 =
        (self.nixosConfigurations.rpi3.extendModules {
          modules = [./modules/sd-image/rpi3];
        })
        .config
        .system
        .build
        .sdImage;
      rpizero2 =
        (self.nixosConfigurations.rpizero2.extendModules {
          modules = [./modules/sd-image/rpizero2];
        })
        .config
        .system
        .build
        .sdImage;
    };
    nixosConfigurations = {
      rpi4 = nixpkgs.lib.nixosSystem {
        system = "aarch64-linux";
        modules = [
          nixos-hardware.nixosModules.raspberry-pi-4
          ./hardware/rpi4
        ];
      };
      rpi3 = nixpkgs.lib.nixosSystem {
        system = "aarch64-linux";
        modules = [
          ./hardware/rpi3
        ];
      };
      rpizero2 = nixpkgs.lib.nixosSystem {
        system = "aarch64-linux";
        modules = [
          ./hardware/rpizero2
        ];
      };
    };
  };
}
