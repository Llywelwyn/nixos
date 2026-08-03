{
  flake.modules.homeManager.desktop = { pkgs, ... }: {
    home.packages = with pkgs; [
      inkscape
      krita
      mpv
      vesktop
      slack
      proton-authenticator
    ];
  };
}
