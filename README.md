# NixOs Wallpaper Engine Plugin File
Nix file for working wallpaper engine plugin for plasma 6

## How to enable
To enable the plugin, simply add the file in the import section of the configuration.nix like this:
```nix
    imports = [
        ./hardware-configuration.nix
        ./wallpaper-engine-kde-plugin.nix
    ];
```
and enable it:
```nix
    nixos.pkgs = {
        wallpaper-engine-kde-plugin.enable = true;
    };
```
