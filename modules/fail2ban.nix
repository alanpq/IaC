{
  services.fail2ban = {
    enable = true;
    maxretry = 3;
    ignoreIP = [
      "10.0.0.0/8"
      "172.16.0.0/12"
      "192.168.0.0/16"
    ];
    jails = {
      # (nixos module provides default jail for ssh)
    };
  };
}
