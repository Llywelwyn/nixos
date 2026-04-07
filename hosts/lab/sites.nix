{ ... }:
let
  websiteServiceDir = "/srv/website";
in
{
  services.site.website = {
    domain = "wynne.rs";
    redirectDomains = [ "ily.rs" ];
    repo = "https://git.ily.rs/lew/website";
    branch = "master";
    port = 4322;
    packageManager = "pnpm";
    dataDir = websiteServiceDir;
    environment = {
      ASTRO_DB_REMOTE_URL = "file:${websiteServiceDir}/data/guestbook.db";
    };
    buildEnvironment = {
      ASTRO_DB_REMOTE_URL = "file:${websiteServiceDir}/data/guestbook.db";
    };
    readWritePaths = [ "${websiteServiceDir}/data" ];
    afterServices = [ "forgejo.service" ];
  };
}
