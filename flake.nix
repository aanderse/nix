{
  description = "bite size pieces of nix";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/release-21.11";

  outputs = { self, nixpkgs }: {
    nixosModules.github-runner = import ./nixos/modules/github-runner;
  };
}
