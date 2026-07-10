# Options are documented in modules/server/site.nix. Each site gets a CD webhook at
# http://localhost:4323/hooks/<name>-rebuild (preview: <name>-preview-rebuild);
# point a Forgejo push webhook at it.
{
  flake.modules.nixos.server = { config, pkgs, ... }:
  let
    guestbookPort = toString config.services.guestbook.port;
  in
  {
    services = {
      telegram-alerts.units = [ "site-webhook" ];
      uptime-page.probes = {
        website  = { url = "https://ily.rs"; order = 10; };
        lite     = { url = "https://lite.ily.rs"; order = 15; };
        records  = { url = "https://c.ily.rs"; order = 50; };
        penfield = { url = "https://penfield.ily.rs"; order = 60; };
        x        = { url = "https://x.ily.rs"; order = 100; };
      };

      site = {
        website = {
          enable = true;
          domain = "ily.rs";
          redirectDomains = [ "www.ily.rs" "wynne.rs" "www.wynne.rs" "lewis.wales" "www.lewis.wales" ];
          repo = "https://git.ily.rs/l/website";
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
            redir /g /guestbook permanent

            @guestbook path /guestbook /guestbook/*
            handle @guestbook {
              reverse_proxy localhost:${guestbookPort}
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

        website-lite = {
          enable = true;
          domain = "lite.ily.rs";
          repo = "https://git.ily.rs/l/website";
          branch = "master";
          static = true;
          buildOutputDir = "public";
          installCommand = "";
          buildCommand = "zola --config config-lite.toml build && find public \\( -name '*.png' -o -name '*.gif' -o -name '*.jpg' -o -name '*.webp' \\) -delete";
          extraBuildPackages = [ pkgs.zola ];
          caddyConfig = ''
            import favicons
            root * /srv/website-lite/repo/public
            encode zstd gzip

            @guestbook path /guestbook /guestbook/*
            handle @guestbook {
              reverse_proxy localhost:${guestbookPort}
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

        penfield = {
          enable = true;
          domain = "penfield.ily.rs";
          redirectDomains = [ "penfield.wynne.rs" ];
          repo = "https://git.ily.rs/l/penfield";
          static = true;
          caddyConfig = ''
            import favicons
            root * /srv/penfield/repo/dist
            encode zstd gzip
            file_server
          '';
        };

        record-generator = {
          enable = true;
          domain = "c.ily.rs";
          repo = "https://git.ily.rs/l/character-records-generator";
          branch = "master";
          static = true;
          buildOutputDir = "build";
          packageManager = "npm";
        };

        x = {
          enable = true;
          domain = "x.ily.rs";
          repo = "https://git.ily.rs/l/x";
          static = true;
          buildOutputDir = ".";
          installCommand = "";
          buildCommand = "";
        };
      };
    };
  };
}
