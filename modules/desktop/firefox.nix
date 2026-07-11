{ inputs, ... }:
{
  flake.modules.homeManager.desktop = { pkgs, ... }: {
    programs.firefox = {
      enable = true;
      profiles.default = {
        id = 0;
        extensions.packages = with inputs.firefox-addons.packages.${pkgs.stdenv.hostPlatform.system}; [
          proton-pass
          ublock-origin
        ];
        settings = {
          "sidebar.revamp" = true;
          "sidebar.verticalTabs" = true;
        };
      };
    };
  };
}
