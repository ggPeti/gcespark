# NixOS profile for gcespark master node
{ config, pkgs, lib, ... } :
let
  pinnedPkgs = import ../nixpkgs-pinned.nix {};
  hive = fetchTarball {
    url = http://dk.mirrors.quenda.co/apache/hive/hive-3.1.1/apache-hive-3.1.1-bin.tar.gz;
    sha256 = "0j08v9lsh86m1i0wnk6mahkkggjhqijxz131bzi3agvqnvzkrcya";
  };
  spark = pinnedPkgs.spark;
  tcpds = import ../packages/tpcds.nix { inherit pkgs; };
in
{
  imports = [ ./node.nix ];

  fileSystems."/data" = {
    device = "/dev/sdb";
    autoFormat = true;
    fsType = "ext4";
  };

  environment.systemPackages = [
    tcpds
    hive
    pkgs.tmate
    pkgs.vim
  ];

  users.groups.hive = {};
  users.users.hive = {
    group = "hive";
    createHome = true;
    home = "/home/hive";
  };

  services.hadoopCluster.master = true;

  systemd.services.hive = {
    wantedBy = [ "multi-user.target" ];
    path = [ config.services.hadoop.package hive pkgs.bash pkgs.gawk ];
    environment = {
      HIVE_HOME = hive;
    };
    serviceConfig.User = "hive";
    script = ''
      hadoop fs -mkdir -p /tmp
      hadoop fs -mkdir -p ${config.users.users.hive.home}/warehouse
      hadoop fs -chmod a+rwx /tmp
      hadoop fs -chmod a+rwx /tmp/hive
      hadoop fs -chmod a+rwx ${config.users.users.hive.home}/warehouse
      cd ${config.users.users.hive.home}/warehouse
      schematool -dbType derby -initSchema || true
      hiveserver2
    '';
  };

  systemd.services.spark-master = {
    wantedBy = [ "multi-user.target" ];
    environment = {
      SPARK_MASTER_HOST = config.services.hadoopCluster.master_ip;
      SPARK_LOG_DIR = "${config.users.users.spark.home}/logs";
      SPARK_NO_DAEMONIZE = "true";
    };
    serviceConfig.User = "spark";
    path = [ pkgs.procps ];
    script = ''
      ${spark}/lib/spark-2.4.3-bin-without-hadoop/sbin/start-master.sh
    '';
  };
}
