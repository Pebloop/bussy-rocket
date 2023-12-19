let
  nixpkgs = fetchTarball "https://github.com/NixOS/nixpkgs/tarball/nixos-23.11";
  pkgs = import nixpkgs { config = {}; overlays = []; };
  frameworks = pkgs.darwin.apple_sdk.frameworks;
  chipmunk = pkgs.stdenv.mkDerivation rec {
    pname = "chipmunk";
    majorVersion = "7";
    version = "${majorVersion}.0.3";

    src = pkgs.fetchurl {
      url = "https://chipmunk-physics.net/release/Chipmunk-${majorVersion}.x/Chipmunk-${version}.tgz";
      sha256 = "06j9cfxsyrrnyvl7hsf55ac5mgff939mmijliampphlizyg0r2q4";
    };

    patches = [
      (pkgs.fetchpatch {
        url = "https://github.com/slembcke/Chipmunk2D/commit/9a051e6fb970c7afe09ce2d564c163b81df050a8.patch";
        sha256 = "0ps8bjba1k544vcdx5w0qk7gcjq94yfigxf67j50s63yf70k2n70";
      })
    ];

    nativeBuildInputs = [ pkgs.cmake ]
      ++ pkgs.lib.optionals pkgs.stdenv.isDarwin [
        pkgs.darwin.apple_sdk.frameworks.Cocoa
      ];

    cmakeFlags = [
      "-DBUILD_DEMOS=OFF"
    ];

    meta = with pkgs.lib; {
      description = "A fast and lightweight 2D game physics library";
      homepage = "http://chipmunk2d.net/";
      license = licenses.mit;
      platforms = platforms.all;
    };
  };
in
pkgs.mkShell {
  packages = with pkgs; [
      zig
      chipmunk
      SDL2
      SDL2_ttf
      SDL2_mixer
      SDL2_image
      iconv
    ]
    ++ pkgs.lib.optionals pkgs.stdenv.isDarwin (with pkgs.darwin.apple_sdk.frameworks; [
      QuartzCore
      CoreAudio
      Metal
      ForceFeedback
      CoreHaptics
      Carbon
      GameController
      Cocoa
      IOKit
      AudioToolbox
    ]);
}
