{
  description = "Infra flake";

  nixConfig = {
    extra-substituters = ["https://microvm.cachix.org"];
    extra-trusted-public-keys = ["microvm.cachix.org-1:oXnBc6hRE3eX5rSYdRyMYXnfzcCxC7yKPTbZXALsqys="];
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

    microvm = {
      url = "github:astro/microvm.nix";
    };
  };

  outputs = {
    self,
    nixpkgs,
    microvm,
    disko,
    sops-nix,
    ...
  }: let
    system = "x86_64-linux";
  in {
    packages.${system} = {
      ein = self.nixosConfigurations.ein.config.microvm.declaredRunner;
    };

    nixosConfigurations = {
      ein = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          microvm.nixosModules.microvm
          sops-nix.nixosModules.sops
          disko.nixosModules.disko
          ./hosts/ein
        ];
      };
    };
  };
}
