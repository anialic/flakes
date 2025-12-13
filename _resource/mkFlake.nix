{
  nixpkgs,
  src,
  args ? { },
  exclude ?
    { name, ... }:
    let
      c = builtins.substring 0 1 name;
    in
    c == "_" || c == "." || name == "flake.nix",
}:
let
  inherit (nixpkgs) lib;

  scan =
    dir:
    lib.concatLists (
      lib.mapAttrsToList (
        name: type:
        let
          path = dir + "/${name}";
          relPath = lib.removePrefix (toString src + "/") (toString path);
        in
        if exclude { inherit name path relPath; } then
          [ ]
        else if type == "directory" then
          scan path
        else if type == "regular" && lib.hasSuffix ".nix" name then
          [ path ]
        else
          [ ]
      ) (builtins.readDir dir)
    );

  optionsType = lib.mkOptionType {
    name = "deepMergeAttrs";
    check = builtins.isAttrs;
    merge = _: defs: lib.foldl' lib.recursiveUpdate { } (builtins.map (d: d.value) defs);
  };

  modulesType = lib.mkOptionType {
    name = "deferredModules";
    check = x: builtins.isList x || builtins.isFunction x || builtins.isAttrs x;
    merge = _: defs: lib.concatMap (d: lib.toList d.value) defs;
  };

  coreModule =
    { config, ... }:
    let
      moduleEntries = lib.mapAttrsToList (
        name: spec:
        assert !(spec.options ? enable) || throw "rshy: module '${name}' cannot define 'enable'";
        {
          inherit name;
          inherit (spec) target options module;
        }
      ) config.modules;

      nodeOptions = lib.foldl' lib.recursiveUpdate { } (
        builtins.map (m: {
          ${m.name} = {
            enable = lib.mkEnableOption "module ${m.name}";
          }
          // m.options;
        }) moduleEntries
      );

      nodeType = lib.types.submodule {
        freeformType = lib.types.attrsOf lib.types.raw;
        options = {
          system = lib.mkOption { type = lib.types.str; };
          target = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
          };
          extraModules = lib.mkOption {
            type = lib.types.listOf lib.types.deferredModule;
            default = [ ];
          };
          instantiate = lib.mkOption {
            type = lib.types.nullOr lib.types.raw;
            default = null;
          };
        }
        // nodeOptions;
      };

      inferTarget = system: if lib.hasSuffix "-darwin" system then "darwin" else "nixos";

      getTarget = node: if node.target != null then node.target else inferTarget node.system;

      cleanNode =
        name: node:
        let
          reserved = [
            "system"
            "target"
            "extraModules"
            "instantiate"
          ];
        in
        removeAttrs node reserved
        // {
          _name = name;
          _system = node.system;
          _target = getTarget node;
        };

      allNodes = lib.mapAttrs cleanNode config.nodes;

      hasOptionsSet =
        modName: node:
        let
          go =
            depth: o:
            if o == null || o ? _type then
              o.isDefined or false
            else if builtins.isAttrs o then
              builtins.any (k: (depth != 0 || k != "enable") && go (depth + 1) o.${k}) (builtins.attrNames o)
            else
              false;
        in
        go 0 (node.${modName} or null);

      checkNode =
        name: node:
        let
          target = getTarget node;
        in
        lib.optional (!(config.targets ? ${target})) "${name}: target '${target}' not defined"
        ++ lib.concatMap (
          m:
          let
            enabled = node.${m.name}.enable or false;
            hasOpts = hasOptionsSet m.name node;
            targetOk = m.target == null || m.target == target;
          in
          lib.optional (hasOpts && !enabled) "${name}: ${m.name}.* set but ${m.name}.enable = false"
          ++ lib.optional (
            enabled && !targetOk
          ) "${name}: ${m.name} requires target '${m.target}', got '${target}'"
        ) moduleEntries;

      mkNode =
        name:
        let
          node = config.nodes.${name};
          target = getTarget node;
          errors = checkNode name node;
          activeModules = builtins.filter (
            m: m.module != [ ] && node.${m.name}.enable or false && (m.target == null || m.target == target)
          ) moduleEntries;
          specialArgs = {
            inherit name;
            inherit (node) system;
            pkgs = nixpkgs.legacyPackages.${node.system};
            node = allNodes.${name};
            nodes = allNodes;
          }
          // args;
          instantiate =
            if node.instantiate != null then node.instantiate else config.targets.${target}.instantiate;
        in
        assert errors == [ ] || throw ("rshy:\n" + lib.concatMapStringsSep "\n" (e: "  - ${e}") errors);
        instantiate {
          inherit (node) system;
          inherit specialArgs;
          modules = lib.concatMap (m: m.module) activeModules ++ node.extraModules;
        };

      nodesByTarget = builtins.groupBy (n: getTarget config.nodes.${n}) (builtins.attrNames config.nodes);

      targetOutputs = lib.mapAttrs' (
        target: def: lib.nameValuePair def.output (lib.genAttrs (nodesByTarget.${target} or [ ]) mkNode)
      ) config.targets;

      perSystemOutputs = [
        "packages"
        "devShells"
        "apps"
        "checks"
        "legacyPackages"
      ];

      perSystemFor =
        system:
        config.perSystem {
          inherit system;
          pkgs = nixpkgs.legacyPackages.${system};
        };

      expandPerSystem =
        output:
        lib.filterAttrs (_: v: v != { }) (
          lib.genAttrs config.systems (system: (perSystemFor system).${output} or { })
        );

      formatter = lib.genAttrs config.systems (
        system: (perSystemFor system).formatter or nixpkgs.legacyPackages.${system}.nixfmt-rfc-style
      );
    in
    {
      options = {
        systems = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [
            "x86_64-linux"
            "aarch64-linux"
            "aarch64-darwin"
            "x86_64-darwin"
          ];
        };

        modules = lib.mkOption {
          type = lib.types.attrsOf (
            lib.types.submodule {
              options = {
                target = lib.mkOption {
                  type = lib.types.nullOr lib.types.str;
                  default = null;
                };
                options = lib.mkOption {
                  type = optionsType;
                  default = { };
                };
                module = lib.mkOption {
                  type = modulesType;
                  default = [ ];
                };
              };
            }
          );
          default = { };
        };

        targets = lib.mkOption {
          type = lib.types.attrsOf (
            lib.types.submodule {
              options = {
                instantiate = lib.mkOption { type = lib.types.raw; };
                output = lib.mkOption { type = lib.types.str; };
              };
            }
          );
          default = { };
        };

        nodes = lib.mkOption {
          type = lib.types.attrsOf nodeType;
          default = { };
        };

        perSystem = lib.mkOption {
          type = lib.types.functionTo (lib.types.lazyAttrsOf lib.types.raw);
          default = _: { };
        };

        flake = lib.mkOption {
          type = lib.types.submoduleWith {
            modules = [ { freeformType = lib.types.lazyAttrsOf lib.types.raw; } ];
          };
          default = { };
        };
      };

      config = {
        targets.nixos = {
          instantiate =
            {
              system,
              modules,
              specialArgs,
            }:
            lib.nixosSystem { inherit system modules specialArgs; };
          output = "nixosConfigurations";
        };

        flake =
          lib.mapAttrs (_: lib.mkDefault) targetOutputs
          // {
            formatter = lib.mkDefault formatter;
          }
          // lib.genAttrs perSystemOutputs (o: lib.mkDefault (expandPerSystem o));
      };
    };

  pkgsFor = system: nixpkgs.legacyPackages.${system};

  evaluated = lib.evalModules {
    modules = builtins.map import (scan src) ++ [ coreModule ];
    specialArgs = {
      inherit lib nixpkgs pkgsFor;
    }
    // args;
  };
in
lib.filterAttrs (_: v: v != { }) evaluated.config.flake
