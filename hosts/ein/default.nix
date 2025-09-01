{
  modulesPath,
  pkgs,
  config,
  lib,
  inputs,
  ...
}: {
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    (modulesPath + "/profiles/qemu-guest.nix")
    ./disko.nix
    ./hardware-configuration.nix
    ../../modules/caddy.nix
    ../../modules/jellyfin.nix
    ../../modules/immich.nix
  ];

  nix = {
    package = lib.mkDefault pkgs.nix;
    settings = {
      experimental-features = ["nix-command" "flakes"];
      warn-dirty = false;
    };
  };
  # sops.age.sshKeyPaths = ["/etc/ssh/ssh_host_ed25519_key"];
  boot = {
    loader.systemd-boot.enable = true;
    loader.efi.canTouchEfiVariables = true;
    supportedFilesystems = ["ntfs" "vfat" "ext4" "lvm" "xfs"];
  };
  sops.defaultSopsFile = ./secrets.yaml;

  services.cloudflare-dyndns = {
    enable = true;
    apiTokenFile = config.sops.secrets.cloudflare-api-token.path;
    domains = [
      "ein.alanp.me"
    ];
    proxied = true;
  };
  sops.secrets.cloudflare-api-token = {};

  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "yes";
      PasswordAuthentication = false;
    };
  };
  networking = {
    hostName = "ein";
    firewall.allowedTCPPorts = [80 443 22];
  };
  users.users.root.password = "";
  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKKUWJ2oqT2pcU1LR8iOG03FXh8rBsUg8yNfEi13yofq alan@gamer-think"
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC+9vPgSsCWRTtVmS+8MhBz/aKKPFPZlZc2iZ4Xf7oJa4LvzScMlh/O9mlQepGIuVUnGYB0AJ8CP3jGw/p8Yn2QGD7YE+w4xf4c03fpELFxeOMSZEeBEjXb0+tkLWoWY28mVFpmr2zt/Vj1uzvR1hxoiGV20VHViSRxzIrmMGYT0njhcdVfu5JcfS1fdXVrSbF6SwAut/49O8Tb5sp83tNKc9S/nR0ReQMwMReOAOkB4MemB05eqjIwbwall38ualf/vF395ObO1LKLiU1DjILfm33Oa57UAHpudoK3GzUZdqaAJeL1mTaH5o9Lvy9cJcTN+RHQhwv2hCjzUR1swMfrGSuNNIpy22ghSf8bOU1dyvtljMax6i+WKPUzeRKVI9bWCcjZZFd0OUA2MfqsWPX+ER29uaWcssHb75Mv1oA3R6FgJ4LokghxUUYZZfjjUZlLpRkgdZQvr10ZKiG1gjzgw0E+un9BT2Ts0g6smtN3I1s525iG3eY33fBt0UU8RJ0= alan@zwei-pc"
  ];

  environment.systemPackages = map lib.lowPrio [
    pkgs.neovim
    pkgs.curl
    pkgs.gitMinimal
  ];

  system.stateVersion = "25.05";
}
