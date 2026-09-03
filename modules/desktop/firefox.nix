{ inputs, ... }:
{
  flake.modules.homeManager.desktop = { pkgs, ... }:
  {
    home.packages = [ pkgs.firefoxpwa ];

    xdg = {
      configFile."mimeapps.list".force = true;
      mimeApps = {
        enable = true;
        defaultApplications = {
          "text/html" = "firefox.desktop";
          "x-scheme-handler/http" = "firefox.desktop";
          "x-scheme-handler/https" = "firefox.desktop";
          "x-scheme-handler/about" = "firefox.desktop";
          "x-scheme-handler/unknown" = "firefox.desktop";
        };
      };
    };

    programs.firefox = {
      enable = true;
      nativeMessagingHosts = [ pkgs.firefoxpwa ];
      profiles.default = {
        id = 0;
        extensions.packages = with inputs.firefox-addons.packages.${pkgs.stdenv.hostPlatform.system}; [
          linkding-extension
          proton-pass
          pwas-for-firefox
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
