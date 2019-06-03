# NixOS module for gcespark
# Provisioned by Terraform

{ config, pkgs, lib, ... } :

let spark_221_patched = pkgs.stdenv.mkDerivation {
  name = "spark-2.2.1-patched";
  src = pkgs.spark;
  installPhase = ''
    mkdir $out
    sed -i '/PATH=/ s/$/:$PATH/' lib/spark-2.2.1-bin-without-hadoop/conf/spark-env.sh
    cp -r * $out
  '';
};
in
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
      export SPARK_MASTER_HOST=localhost
      export SPARK_LOG_DIR=/home/spark/logs
      export SPARK_NO_DAEMONIZE=true
      ${spark_221_patched}/lib/spark-2.2.1-bin-without-hadoop/sbin/start-master.sh
    '';
  };

}
