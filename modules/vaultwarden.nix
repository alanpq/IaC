{
  lib,
  config,
  pkgs,
  ...
}: let
  domain = lib.concatStringsSep "." ["pass" "alanp" "me"];
in {
  services.vaultwarden = {
    enable = true;
    package = pkgs.unstable.vaultwarden;
    backupDir = "/var/local/vaultwarden/backup";
    environmentFile = config.sops.templates.vaultwarden-env.path;
    config = {
      # Refer to https://github.com/dani-garcia/vaultwarden/blob/main/.env.template
      DOMAIN = "https://${domain}";
      SIGNUPS_ALLOWED = false;

      ROCKET_ADDRESS = "127.0.0.1";
      ROCKET_PORT = 8222;
      ROCKET_LOG = "critical";
    };
  };

  sops = {
    templates.vaultwarden-env.content = ''
      ADMIN_TOKEN='${config.sops.placeholder.vaultwardenAdminToken}'
    '';
    secrets = {
      vaultwardenAdminToken = {};
    };
  };

  services.caddy.virtualHosts.${domain}.extraConfig = ''
    encode zstd gzip

    reverse_proxy :${toString config.services.vaultwarden.config.ROCKET_PORT} {
        header_up X-Real-IP {remote_host}
    }
  '';
}
