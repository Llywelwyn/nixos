{ ... }:
let
  wynneDataDir = "/srv/website";
in
{
  services.site.wynne = {
    domain = "wynne.rs";
    redirectDomains = [ "ily.rs" ];
    repo = "https://git.ily.rs/lew/website";
    branch = "master";
    port = 4322;
    packageManager = "pnpm";
    dataDir = wynneDataDir;
    environment = {
      ASTRO_DB_REMOTE_URL = "file:${wynneDataDir}/data/guestbook.db";
    };
    buildEnvironment = {
      ASTRO_DB_REMOTE_URL = "file:${wynneDataDir}/data/guestbook.db";
    };
    readWritePaths = [ "${wynneDataDir}/data" ];
    afterServices = [ "forgejo.service" ];
  };
}
