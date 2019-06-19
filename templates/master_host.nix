# NixOS module for gcespark
# Provisioned by Terraform

{ config, pkgs, lib, ... } :

let
  hivepackage = fetchTarball { 
    url = http://dk.mirrors.quenda.co/apache/hive/hive-3.1.1/apache-hive-3.1.1-bin.tar.gz;
    sha256 = "0j08v9lsh86m1i0wnk6mahkkggjhqijxz131bzi3agvqnvzkrcya";
  };
in 
  {
    imports = [ ./hadoop_cluster.nix ];

    networking.firewall.enable = false;

    fileSystems."/data" = {
      device = "/dev/sdb";
      autoFormat = true;
      fsType = "ext4";
    };

    programs.bash.enableCompletion = true;

    environment.systemPackages = [ (import /root/tpcds.nix { inherit pkgs; }) pkgs.hadoop_3_1 hivepackage pkgs.tmate pkgs.vim ];

    users.groups.spark = {};
    users.users.spark = {
      group = "spark";
      createHome = true;
      home = "/home/spark";
    };
    users.groups.hive = {};
    users.users.hive = {
      group = "hive";
      createHome = true;
      home = "/home/hive";
    };

    systemd.services.mysparkservice = {
      wantedBy = [ "multi-user.target" ];
      serviceConfig.User = "spark";
      path = [ pkgs.procps ];
      script = ''
        export SPARK_MASTER_HOST=${master_ip}
        export SPARK_LOG_DIR=/home/spark/logs
        export SPARK_NO_DAEMONIZE=true
        $${(import ./nixpkgs-pinned.nix {}).spark}/lib/spark-2.4.3-bin-without-hadoop/sbin/start-master.sh
      '';
    };

    services.hadoopCluster = {
      enable = true;
      master = true;
    };

    systemd.services.myhiveservice = {
      wantedBy = [ "multi-user.target" ];
      serviceConfig.User = "hive";
      path = [ hivepackage pkgs.hadoop_3_1 pkgs.bash pkgs.gawk ];
      script = ''
        export HADOOP_HOME=$${pkgs.hadoop_3_1}
        export HIVE_HOME=$${hivepackage}
        hadoop fs -mkdir -p /tmp
        hadoop fs -mkdir -p /home/hive/warehouse
        hadoop fs -chmod g+w /tmp
        hadoop fs -chmod g+w /home/hive/warehouse
        cd /home/hive/warehouse
        schematool -dbType derby -initSchema || true
        hiveserver2
      '';
    };
  }