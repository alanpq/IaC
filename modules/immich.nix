{
  config,
  pkgs,
  ...
}: let
  domain = "immich.alanp.me";
in {
  services.immich = {
    enable = true;
    port = 2283;
    openFirewall = false;
    accelerationDevices = null; # allow all devices

    settings.server.externalDomain = "https://${domain}";

    mediaLocation = "/mnt/immich";
  };
  users.users.immich = {
    uid = 994;
    extraGroups = ["video" "render"];
  };
  users.groups.immich.gid = 992;

  environment.systemPackages = [pkgs.cifs-utils];
  fileSystems."/mnt/immich" = {
    device = "//u455406-sub2.your-storagebox.de/u455406-sub2";
    fsType = "cifs";
    options = let
      # this line prevents hanging on network split
      automount_opts = "x-systemd.automount,noauto,x-systemd.idle-timeout=60,x-systemd.device-timeout=5s,x-systemd.mount-timeout=5s";
    in ["${automount_opts},credentials=${config.sops.templates.immich-samba-mount-creds.path},uid=${toString config.users.users.immich.uid},gid=${toString config.users.groups.immich.gid}"];
  };

  sops = {
    templates.immich-samba-mount-creds.content = ''
      username=${config.sops.placeholder.immich-samba-username}
      password=${config.sops.placeholder.immich-samba-password}
    '';
    secrets = {
      immich-samba-username = {};
      immich-samba-password = {};
    };
  };

  services.caddy.virtualHosts."${domain}".extraConfig = ''
    reverse_proxy http://${toString config.services.immich.host}:${toString config.services.immich.port}
  '';
}
