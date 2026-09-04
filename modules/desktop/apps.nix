{
  flake.modules.homeManager.desktop = { pkgs, ... }: {
    home.packages = with pkgs; [
      krita
      mpv
      vesktop
      slack
      proton-authenticator
    ];
  };
}
