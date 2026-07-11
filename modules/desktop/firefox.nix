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
          "sidebar.main.tools" = "aichat,bookmarks,history";
          "browser.ml.chat.enabled" = true;
          "browser.ml.chat.provider" = "https://claude.ai/new";
          "sidebar.backupState" = builtins.toJSON {
            command = "";
            launcherExpanded = false;
            launcherVisible = true;
          };
          "browser.uiCustomization.state" = builtins.toJSON {
            placements = {
              "widget-overflow-fixed-list" = [ ];
              "unified-extensions-area" = [ ];
              "nav-bar" = [ "sidebar-button" "urlbar-container" ];
              "toolbar-menubar" = [ "menubar-items" ];
              "TabsToolbar" = [ ];
              "vertical-tabs" = [ "tabbrowser-tabs" ];
              "PersonalToolbar" = [ "personal-bookmarks" ];
            };
            currentVersion = 22;
          };
        };
      };
    };
  };
}
