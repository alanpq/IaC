{
  description = "Infra flake";

  nixConfig = {
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    disko,
    sops-nix,
    ...
  }: let
    system = "x86_64-linux";
  in {
    nixosConfigurations = {
      ein = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          sops-nix.nixosModules.sops
          disko.nixosModules.disko
          ./hosts/ein
        ];
      };
    };
  };
}
