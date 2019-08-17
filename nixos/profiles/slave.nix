# NixOS profile for gcespark slave nodes
{ config, pkgs, lib, ... } :
let
  master_ip = config.services.hadoopCluster.master_ip;
  spark = (import ../nixpkgs-pinned.nix {}).spark;
in
{
  imports = [ ./node.nix ];

  services.hadoopCluster.master = false;

  systemd.services.spark-slave = {
    wantedBy = [ "multi-user.target" ];
    serviceConfig.User = "spark";
    path = [ pkgs.procps ];
    environment = {
      SPARK_MASTER_HOST = master_ip;
      SPARK_LOG_DIR = "${config.users.users.spark.home}/logs";
      SPARK_WORKER_DIR = "${config.users.users.spark.home}/work";
      SPARK_NO_DAEMONIZE = "true";
    };
    script = ''
      ${spark}/lib/spark-2.4.3-bin-without-hadoop/sbin/start-slave.sh spark://${master_ip}:7077
    '';
  };
}
