{
  description = "Flake for building scenic.";

  inputs = {
    nixpkgs = { url = "github:NixOS/nixpkgs/nixos-23.11"; };
    flake-utils = { url = "github:numtide/flake-utils"; };
  };
  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
    let
      inherit (pkgs.lib) optional optionals;
      pkgs = import nixpkgs { inherit system; };

      elixir = pkgs.beam.packages.erlang.elixir;
    in
    with pkgs;
    {
      devShell = pkgs.mkShell {
        buildInputs = [
          elixir_1_16
          elixir_ls
        ] ++ optional stdenv.isLinux inotify-tools
          ++ optional stdenv.isDarwin terminal-notifier
          ++ optionals stdenv.isDarwin (with darwin.apple_sdk.frameworks; [
            CoreFoundation
            CoreServices
          ]);
      };
  });
}
