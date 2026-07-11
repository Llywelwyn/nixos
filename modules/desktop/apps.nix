{
  flake.modules.nixos.desktop = {
    nixpkgs.config.allowUnfree = true;
  };

  flake.modules.homeManager.desktop = { pkgs, ... }: {
    home.packages = with pkgs; [
      vesktop
      slack
      proton-authenticator
    ];
  };
}
