{ pkgs, ... }:
pkgs.stdenv.mkDerivation rec {
  pname = "tpcds-kit";
  version = "unstable-2019-06-14";
  src = pkgs.fetchFromGitHub {
    owner = "gregrahn";
    repo = pname;
    rev = "9d01e73403c32d8e3d89a987d096b98cbfae3c62";
    sha256 = "0l1jn2k4n9cyvf3i4bjkirqpz77d42jv13yzwg34rwlzckrvybx5";
  };
  preBuild = "cd tools";
  buildInputs = with pkgs; [ bison byacc (pkgs.writeScriptBin "lex" "exec ${flex}/bin/flex $@") ];
  hardeningDisable = [ "all" ];
  
  installPhase = ''
    mkdir -p $out/bin
    cp dsdgen dsqgen distcomp mkheader checksum $out/bin;
        
  '';
  
}