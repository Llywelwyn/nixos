{
  flake.modules.homeManager.desktop = { pkgs, ... }: {
    home.packages = with pkgs; [
      darktable
      krita
      mpv
      vesktop
      slack
      proton-authenticator
    ];
  };
}
