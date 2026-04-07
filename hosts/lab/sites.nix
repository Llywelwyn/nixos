# services.site.<name> options:
#
#   domain              — primary domain (required)
#   repo                — git repository URL (required)
#   port                — Node.js server port (required)
#   redirectDomains     — domains that 301 to the primary domain (default: [])
#   branch              — git branch to track (default: "main")
#   packageManager      — "npm" or "pnpm" (default: "pnpm")
#   entryPoint          — Node.js entry point relative to repo root (default: "dist/server/entry.mjs")
#   environment         — env vars for the running server (default: {})
#   buildEnvironment    — env vars for building (default: {})
#   dataDir             — base directory for repo and data (default: /srv/<name>)
#   readWritePaths      — paths the server can write to at runtime (default: [])
#   afterServices       — systemd units to wait for before building (default: ["forgejo.service"])

{ ... }:
let
  websiteData = "/srv/website/data";
in
{
  services.site.website = {
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
    domain = "penfield2.ily.rs";
    repo = "https://git.ily.rs/lew/penfield";
    port = 4324;
  };
}
