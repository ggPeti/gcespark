# nix-shell environment for provisioning infrastructure and deployment
{pkgs ? import nixos/nixpkgs-pinned.nix {}, ...} :
let
  terraform = (pkgs.terraform_0_12.withPlugins (p: with p; [
    p.null local template tls google
  ]));
in
pkgs.stdenv.mkDerivation {
  name = "gcespark-env";
  buildInputs = [ terraform ];
  shellHook = ''
    [ -z $GOOGLE_CREDENTIALS ] && export GOOGLE_CREDENTIALS=account.json
    terraform init
  '';
}
