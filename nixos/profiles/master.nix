# NixOS profile for gcespark master node
{ config, pkgs, lib, ... } :
let
  pinnedPkgs = import ../nixpkgs-pinned.nix {};
  hive = fetchTarball {
    url = http://dk.mirrors.quenda.co/apache/hive/hive-3.1.2/apache-hive-3.1.2-bin.tar.gz;
    sha256 = "1g4y3378y2mwwlmk5hs1695ax154alnq648hn60zi81i83hbxy5q";
  };
  spark = pinnedPkgs.spark;
  tcpds = import ../packages/tpcds.nix { inherit pkgs; };
in
{
  imports = [ ./common.nix ];

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
    path = with pkgs; [ config.services.hadoop.package hive bash gawk procps which ];
    environment = {
      HIVE_HOME = hive;
      HADOOP_HOME = config.services.hadoop.package;
      HADOOP_HEAPSIZE = "2048";
    };
    serviceConfig.User = "hive";
    script = ''
      hdfs dfs -mkdir -p hdfs://master:9000/tmp/hive
      hdfs dfs -mkdir -p hdfs://master:9000/user/hive/warehouse
      cd
      schematool -initSchema -dbType derby || true
      hiveserver2\
        --hiveconf hive.metastore.schema.verification=false\
        --hiveconf hive.server2.enable.doAs=false\
        --hiveconf fs.defaultFS=hdfs://master:9000/\
        --hiveconf org.jpox.autoCreateSchema=true
    '';
    after = [ "hdfs-namenode.service" ];
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
