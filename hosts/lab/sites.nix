# services.site.<name> options:
#
#   enable              — whether this site is active (default: false)
#   domain              — primary domain (required)
#   repo                — git repository URL (required)
#   static              — serve build output as static files, no Node server (default: false)
#   port                — Node.js server port (required when static = false)
#   buildOutputDir      — build output directory relative to repo root (default: "dist")
#   redirectDomains     — domains that 301 to the primary domain (default: [])
#   branch              — git branch to track (default: "main")
#   packageManager      — "npm" or "pnpm" (default: "pnpm")
#   installCommand      — override install command, "" skips, null derives from packageManager (default: null)
#   buildCommand        — override build command, null derives from packageManager (default: null)
#   extraBuildPackages  — extra packages on PATH during build, e.g. zola (default: [])
#   caddyConfig         — override Caddy extraConfig for primary domain, null uses default (default: null)
#   entryPoint          — Node.js entry point relative to repo root (default: "dist/server/entry.mjs")
#   environment         — env vars for the running server (default: {})
#   buildEnvironment    — env vars for building (default: {})
#   dataDir             — base directory for repo and data (default: /srv/<name>)
#   readWritePaths      — paths the server can write to at runtime (default: [])
#   afterServices       — systemd units to wait for before building (default: ["forgejo.service"])
#   preview.enable      — TinyAuth-protected preview of this site (default: false)
#   preview.branch      — branch for preview (default: "develop")
#   preview.domain      — preview domain (default: 0<name>.ily.rs)
#   preview.port        — preview server port (required when static = false)
#
# remarks:
#
#   - a listener is active on http://localhost:4323/hooks/${name}-rebuild for CD
#     Forgejo repo -> settings -> Webhooks -> Add webhook
#   - preview webhook: http://localhost:4323/hooks/${name}-preview-rebuild

{ pkgs, nixpkgs-unstable, ... }:
let
  unstable = import nixpkgs-unstable { inherit (pkgs) system; };
in
{
  services.site.website = {
    enable = true;
    domain = "ily.rs";
    redirectDomains = [ "wynne.rs" ];
    repo = "https://git.ily.rs/lew/website";
    branch = "master";
    static = true;
    buildOutputDir = "public";
    installCommand = "";
    buildCommand = "zola build";
    # 25.11 ships zola 0.21.0; the new [markdown.highlighting] section
    # (light_theme/dark_theme/extra_themes) needs 0.22+. Pull from unstable.
    extraBuildPackages = [ unstable.zola ];
    caddyConfig = ''
      import favicons

      root * /srv/website/repo/public
      encode zstd gzip

      @now_legacy path /now.txt /txt/now.txt
      handle @now_legacy {
        redir * /now permanent
      }

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

      @site_file file {
        try_files {path} {path}/index.html
      }
      handle @site_file {
        try_files {path} {path}/index.html
        file_server
      }

      handle {
        reverse_proxy localhost:8080
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
}
