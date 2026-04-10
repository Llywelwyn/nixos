{
  description = "NixOS configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    guestbook.url = "git+https://git.ily.rs/lew/guestbook";
  };

  outputs = { self, nixpkgs, sops-nix, guestbook, ... }: {
    nixosConfigurations.lab = nixpkgs.lib.nixosSystem {
      system = "aarch64-linux";
      specialArgs = { inherit guestbook; };
      modules = [
        sops-nix.nixosModules.sops
        guestbook.nixosModules.default
        ./hosts/lab
      ];
    };
  };
}
