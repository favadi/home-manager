{ config, lib, pkgs, ... }:

with lib;

let

  dag = config.lib.dag;
  hmTypes = import ../../../modules/lib/types.nix { inherit dag lib; };

  result =
    let
      sorted = dag.topoSort config.tested.dag;
      data = map (e: "${e.name}:${e.data}") sorted.result;
    in
      concatStringsSep "\n" data + "\n";

in

{
  options.tested.dag = mkOption {
    type = with types; hmTypes.dagOf str;
  };

  config = {
    tested = mkMerge [
      { dag.after = dag.entryAnywhere "after"; }
      { dag.before = dag.entryBefore ["after"] "before"; }
      { dag.between = dag.entryBetween ["after"] ["before"] "between"; }
    ];

    home.file."result.txt".text = result;

    nmt.script = ''
      assertFileContent \
        home-files/result.txt \
        ${./dag-merge-result.txt}
    '';
  };
}
