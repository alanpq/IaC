{
  description = "Infra flake";

  nixConfig = {
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    alanp-web = {
      url = "github:alanpq/website";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    heardle = {
      url = "git+ssh://git@github.com/alanpq/heardle/";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    panoptes = {
      url = "git+ssh://git@github.com/alanpq/panoptes/";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    nixpkgs-unstable,
    disko,
    sops-nix,
    alanp-web,
    heardle,
    ...
  } @ inputs: let
    inherit (self) outputs;
    inherit (nixpkgs) lib;
    systems = ["x86_64-linux" "aarch64-linux"];
    forEachSystem = f: lib.genAttrs systems (system: f pkgsFor.${system});
    overlays = [
      (final: prev:
        import ./pkgs {pkgs = final;}
        // {
          # opencv = prev.opencv.overrideAttrs (old: let
          #   contribSrc = prev.fetchFromGitHub {
          #     owner = "opencv";
          #     repo = "opencv_contrib";
          #     tag = old.version;
          #     hash = "sha256-3tbscRFryjCynIqh0OWec8CUjXTeIDxOGJkHTK2aIao=";
          #   };
          # in {
          #   postUnpack = ''
          #     cp --no-preserve=mode -r "${contribSrc}/modules" "$NIX_BUILD_TOP/source/opencv_contrib"
          #   '';
          # });
          # perlPackages = prev.perlPackages.overrideScope (_: perlPrev: {
          #   ImageExifTool = perlPrev.ImageExifTool.overrideAttrs (old: rec {
          #     version = "13.38";
          #     src = prev.fetchurl {
          #       #url = "https://sourceforge.net/projects/exiftool/files/Image-ExifTool-${version}.tar.gz/download";
          #       url = "https://exiftool.org/Image-ExifTool-${version}.tar.gz";
          #       hash = "sha256-AlZnKrUHZi/kLRroUa4bVZMKPI62np1og8M1WekPXwE=";
          #       # https://sourceforge.net/projects/exiftool/files/Image-ExifTool-13.38.tar.gz/download
          #     };
          #   });
          # });
        })
    ];
    pkgsFor = lib.genAttrs systems (system:
      import nixpkgs {
        inherit system overlays;
        config.allowUnfree = true;
      });
    unstableOverlay = {config, ...}: {
      nixpkgs.overlays = overlays;
      nixpkgs.config.packageOverrides = pkgs: {
        unstable = import nixpkgs-unstable {
          inherit (config.nixpkgs) config;
          inherit system overlays;
        };
      };
    };
    system = "x86_64-linux";
  in {
    packages = forEachSystem (pkgs: import ./pkgs {inherit pkgs;});
    devShells = forEachSystem (pkgs: import ./shell.nix {inherit pkgs;});
    formatter = forEachSystem (pkgs: pkgs.alejandra);
    nixosConfigurations = {
      ein = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = {
          inherit inputs system;
        };
        modules = [
          sops-nix.nixosModules.sops
          disko.nixosModules.disko
          unstableOverlay
          ./hosts/ein
        ];
      };
      zephyr = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = {
          inherit inputs system;
        };
        modules = [
          sops-nix.nixosModules.sops
          disko.nixosModules.disko

          unstableOverlay

          alanp-web.nixosModules.default
          heardle.nixosModules.default
          {nixpkgs.overlays = overlays;}
          ./hosts/zephyr
        ];
      };
    };
  };
}
