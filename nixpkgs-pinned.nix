# Define a pinned nixpkgs version
{ pkgs ? import <nixpkgs> {}, ...} :
let
  pinned_pkgs_path = pkgs.fetchFromGitHub {
    owner = "NixOS";
    repo = "nixpkgs";
    rev = "8669561bde00b4039cda2b662f9f726db8385069";
    sha256 = "157a5h1vcfj892b20c90n7i6rfr5k61242ylgz6i21m8sbcxfry6";
  };
in
  import pinned_pkgs_path {}
