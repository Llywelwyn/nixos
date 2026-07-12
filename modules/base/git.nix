{ config, ... }:
{
  flake.modules.homeManager.base = {
    programs.git = {
      enable = true;
      lfs.enable = true;
      ignores = [ "**/.claude/settings.local.json" ];
      settings = {
        user = {
          name = "Lewis Wynne";
          email = config.flake.meta.email;
        };
        init.defaultBranch = "main";
        url."ssh://forgejo@git.ily.rs:4201/".insteadOf = "https://git.ily.rs/";
        pull.rebase = true;
        submodule.recurse = true;
        push.recurseSubmodules = "on-demand";
      };
    };
  };
}
