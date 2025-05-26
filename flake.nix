{
  description = "Infra flake";

  nixConfig = {
    extra-substituters = ["https://microvm.cachix.org"];
    extra-trusted-public-keys = ["microvm.cachix.org-1:oXnBc6hRE3eX5rSYdRyMYXnfzcCxC7yKPTbZXALsqys="];
  };

  inputs.microvm = {
    url = "github:astro/microvm.nix";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = {
    self,
    nixpkgs,
    microvm,
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
          ./hosts/ein.nix
        ];
      };
    };
  };
}
