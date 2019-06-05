# NixOS module for gcespark
# Provisioned by Terraform

{ config, pkgs, lib, ... } :

{
  networking.firewall.allowedTCPPorts = [ 22 7077 8080 ];
  programs.bash.enableCompletion = true;

  users.groups.spark = {};
  users.users.spark = {
    group = "spark";
    createHome = true;
    home = "/home/spark";
  };

  systemd.services.mysparkservice = {
    wantedBy = [ "multi-user.target" ];
    serviceConfig.User = "spark";
    path = [ pkgs.procps ];
    script = ''
      export SPARK_MASTER_HOST=${master_ip}
      export SPARK_LOG_DIR=/home/spark/logs
      export SPARK_WORKER_DIR=/home/spark/work
      export SPARK_NO_DAEMONIZE=true
      $${(import ./nixpkgs-pinned.nix {}).spark}/lib/spark-2.4.3-bin-without-hadoop/sbin/start-slave.sh spark://${master_ip}:7077
    '';
  };

}
