{
  flake.modules.homeManager.desktop = { pkgs, ... }: {
    programs.zoxide.enable = true;

    home.packages = with pkgs; [
      bat
      eza
      fastfetch
      fd
      ffmpeg
      gh
      glow
      jq
      python3
      ripgrep
      zola
    ];
  };
}
