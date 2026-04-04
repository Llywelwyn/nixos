{
  description = "NixOS configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, sops-nix, ... }: {
    nixosConfigurations.lab = nixpkgs.lib.nixosSystem {
      system = "aarch64-linux";
      modules = [
        sops-nix.nixosModules.sops
        ./hosts/lab
      ];
    };
  };
}
