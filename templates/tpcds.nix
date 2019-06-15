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
  buildInputs = with pkgs; [ makeWrapper bison byacc (pkgs.writeScriptBin "lex" "exec ${flex}/bin/flex $@") ];
  hardeningDisable = [ "all" ];
  
  installPhase = ''
    mkdir -p $out/bin
    cp -r dsdgen dsqgen distcomp mkheader checksum .ctags_updated $out/bin
    mkdir -p $out/share
    cp -r tpcds.idx ../query_templates $out/share
    
  '';

  postFixup = ''wrapProgram $out/bin/dsdgen --run "cd $out/share"
                wrapProgram $out/bin/dsqgen --add-flags "-directory query_templates" --run "cd $out/share"'';
}

