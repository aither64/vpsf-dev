{
  description = "vpsf-dev node configurations";

  inputs = {
    vpsadminos.url = "git+file:///home/aither/workspace/vpsadmin/vpsadminos";
    vpsadmin.url = "git+file:///home/aither/workspace/vpsadmin/vpsadmin";
    nixpkgs.follows = "vpsadminos/nixpkgs";
  };

  outputs =
    {
      self,
      nixpkgs,
      vpsadminos,
      vpsadmin,
    }:
    let
      system = "x86_64-linux";
      lib = nixpkgs.lib;

      nodeNames =
        let
          entries = builtins.readDir ./nodes;
          nodeEntries = lib.filterAttrs (
            name: type:
            type == "regular"
            && lib.hasSuffix ".nix" name
            && !(builtins.elem name [
              "base.nix"
              "crashdump.nix"
            ])
          ) entries;
        in
        builtins.sort builtins.lessThan (
          map (name: lib.removeSuffix ".nix" name) (builtins.attrNames nodeEntries)
        );

      mkNodeConfiguration =
        node:
        let
          vpsadminNixosModule = vpsadmin.nixosModules.nixos-modules;
          vpsadminVpsadminosModule = vpsadmin.nixosModules.vpsadminos-modules;
        in
        vpsadminos.lib.vpsadminosSystem {
          inherit system;
          modules = [ (./nodes + "/${node}.nix") ];
          specialArgs = {
            inherit vpsadminNixosModule vpsadminVpsadminosModule;
            vpsadminosQemuModule = vpsadminos.outPath + "/os/configs/qemu.nix";
          };
        };

      nodeConfigurations = lib.genAttrs nodeNames mkNodeConfiguration;

      qemuPackages = lib.mapAttrs' (
        node: cfg: lib.nameValuePair "${node}-qemu" cfg.config.system.build.runvm
      ) nodeConfigurations;

      toplevelPackages = lib.mapAttrs' (
        node: cfg: lib.nameValuePair "${node}-toplevel" cfg.config.system.build.toplevel
      ) nodeConfigurations;

      nodeIps = lib.mapAttrs (_: cfg: cfg.config.networking.static.ip) nodeConfigurations;
    in
    {
      inherit nodeConfigurations nodeIps;

      packages.${system} = qemuPackages // toplevelPackages;
    };
}
