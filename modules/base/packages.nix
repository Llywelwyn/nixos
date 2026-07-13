{
  flake.modules.nixos.base = { pkgs, ... }: {
    programs.neovim = {
      enable = true;
      defaultEditor = true;
    };

    environment.systemPackages = with pkgs; [
      git
      sops
      just
      htop
      nvd
    ];
  };
}
