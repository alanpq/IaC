{pkgs, ...}: {
  environment.systemPackages = [
    pkgs.nss.tools # needed for caddy self signed certs?
  ];
  services.caddy = {
    enable = true;
    # cloudflare covers us ssl-wise, we just need self signed certs
    globalConfig = ''
      local_certs
    '';
    virtualHosts."localhost".extraConfig = ''
      respond "OK"
    '';
  };
}
