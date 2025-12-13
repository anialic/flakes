{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable-small";
    rshy.url = "github:anialic/rshy";
    preservation.url = "github:nix-community/preservation";
    lanzaboote.url = "github:nix-community/lanzaboote";
    lanzaboote.inputs.nixpkgs.follows = "nixpkgs";
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";
    apple-silicon-support.url = "github:nix-community/nixos-apple-silicon";
  };

  outputs =
    { nixpkgs, rshy, ... }@inputs:
    rshy.mkFlake {
      inherit nixpkgs;
      src = ./.;
      args = {
        inherit inputs;
        resource = ./_resource;
      };
    };
}
