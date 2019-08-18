{ pkgs ? import <nixpkgs> {}, worker_ips? ["localhost"], ... }:
pkgs.hadoop_3_1.overrideAttrs (oldAttrs: {
  installPhase = builtins.replaceStrings ["HADOOP_PREFIX"] ["HADOOP_HOME"] oldAttrs.installPhase
  + ''
    echo "${pkgs.lib.concatStringsSep "\n" worker_ips}" > $out/etc/hadoop/workers
  '' ;
})
