{
  flake.modules.homeManager.desktop = { pkgs, ... }: {
    programs.zoxide.enable = true;

    home.packages = with pkgs; [
      bat
      dotnet-sdk
      eza
      fastfetch
      fd
      ffmpeg
      fzf
      gh
      glow
      python3
      ripgrep
    ];
  };
}
