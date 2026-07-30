{
  flake.modules.homeManager.desktop = {
    xdg.mimeApps.defaultApplications."x-scheme-handler/terminal" =
      "com.mitchellh.ghostty.desktop";

    programs.plasma.configFile.kdeglobals.General = {
      TerminalApplication = "ghostty";
      TerminalService = "com.mitchellh.ghostty.desktop";
    };

    programs.ghostty = {
      enable = true;
      settings = {
        font-family = "JetBrainsMonoNL Nerd Font";
        font-size = 9;
        background-opacity = 0.9;
        confirm-close-surface = false;
      };
    };
  };
}
