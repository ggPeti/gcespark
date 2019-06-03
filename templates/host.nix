# NixOS module for rds_tactics_proxy
# Provisioned by Terraform

{ config, pkgs, lib, ... } :
{
  networking.firewall.allowedTCPPorts = [ 22 9411 ];
  programs.bash.enableCompletion = true;

  systemd.services.zipkin = {
    wantedBy = [ "multi-user.target" ];
    after = [ "postgresql.service" ];
    serviceConfig.User = "";
    script = "${pkgs.zipkin}/bin/zipkin-server";
  };

}
