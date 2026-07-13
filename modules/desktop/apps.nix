{
  flake.modules.homeManager.desktop = { pkgs, ... }: {
    home.packages = with pkgs; [
      vesktop
      slack
      proton-authenticator
    ];
  };
}
