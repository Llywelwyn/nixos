{
  flake.modules.nixos.desktop = { pkgs, ... }:
    let
      version = "2.1.0";
      appimage = pkgs.fetchurl {
        url = "https://github.com/ChrisDKN/Amethyst-Mod-Manager/releases/download/v${version}/AmethystModManager-${version}-x86_64.AppImage";
        hash = "sha256-Nwt/2qS7CVkyZjHiNsKwcdb21QAN2Jtg9E9YGI9RCEk=";
      };
      icon = pkgs.fetchurl {
        url = "https://raw.githubusercontent.com/ChrisDKN/Amethyst-Mod-Manager/v${version}/src/appimage/mod-manager.png";
        hash = "sha256-oXwQTMX15hClM6CWiOn8H6iB6z2n8fjnYvF7ggOhlhE=";
      };
      desktopItem = pkgs.makeDesktopItem {
        name = "amethyst-mod-manager";
        desktopName = "Amethyst Mod Manager";
        comment = "Game mod manager for Linux";
        exec = "amethyst-mod-manager %u";
        icon = "amethyst-mod-manager";
        categories = [ "Game" "Utility" ];
        mimeTypes = [ "x-scheme-handler/nxm" ];
        startupWMClass = "mod-manager";
      };
      amethyst = pkgs.runCommand "amethyst-mod-manager-${version}" { } ''
        install -Dm755 ${appimage} $out/bin/amethyst-mod-manager
        install -Dm444 ${icon} $out/share/icons/hicolor/256x256/apps/amethyst-mod-manager.png
        install -Dm444 ${desktopItem}/share/applications/*.desktop -t $out/share/applications
      '';
    in
    {
      environment.systemPackages = [ amethyst ];
      xdg.mime.defaultApplications."x-scheme-handler/nxm" = "amethyst-mod-manager.desktop";
    };
}
