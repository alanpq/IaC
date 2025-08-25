_: {
  # TODO: better jellyfin management (config is soo lame rn :c)
  services.jellyfin = {
    enable = true;
  };
  services.caddy.virtualHosts."jellyfin.alanp.me".extraConfig = ''
    reverse_proxy http://127.0.0.1:8096
  '';
}
