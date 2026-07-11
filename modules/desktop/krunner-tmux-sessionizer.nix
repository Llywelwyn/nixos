{
  flake.modules.homeManager.desktop =
    { config, pkgs, ... }:
    let
      python = pkgs.python3.withPackages (ps: [
        ps.dbus-python
        ps.pygobject3
      ]);
      runner = pkgs.writeScriptBin "krunner-tmux-sessionizer" ''
        #!${python}/bin/python3
        ${builtins.readFile ./_scripts/krunner-tmux-sessionizer.py}
      '';
    in
    {
      xdg.dataFile."krunner/dbusplugins/tmux-sessionizer.desktop".text = ''
        [Desktop Entry]
        Type=Service
        Name=tmux-sessionizer
        Comment=Open or focus a project tmux session
        Icon=utilities-terminal
        X-KDE-PluginInfo-Name=tmux-sessionizer
        X-KDE-PluginInfo-EnabledByDefault=true
        X-KDE-ServiceTypes=Plasma/Runner
        X-Plasma-API=DBus
        X-Plasma-DBusRunner-Service=rs.ily.tmuxsessionizer
        X-Plasma-DBusRunner-Path=/runner
        X-Plasma-Runner-Min-Letter-Count=2
      '';

      systemd.user.services.krunner-tmux-sessionizer = {
        Unit = {
          Description = "KRunner DBus runner for tmux-sessionizer";
          After = [ "graphical-session.target" ];
          PartOf = [ "graphical-session.target" ];
        };
        Service = {
          Type = "dbus";
          BusName = "rs.ily.tmuxsessionizer";
          ExecStart = "${runner}/bin/krunner-tmux-sessionizer";
          Restart = "on-failure";
          Environment = [ "PATH=${config.home.profileDirectory}/bin:/run/current-system/sw/bin" ];
        };
        Install.WantedBy = [ "graphical-session.target" ];
      };
    };
}
