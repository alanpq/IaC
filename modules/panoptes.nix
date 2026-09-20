{
  inputs,
  system,
  config,
  ...
}: {
  sops.secrets.panoptes-discord-token = {};

  services = {
    panoptes = {
      enable = true;
      tokenFile = config.sops.secrets.panoptes-discord-token.path;
      database.createLocally = true; # brings up postgres + pgvector locally
      logLevel = "bot=debug,embedder=debug,serenity=warn,info";
    };
    caddy.virtualHosts."panoptes.alanp.me".extraConfig = ''
      reverse_proxy http://127.0.0.1:3010
    '';
  };
  virtualisation.oci-containers = {
    containers = {
      panoptes = {
        image = "panoptes:latest";
        imageFile =
          inputs.panoptes.packages.${system}.website-image;

        ports = ["3010:80"];
      };
    };
  };
}
