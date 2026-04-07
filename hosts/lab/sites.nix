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

{ ... }:
let
  websiteData = "/srv/website/data";
in
{
  services.site.website = {
    enable = true;
    domain = "wynne.rs";
    redirectDomains = [ "ily.rs" ];
    repo = "https://git.ily.rs/lew/website";
    branch = "master";
    port = 4322;
    environment = {
      ASTRO_DB_REMOTE_URL = "file:${websiteData}/guestbook.db";
    };
    buildEnvironment = {
      ASTRO_DB_REMOTE_URL = "file:${websiteData}/guestbook.db";
    };
    readWritePaths = [ websiteData ];
  };

  services.site.penfield = {
    enable = true;
    domain = "penfield.ily.rs";
    redirectDomains = [ "penfield.wynne.rs" ];
    repo = "https://git.ily.rs/lew/penfield";
    static = true;
    preview.enable = true;
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
