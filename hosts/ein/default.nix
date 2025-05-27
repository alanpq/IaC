{
  pkgs,
  config,
  lib,
  inputs,
  ...
}: {
  imports = [
    ./disko.nix
    ../../modules/caddy.nix
  ];

  nix = {
    package = lib.mkDefault pkgs.nix;
    settings = {
      experimental-features = ["nix-command" "flakes"];
      warn-dirty = false;
    };
  };
  sops.age.sshKeyPaths = ["/etc/ssh/ssh_host_ed25519_key"];

  boot.loader.grub = {
    # no need to set devices, disko will add all devices that have a EF02 partition to the list already
    # devices = [ ];
    efiSupport = true;
    efiInstallAsRemovable = true;
  };

  services.cloudflare-dyndns = {
    enable = true;
    apiTokenFile = config.sops.secrets.cloudflare-api-token.path;
    domains = [
      "ein"
    ];
    proxied = true;
  };

  sops.secrets.cloudflare-api-token = {
    sopsFile = ./secrets.yaml;
  };

  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "yes";
      PasswordAuthentication = true;
    };
  };
  networking = {
    hostName = "ein";
    firewall.allowedTCPPorts = [80 443 22];
  };
  users.users.root.password = "";

  environment.systemPackages = map lib.lowPrio [
    pkgs.neovim
    pkgs.curl
    pkgs.gitMinimal
    pkgs.nss.tools # needed for caddy self signed certs?
  ];

  virtualisation.vmVariantWithDisko = {
    virtualisation = {
      forwardPorts = [
        {
          from = "host";
          host.port = 2222;
          guest.port = 22;
        }
      ];
      sharedDirectories = {
        my-share = {
          source = "/tmp/tmp.1b4nwgTkDb/etc/ssh/";
          target = "/etc/ssh";
        };
      };
    };
  };

  microvm = {
    volumes = [
      {
        mountPoint = "/var";
        image = "var.img";
        size = 256;
      }
    ];
    shares = [
      {
        # use proto = "virtiofs" for MicroVMs that are started by systemd
        proto = "9p";
        tag = "ro-store";
        # a host's /nix/store will be picked up so that no
        # squashfs/erofs will be built for it.
        source = "/nix/store";
        mountPoint = "/nix/.ro-store";
      }
    ];

    # "qemu" has 9p built-in!
    hypervisor = "qemu";
    socket = "control.socket";
  };

  system.stateVersion = "25.05";
}
