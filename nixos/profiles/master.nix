# NixOS profile for gcespark master node
{ config, pkgs, lib, ... } :
let
  pinnedPkgs = import ../nixpkgs-pinned.nix {};
  hive = pkgs.stdenv.mkDerivation {
    name = "hive_with_new_pgjdbc";
    src = fetchTarball {
      url = http://dk.mirrors.quenda.co/apache/hive/hive-3.1.2/apache-hive-3.1.2-bin.tar.gz;
      sha256 = "1g4y3378y2mwwlmk5hs1695ax154alnq648hn60zi81i83hbxy5q";
    };
    installPhase = ''
      mkdir -p $out
      cp -r ./* $out
      rm $out/lib/postgresql-9.4.1208.jre7.jar
      cp ${pkgs.postgresql_jdbc}/share/java/postgresql-jdbc.jar $out/lib/
    '';
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
    spark
  ];

  users.groups.hive = {};
  users.users.hive = {
    group = "hive";
    createHome = true;
    home = "/home/hive";
  };

  services.hadoopCluster.master = true;

  services.postgresql = {
    enable = true;
    enableTCPIP = true;
    authentication = lib.mkAfter "host all all 127.0.0.1/32 trust";
  };

  systemd.services.createMetastoreDb = {
    wantedBy = [ "multi-user.target" ];
    serviceConfig.Type = "oneshot";
    serviceConfig.User = "postgres";
    path = [ config.services.postgresql.package hive pkgs.bash config.services.hadoop.package ];
    after = [ "postgresql.service" ];
    environment = {
      HADOOP_HOME = config.services.hadoop.package;
      HIVE_HOME = hive;
    };
    script = ''
      createdb metastore || true
      schematool -dbType postgres -initSchema -url jdbc:postgresql://localhost/metastore -ifNotExists -driver org.postgresql.Driver -userName postgres || true
    '';
  };
  
  systemd.services.metastore = {
    wantedBy = [ "multi-user.target" ];
    path = with pkgs; [ hive bash config.services.hadoop.package gawk procps which ];
    serviceConfig.User = "hive";
    environment = {
      HADOOP_HOME = config.services.hadoop.package;
      HIVE_HOME = hive;
    };
    script = ''
      hive --service metastore\
        --hiveconf metastore.task.threads.always=org.apache.hadoop.hive.metastore.events.EventCleanerTask\
        --hiveconf metastore.expression.proxy=org.apache.hadoop.hive.metastore.DefaultPartitionExpressionProxy\
        --hiveconf metastore.metastore.event.db.notification.api.auth=false\
        --hiveconf hive.metastore.warehouse.dir=hdfs://master:9000/user/hive/warehouse\
        --hiveconf datanucleus.schema.autoCreateAll=true\
        --hiveconf hive.metastore.schema.verification=false\
        --hiveconf javax.jdo.option.ConnectionURL=jdbc:postgresql:///metastore\
        --hiveconf javax.jdo.option.ConnectionDriverName=org.postgresql.Driver\
        --hiveconf javax.jdo.option.ConnectionUserName=postgres\
        --hiveconf hive.metastore.thrift.bind.host=localhost

    '';
    after = [ "createMetastoreDb.service" ];
  };

  systemd.services.hive = {
    wantedBy = [ "multi-user.target" ];
    path = with pkgs; [ config.services.hadoop.package hive bash gawk procps which ];
    environment = {
      HIVE_HOME = hive;
      HADOOP_HOME = config.services.hadoop.package;
      HADOOP_HEAPSIZE = "2048";
      HADOOP_CONF_DIR = "${config.services.hadoop.package}/etc/hadoop";
    };
    serviceConfig.User = "hive";
    script = ''
      hdfs dfs -mkdir -p hdfs://master:9000/tmp/hive
      hdfs dfs -mkdir -p hdfs://master:9000/user/hive/warehouse
      hiveserver2\
        --hiveconf hive.metastore.schema.verification=false\
        --hiveconf metastore.metastore.event.db.notification.api.auth=false\
        --hiveconf hive.server2.enable.doAs=false\
        --hiveconf fs.defaultFS=hdfs://master:9000/\
        --hiveconf hive.log.explain.output=true\
        --hiveconf hive.metastore.uris=thrift://localhost:9083
    '';
    after = [ "hdfs-namenode.service" "metastore.service" ];
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
