{ config, ... }:
{
  sops.secrets.discord-irc-token = {
    sopsFile = ../../secrets/discord-irc.yaml;
  };

  sops.templates."discord-irc-config.json" = {
    owner = "podman";
    restartUnits = [ "podman-discord-irc.service" ];
    content = builtins.toJSON {
      nickname = "d";
      format = {
        ircText = "<{$discordUsername}> {$text}";
        urlAttachment = "<{$discordUsername}> {$attachmentURL}";
      };
      server = "127.0.0.1";
      port = 6667;
      tls = false;
      discordToken = config.sops.placeholder.discord-irc-token;
      webhooks = true;
      ircNickColor = true;
      ircStatusNotices = false;
      sendMessageUpdates = true;
      channelMapping = {
        "1507821989300273307" = "#grey-mc";
        "1462196901209440374" = "#grey-dnd";
        "832733970068144221" = "#grey";
        "384092190068047880" = "#icon";
        "462370232712036355" = "#laiken";
        "1401241161225732240" = "#laiken-osrs";
        "1449354793687584880" = "#laiken-osrs-loot";
        "302201161044328450" = "#aurora-code";
        "157531783779319808" = "#aurora";
        "725470666039754783" = "#aurora-serious";
        "1163487808879611955" = "#aurora-creations";
      };
    };
  };

  virtualisation.oci-containers.containers.discord-irc = {
    image = "ghcr.io/aronson/discord-irc:3.1.0";
    podman.user = "podman";
    extraOptions = [ "--network=host" ];
    volumes = [
      "${config.sops.templates."discord-irc-config.json".path}:/app/config.json:ro"
    ];
  };

  systemd.services.podman-discord-irc = {
    after = [ "ergochat.service" ];
    wants = [ "ergochat.service" ];
  };
}
