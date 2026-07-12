{ inputs, ... }:
{
  flake.modules.homeManager.desktop = { pkgs, lib, ... }: {
    imports = [ inputs.plasma-manager.homeModules.plasma-manager ];

    home.packages = [
      pkgs.kdotool
      (pkgs.writeShellScriptBin "focus-or-launch" (builtins.readFile ./_scripts/focus-or-launch))
    ];

    programs.plasma = {
      enable = true;

      kwin.virtualDesktops = {
        rows = 1;
        names = [ "main" "chat" "work" ];
      };

      shortcuts = {
        kwin = {
          "Overview" = [ ];
          "Show Desktop" = [ ];
          "Window Close" = "Meta+W";
          "Window Maximize" = "Meta+Z";
          "Window Fullscreen" = "F11";
          "Switch Window Left" = "Meta+Left";
          "Switch Window Right" = "Meta+Right";
          "Switch Window Up" = "Meta+Up";
          "Switch Window Down" = "Meta+Down";
          "Window Quick Tile Left" = "Meta+Shift+Left";
          "Window Quick Tile Right" = "Meta+Shift+Right";
          "Window Quick Tile Top" = "Meta+Shift+Up";
          "Window Quick Tile Bottom" = "Meta+Shift+Down";
          "Switch to Desktop 1" = "Meta+1";
          "Switch to Desktop 2" = "Meta+2";
          "Switch to Desktop 3" = "Meta+3";
          "Window to Desktop 1" = [ "Meta+Shift+1" "Meta+!" ];
          "Window to Desktop 2" = [ "Meta+Shift+2" "Meta+\"" ];
          "Window to Desktop 3" = [ "Meta+Shift+3" "Meta+£" ];
          "Walk Through Windows" = [ "Alt+Tab" "Meta+Tab" ];
          "Walk Through Windows (Reverse)" = [ "Alt+Shift+Tab" "Meta+Shift+Tab" ];
        };
        "org_kde_powerdevil"."powerProfile" = "Battery";
        plasmashell = {
          "next activity" = [ ];
          "previous activity" = [ ];
        }
        // lib.listToAttrs (
          map (i: lib.nameValuePair "activate task manager entry ${toString i}" [ ]) (lib.range 1 9)
        );
      };

      hotkeys.commands = {
        launch-terminal = {
          name = "Launch Ghostty";
          key = "Meta+Return";
          command = "ghostty";
        };
        launch-browser = {
          name = "Launch Firefox";
          key = "Meta+B";
          command = "firefox";
        };
        toggle-vesktop = {
          name = "Focus or launch Vesktop";
          key = "Meta+D";
          command = "focus-or-launch vesktop vesktop";
        };
        toggle-slack = {
          name = "Focus or launch Slack";
          key = "Meta+S";
          command = "focus-or-launch slack slack";
        };
      };

      powerdevil.AC = {
        turnOffDisplay.idleTimeout = 600;
        autoSuspend = {
          action = "sleep";
          idleTimeout = 3600;
        };
      };

      krunner = {
        position = "top";
        activateWhenTypingOnDesktop = false;
        historyBehavior = "enableAutoComplete";
        shortcuts.launch = "Meta+Space";
      };

      window-rules = [
        {
          description = "chat apps open on the chat desktop";
          match.window-class = {
            value = "vesktop|[Ss]lack";
            type = "regex";
          };
          apply.desktops = {
            value = "Desktop_2";
            apply = "initially";
          };
        }
        {
          description = "obs opens on the work desktop";
          match.window-class = {
            value = "obsproject";
            type = "substring";
          };
          apply.desktops = {
            value = "Desktop_3";
            apply = "initially";
          };
        }
      ];

      configFile = {
        kwinrc.TabBox.DesktopMode = 1;
        krunnerrc.Plugins = {
          "baloosearchEnabled" = false;
          "bookmarksEnabled" = true;
          "calculatorEnabled" = false;
          "helprunnerEnabled" = false;
          "krunner_charrunnerEnabled" = false;
          "krunner_dictionaryEnabled" = false;
          "krunner_katesessionsEnabled" = false;
          "krunner_killEnabled" = false;
          "krunner_konsoleprofilesEnabled" = false;
          "krunner_placesrunnerEnabled" = false;
          "krunner_powerdevilEnabled" = true; 
          "krunner_recentdocumentsEnabled" = false;
          "krunner_sessionsEnabled" = false;
          "krunner_shellEnabled" = false;
          "krunner_spellcheckEnabled" = false;
          "krunner_webshortcutsEnabled" = false;
          "locationsEnabled" = true;
          "org.kde.datetimeEnabled" = false;
          "tmux-sessionizerEnabled" = true;
          "unitconverterEnabled" = false;
          "windowsEnabled" = false;
        };
      };
    };
  };
}
