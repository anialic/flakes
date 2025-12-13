{ lib, ... }:
{
  modules.base = {
    options.logind = {
      handlePowerKey = lib.mkOption {
        type = lib.types.str;
        default = "suspend";
      };
      handleLidSwitch = lib.mkOption {
        type = lib.types.str;
        default = "sleep";
      };
    };

    module =
      { node, ... }:
      {
        services.logind.settings.Login = {
          HandlePowerKey = node.base.logind.handlePowerKey;
          HandleLidSwitch = node.base.logind.handleLidSwitch;
        };
      };
  };
}
