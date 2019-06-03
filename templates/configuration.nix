{ ... }:

{
  imports = [
    <nixpkgs/nixos/modules/virtualisation/google-compute-image.nix>
    /root/host.nix
  ];
}

# /etc/nixos/configuration.nix