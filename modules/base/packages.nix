{
  flake.modules.nixos.base = { pkgs, ... }: {
    environment.systemPackages = with pkgs; [
      neovim
      git
      sops
      just
      htop
    ];
  };
}
