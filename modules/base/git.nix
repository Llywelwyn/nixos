{
  flake.modules.homeManager.base = {
    programs.git = {
      enable = true;
      lfs.enable = true;
      ignores = [ "**/.claude/settings.local.json" ];
      settings = {
        user = {
          name = "Lewis Wynne";
          email = "l@ily.rs";
        };
        init.defaultBranch = "main";
        pull.rebase = true;
        submodule.recurse = true;
        push.recurseSubmodules = "on-demand";
      };
    };
  };
}
