# nix-shell environment for provisioning infrastructure and deployment

{pkgs ? import ./nixpkgs-pinned.nix {}, ...} :
pkgs.stdenv.mkDerivation {
  name = "gcespark-env";
  buildInputs = [ (pkgs.terraform_0_12.withPlugins (p: [ p.google p.local p.null p.tls ])) ];
  GOOGLE_CREDENTIALS = if builtins.getEnv "GOOGLE_CREDENTIALS" == ""
                          then "account.json"
                          else builtins.getEnv "GOOGLE_CREDENTIALS";
  shellHook = "terraform init";
}
