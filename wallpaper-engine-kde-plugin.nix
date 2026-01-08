{ config, lib, pkgs, ...}:

let

nixos-25-05 = import (builtins.fetchTarball {
    url = "https://github.com/NixOS/nixpkgs/archive/nixos-25.05.tar.gz";
}) { config = {}; };

wallpaper-engine-kde-plugin = with pkgs; stdenv.mkDerivation rec {
    pname = "wallpaperEngineKde";
    version = "4916944f3190c479d949cc58db196a1cf6b5d331";
    src = fetchFromGitHub {
        owner = "prinzhoefte";
        repo = "wallpaper-engine-kde-plugin";
        rev = version;
        hash = "sha256-wXAqDb8l0Yz+JySyX5Vy5DggH7MvKy/AhHMfZaBHiIw=";
        fetchSubmodules = true;  
    };

    nativeBuildInputs = [
        cmake
        kdePackages.extra-cmake-modules
        pkg-config
        gst_all_1.gst-libav
        shaderc
        ninja
        (python3.withPackages (ps: with ps; [ websockets ]))
    ];

    buildInputs = [
        mpv
        libass
        lz4
        vulkan-headers
        vulkan-tools
        vulkan-loader
        eigen
        nixos-25-05.qt6.full
    ] ++ (with nixos-25-05.kdePackages; [
        qtbase
        kpackage
        kdeclarative
        libplasma
        qtwebsockets
        qtwebengine
        qtwebchannel
        qtmultimedia
        qtdeclarative
    ]) ++ [
        # Add .dev output for Qt private headers
        nixos-25-05.pkgs.qt6Packages.qtbase.dev
    ] ++ [
        (python3.withPackages (python-pkgs: [ python-pkgs.websockets ]))
    ];

    cmakeFlags = [ 
        "-DUSE_PLASMAPKG=OFF"
    ];
    
    # Add Qt private headers path
    NIX_CFLAGS_COMPILE = [
        "-Wno-error"
        "-Wno-sign-conversion"
        "-Wno-deprecated-declarations"
        "-I${pkgs.qt6Packages.qtbase.dev}/include/QtGui/${pkgs.qt6Packages.qtbase.version}/QtGui"
    ];

    dontWrapQtApps = true;

    postPatch = ''
        # Fix SPIRV-Reflect CMakeLists.txt to require CMake 3.5 instead of older version
        if [ -f src/backend_scene/third_party/SPIRV-Reflect/CMakeLists.txt ]; then
            sed -i 's/cmake_minimum_required(VERSION [0-9.]*)/cmake_minimum_required(VERSION 3.5)/' \
            src/backend_scene/third_party/SPIRV-Reflect/CMakeLists.txt
        fi
        
        # Fix missing <cstdint> include in glslang headers
        sed -i '1i#include <cstdint>' src/backend_scene/third_party/glslang/SPIRV/SpvBuilder.h
        sed -i '1i#include <cstdint>' src/backend_scene/third_party/glslang/glslang/Include/intermediate.h
    '';

    postInstall = ''
        chmod +x $out/share/plasma/wallpapers/com.github.catsout.wallpaperEngineKde/contents/pyext.py
        patchShebangs --build $out/share/plasma/wallpapers/com.github.catsout.wallpaperEngineKde/contents/pyext.py
    '';

    #Optional informations
    meta = with lib; {
        description = "Wallpaper Engine KDE plasma plugin";
        homepage = "https://github.com/Jelgnum/wallpaper-engine-kde-plugin";
        license = licenses.gpl2Plus;
        platforms = platforms.linux;
    };
};
in 
{
    options.nixos = {
        pkgs.wallpaper-engine-kde-plugin = {
            enable = lib.mkOption {
                type = lib.types.bool;
                default = false;
                example = true;
                description = "Enable wallpaper-engine-kde-plugin.";
            };
        };
    };

    config = lib.mkIf (config.nixos.pkgs.wallpaper-engine-kde-plugin.enable) {
        environment.systemPackages = with pkgs; [
            wallpaper-engine-kde-plugin
            kdePackages.qtwebsockets
            kdePackages.qtwebchannel
            kdePackages.qtwebengine
            kdePackages.qtmultimedia
            (python3.withPackages (python-pkgs: [ python-pkgs.websockets ]))
        ];

        environment.sessionVariables = {
            PYTHONPATH = "${pkgs.python3.withPackages (p: [ p.websockets ])}/${pkgs.python3.sitePackages}:$PYTHONPATH";
        };

        system.activationScripts = {
            wallpaper-engine-kde-plugin.text = ''
                wallpaperenginetarget=share/plasma/wallpapers/com.github.catsout.wallpaperEngineKde
                mkdir -p /usr/share/plasma/wallpapers/
                if [ -e /usr/$wallpaperenginetarget ] ; then
                    unlink /usr/$wallpaperenginetarget
                fi
                ln -s ${wallpaper-engine-kde-plugin}/$wallpaperenginetarget /usr/$wallpaperenginetarget
            '';
        };
    };
}
