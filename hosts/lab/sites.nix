# Options are documented in modules/site.nix. Each site gets a CD webhook at
# http://localhost:4323/hooks/<name>-rebuild (preview: <name>-preview-rebuild);
# point a Forgejo push webhook at it.
{ pkgs, ... }:
{
  services.site.website = {
    enable = true;
    domain = "ily.rs";
    redirectDomains = [ "www.ily.rs" "wynne.rs" "www.wynne.rs" "lewis.wales" "www.lewis.wales" ];
    repo = "https://git.ily.rs/lew/website";
    branch = "master";
    static = true;
    buildOutputDir = "public";
    installCommand = "";
    buildCommand = "zola build";
    extraBuildPackages = [ pkgs.zola ];
    caddyConfig = ''
      import favicons

      root * /srv/website/repo/public
      encode zstd gzip

      @now_legacy path /now.txt /txt/now.txt
      handle @now_legacy {
        redir * /now permanent
      }

      redir /p /blog/penfield/ permanent

      @guestbook path /guestbook /guestbook/*
      handle @guestbook {
        reverse_proxy localhost:8123
      }

      @status path /status
      handle @status {
        root * /var/lib/uptime
        rewrite * /status.txt
        file_server
      }

      handle {
        try_files {path} {path}/index.html
        file_server
      }

      handle_errors 404 {
        rewrite * /404.html
        file_server
      }
    '';
  };

  services.site.penfield = {
    enable = true;
    domain = "penfield.ily.rs";
    redirectDomains = [ "penfield.wynne.rs" ];
    repo = "https://git.ily.rs/lew/penfield";
    static = true;
  };

  services.site.record-generator = {
    enable = true;
    domain = "c.ily.rs";
    repo = "https://git.ily.rs/lew/character-records-generator";
    branch = "master";
    static = true;
    buildOutputDir = "build";
    packageManager = "npm";
  };

  services.site.x = {
    enable = true;
    domain = "x.ily.rs";
    repo = "https://git.ily.rs/lew/x";
    static = true;
    buildOutputDir = ".";
    installCommand = "";
    buildCommand = "";
  };
}
