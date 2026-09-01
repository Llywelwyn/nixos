{
  flake.modules.nixos.desktop = { pkgs, ... }:
    let
      version = "1.0.3.1";
      appimage = pkgs.fetchurl {
        url = "https://github.com/The-Convergence-Team/ConvergenceER-Public/releases/download/v${version}/ConvergenceLauncher_linux.AppImage";
        hash = "sha256-2FkrZ49HRKyoVa4YgGV5aS45acYw4VYui1iYvCaGz2Q=";
      };
      desktopItem = pkgs.makeDesktopItem {
        name = "convergence-launcher";
        desktopName = "The Convergence Launcher";
        comment = "ELDEN RING The Convergence Launcher";
        exec = "convergence-launcher";
        categories = [ "Game" ];
      };
      wrapped = pkgs.appimageTools.wrapType2 {
        pname = "convergence-launcher";
        inherit version;
        src = appimage;
        extraPkgs = p: [ p.icu ];
      };
      convergence = pkgs.symlinkJoin {
        name = "convergence-launcher-${version}";
        paths = [ wrapped ];
        postBuild = ''
          install -Dm444 ${desktopItem}/share/applications/*.desktop -t $out/share/applications
        '';
      };
    in
    {
      environment.systemPackages = [ convergence ];
    };
}
