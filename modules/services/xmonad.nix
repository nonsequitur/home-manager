{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.xsession.windowManager.xmonad;

  xmonad = pkgs.xmonad-with-packages.override {
    ghcWithPackages = cfg.haskellPackages.ghcWithPackages;
    packages = self:
        cfg.extraPackages self
        ++ optionals cfg.enableContribAndExtras [
          self.xmonad-contrib self.xmonad-extras
        ];
  };

in

{
  options = {
    xsession.windowManager.xmonad = {
      enable = mkEnableOption "xmonad window manager";

      haskellPackages = mkOption {
        default = pkgs.haskellPackages;
        defaultText = "pkgs.haskellPackages";
        example = literalExample "pkgs.haskell.packages.ghc802";
        description = ''
          The <varname>haskellPackages</varname> used to build xmonad
          and other packages. This can be used to change the GHC
          version used to build xmonad and the packages listed in
          <varname>extraPackages</varname>.
        '';
      };

      extraPackages = mkOption {
        default = self: [];
        defaultText = "self: []";
        example = literalExample ''
          haskellPackages: [
            haskellPackages.xmonad-contrib
            haskellPackages.monad-logger
          ]
        '';
        description = ''
          Extra packages available to GHC when rebuilding xmonad. The
          value must be a function which receives the attribute set
          defined in <varname>haskellPackages</varname> as the sole
          argument.
        '';
      };

      enableContribAndExtras = mkOption {
        default = false;
        type = lib.types.bool;
        description = ''
          Enable xmonad-contrib and xmonad-extras in xmonad.
        '';
      };
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ xmonad ];
    xsession.windowManager.command = "${xmonad}/bin/xmonad";
  };
}
