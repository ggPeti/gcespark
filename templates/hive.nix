{ stdenv, hivepackage, makeWrapper, ... }:
stdenv.mkDerivation { 
 name = "hiveWrapped"; 
 src = hivepackage; 
 buildInputs = [ makeWrapper ]; 
 phases = [ "installPhase" ]; 
 installPhase = ''cp -r ./ $out; wrapProgram $out/bin/hive --run "cd /home/hive/warehouse"''; 
}