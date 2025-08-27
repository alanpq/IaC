{config, ...}: let
  domain = "immich.alanp.me";
in {
  services.immich = {
    enable = true;
    port = 2283;
    openFirewall = false;
    accelerationDevices = null; # allow all devices

    settings.server.externalDomain = "https://${domain}";

    mediaLocation = "/media/immich";
  };
  users.users.immich.extraGroups = ["video" "render"];

  services.caddy.virtualHosts."${domain}".extraConfig = ''
    reverse_proxy http://${toString config.services.immich.host}:${toString config.services.immich.port}
  '';
}
