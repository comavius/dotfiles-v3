/*
  Copyright (c) 2003-2026 Eelco Dolstra and the Nixpkgs/NixOS contributors

  Permission is hereby granted, free of charge, to any person obtaining
  a copy of this software and associated documentation files (the
  "Software"), to deal in the Software without restriction, including
  without limitation the rights to use, copy, modify, merge, publish,
  distribute, sublicense, and/or sell copies of the Software, and to
  permit persons to whom the Software is furnished to do so, subject to
  the following conditions:

  The above copyright notice and this permission notice shall be
  included in all copies or substantial portions of the Software.

  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
  MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
  LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
  OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
  WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/
# Adapted from:
# https://github.com/NixOS/nixpkgs/blob/e73de5be04e0eff4190a1432b946d469c794e7b4/pkgs/by-name/mo/mozc/package.nix
# https://github.com/NixOS/nixpkgs/blob/e73de5be04e0eff4190a1432b946d469c794e7b4/pkgs/by-name/fc/fcitx5-mozc/package.nix
{
  bazel_9,
  callPackage,
  fcitx5,
  fetchFromGitHub,
  gettext,
  lib,
  nixpkgs,
  pkg-config,
  python3,
  qt6,
  runCommand,
  stdenv,
  unzip,
  xdg-utils,
}:

let
  version = "0.7.7-unstable-2026-08-22";

  toolchainRuntimePath = lib.makeLibraryPath [
    stdenv.cc.cc.lib
    stdenv.cc.libc
  ];

  bazelPackage = callPackage "${nixpkgs}/pkgs/by-name/ba/bazel_9/build-support/bazelPackage.nix" { };

  mozkeySrc = fetchFromGitHub {
    owner = "koyasi777";
    repo = "mozkey";
    rev = "20645e5cecd685f9b322a45f6b4f8e2a6c2cb011";
    hash = "sha256-OjiqgxkzjSdGnEE9NEbZ/uCSMbU57C2OsQucHBfegC8=";
  };

  fcitxMozcSrc = fetchFromGitHub {
    owner = "fcitx";
    repo = "mozc";
    rev = "6b20c794f3112075703bae1603a81dce86b1f44e";
    hash = "sha256-Z0lZ1WSENvu+YIDb0gOmq4S84uI4GZvqZlb2UEz8pZM=";
  };

  bazelCentralRegistry = fetchFromGitHub {
    owner = "bazelbuild";
    repo = "bazel-central-registry";
    rev = "a5e087e21fcac28ff105ffc5eaeca966e61057af";
    hash = "sha256-X130OQnmmmj9zXTp2wMMGLrZssfrRJ0t9S9GHGOc6hQ=";
  };

  rulesPythonSrc = fetchFromGitHub {
    owner = "bazelbuild";
    repo = "rules_python";
    rev = "1.9.0";
    hash = "sha256-p1M3dqoNEiYfK9UEmJ8LQQeFe5EEo9ly/LF/XzHfm/E=";
  };

  patchedRulesPythonSrc = runCommand "rules-python-1.9.0-nix-shebang" { } ''
    cp -r ${rulesPythonSrc}/. "$out"
    chmod -R u+w "$out"

    substituteInPlace \
      "$out/python/private/py_runtime_info.bzl" \
      "$out/python/private/runtime_env_toolchain.bzl" \
      "$out/python/private/py_executable.bzl" \
      --replace-fail "/usr/bin/env python3" "${python3}/bin/python3"
  '';

  src = runCommand "mozkey-fcitx5-source" { } ''
    cp -r ${mozkeySrc}/. "$out"
    chmod -R u+w "$out"

    cp -r ${fcitxMozcSrc}/src/unix/fcitx5 "$out/src/unix/fcitx5"

    substituteInPlace "$out/src/MODULE.bazel" \
      --replace-fail \
        $'bazel_dep(\n    name = "rules_python",\n    version = "1.9.0",\n)' \
        $'bazel_dep(\n    name = "rules_python",\n    version = "1.9.0",\n)\nlocal_path_override(\n    module_name = "rules_python",\n    path = "${patchedRulesPythonSrc}",\n)'

    substituteInPlace "$out/src/MODULE.bazel" \
      --replace-fail \
        '# Qt for Linux' \
        $'# Local Python toolchain\nlocal_runtime_repo = use_repo_rule(\n    "@rules_python//python/local_toolchains:repos.bzl",\n    "local_runtime_repo",\n)\nlocal_runtime_toolchains_repo = use_repo_rule(\n    "@rules_python//python/local_toolchains:repos.bzl",\n    "local_runtime_toolchains_repo",\n)\nlocal_runtime_repo(\n    name = "nix_python3",\n    interpreter_path = "${python3}/bin/python3",\n    on_failure = "fail",\n    dev_dependency = True,\n)\nlocal_runtime_toolchains_repo(\n    name = "nix_python_toolchains",\n    runtimes = ["nix_python3"],\n    dev_dependency = True,\n)\nregister_toolchains("@nix_python_toolchains//:all", dev_dependency = True)\n\n# Fcitx 5\npkg_config_repository(\n    name = "fcitx5",\n    packages = [\n        "Fcitx5Core",\n        "Fcitx5Module",\n    ],\n)\n\n# Qt for Linux'
  '';

  package = bazelPackage {
    name = "mozkey-fcitx5-${version}";
    inherit
      src
      version
      ;
    registry = bazelCentralRegistry;
    sourceRoot = "mozkey-fcitx5-source/src";
    bazel = bazel_9;

    targets = [
      "//gui/tool:mozc_tool"
      "//renderer/qt:mozc_renderer"
      "//server:mozc_server"
      "//unix/fcitx5:fcitx5-mozc.so"
      "//unix:icons"
    ];

    commandArgs = [
      "--config=oss_linux"
      "--compilation_mode=opt"
    ];

    bazelRepoCacheFOD = {
      outputHash = "sha256-AJ6JrBDUgdA5PHV4aVTP8bzJfIfgiuDYwmXUKfC51ck=";
      outputHashAlgo = "sha256";
    };

    nativeBuildInputs = [
      gettext
      pkg-config
      python3
      qt6.wrapQtAppsHook
      unzip
    ];

    buildInputs = [
      fcitx5
      qt6.qtbase
    ];

    installPhase = ''
      runHook preInstall

      install -Dm555 bazel-bin/server/mozc_server "$out/lib/mozc/mozc_server"
      install -Dm555 bazel-bin/renderer/qt/mozc_renderer "$out/lib/mozc/mozc_renderer"
      install -Dm555 bazel-bin/gui/tool/mozc_tool "$out/lib/mozc/mozc_tool"

      install -Dm555 bazel-bin/unix/fcitx5/fcitx5-mozc.so "$out/lib/fcitx5/fcitx5-mozc.so"
      install -Dm444 unix/fcitx5/mozc-addon.conf "$out/share/fcitx5/addon/mozc.conf"
      install -Dm444 unix/fcitx5/mozc.conf "$out/share/fcitx5/inputmethod/mozc.conf"

      for pofile in unix/fcitx5/po/*.po; do
        filename=$(basename "$pofile")
        lang=''${filename/.po/}
        mofile=''${pofile/.po/.mo}
        msgfmt "$pofile" -o "$mofile"
        install -Dm444 "$mofile" "$out/share/locale/$lang/LC_MESSAGES/fcitx5-mozc.mo"
      done

      msgfmt --xml \
        -d unix/fcitx5/po/ \
        --template unix/fcitx5/org.fcitx.Fcitx5.Addon.Mozc.metainfo.xml.in \
        -o unix/fcitx5/org.fcitx.Fcitx5.Addon.Mozc.metainfo.xml
      install -Dm444 \
        unix/fcitx5/org.fcitx.Fcitx5.Addon.Mozc.metainfo.xml \
        "$out/share/metainfo/org.fcitx.Fcitx5.Addon.Mozc.metainfo.xml"

      install -d "$out/share/icons/mozc"
      unzip bazel-bin/unix/icons.zip -d "$out/share/icons/mozc"

      install -Dm444 \
        "$out/share/icons/mozc/mozc.png" \
        "$out/share/icons/hicolor/128x128/apps/org.fcitx.Fcitx5.fcitx_mozc.png"
      ln -s \
        org.fcitx.Fcitx5.fcitx_mozc.png \
        "$out/share/icons/hicolor/128x128/apps/fcitx_mozc.png"

      for svg in \
        alpha_full.svg \
        alpha_half.svg \
        direct.svg \
        hiragana.svg \
        katakana_full.svg \
        katakana_half.svg \
        outlined/dictionary.svg \
        outlined/properties.svg \
        outlined/tool.svg
      do
        icon_name=$(basename "$svg")
        icon_path="$out/share/icons/hicolor/scalable/apps"
        icon_prefix=org.fcitx.Fcitx5.fcitx_mozc

        install -Dm444 \
          "$out/share/icons/mozc/$svg" \
          "$icon_path/''${icon_prefix}_$icon_name"
        ln -s \
          "''${icon_prefix}_$icon_name" \
          "$icon_path/fcitx_mozc_$icon_name"
      done

      install -Dm444 ../LICENSE "$out/share/licenses/mozkey/LICENSE"

      runHook postInstall
    '';
  };
in
package.overrideAttrs (old: {
  postPatch = (old.postPatch or "") + ''
    patchShebangs .

    for flag in $NIX_CFLAGS_COMPILE $NIX_CXXSTDLIB_COMPILE; do
      echo "build --copt=$flag" >>.bazelrc
      echo "build --host_copt=$flag" >>.bazelrc
    done

    for flag in $NIX_LDFLAGS; do
      echo "build --linkopt=-Wl,$flag" >>.bazelrc
      echo "build --host_linkopt=-Wl,$flag" >>.bazelrc
    done

    echo "build --linkopt=-Wl,--dynamic-linker=${stdenv.cc.bintools.dynamicLinker}" >>.bazelrc
    echo "build --host_linkopt=-Wl,--dynamic-linker=${stdenv.cc.bintools.dynamicLinker}" >>.bazelrc
    echo "build --linkopt=-Wl,-rpath,${toolchainRuntimePath}" >>.bazelrc
    echo "build --host_linkopt=-Wl,-rpath,${toolchainRuntimePath}" >>.bazelrc

    substituteInPlace config.bzl \
      --replace-fail "/usr/bin/xdg-open" "${xdg-utils}/bin/xdg-open" \
      --replace-fail "/usr" "$out"
  '';

  meta = {
    description = "Mozkey Japanese input method with an Fcitx 5 frontend";
    homepage = "https://github.com/koyasi777/mozkey";
    license = lib.licenses.bsd3;
    platforms = lib.platforms.linux;
    maintainers = [ ];
  };
})
