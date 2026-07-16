{
  flake.modules.homeManager.desktop = { pkgs, ... }: {
    home.packages = with pkgs; [
      mpv
      vesktop
      slack
      proton-authenticator
    ];
  };
}
