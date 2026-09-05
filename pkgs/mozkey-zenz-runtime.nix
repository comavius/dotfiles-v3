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
# https://github.com/NixOS/nixpkgs/blob/e73de5be04e0eff4190a1432b946d469c794e7b4/pkgs/by-name/ll/llama-cpp/package.nix
# Runtime contract:
# https://github.com/koyasi777/mozkey/blob/20645e5cecd685f9b322a45f6b4f8e2a6c2cb011/src/mac/installer/zenz_runtime/README.md
{
  cmake,
  fetchFromGitHub,
  fetchurl,
  lib,
  ninja,
  stdenv,
  stdenvNoCC,
}:

let
  llamaCppVersion = "b10268";

  tokenizerPatch = fetchurl {
    url = "https://raw.githubusercontent.com/koyasi777/mozkey/20645e5cecd685f9b322a45f6b4f8e2a6c2cb011/src/mac/installer/zenz_runtime/patches/llama-vocab-gpt2-small-japanese-char.patch";
    hash = "sha256-bbXBGy2oQV1rNyAOxqpPP9zd6O+x56cTdf4zGnsOgpo=";
  };

  llamaServer = stdenv.mkDerivation {
    pname = "mozkey-llama-server";
    version = llamaCppVersion;

    src = fetchFromGitHub {
      owner = "ggml-org";
      repo = "llama.cpp";
      rev = "6b5224cfccdb9caf4c0a0a87692fddad22c7e969";
      hash = "sha256-Mb0SQZ2DtEEQmZuol2B50gokKr/gY4TNcJ9yjggP2r4=";
    };

    patches = [ tokenizerPatch ];

    nativeBuildInputs = [
      cmake
      ninja
    ];

    cmakeFlags = [
      (lib.cmakeBool "BUILD_SHARED_LIBS" false)
      (lib.cmakeBool "GGML_BLAS" false)
      (lib.cmakeBool "GGML_CCACHE" false)
      (lib.cmakeBool "GGML_CPU_KLEIDIAI" false)
      (lib.cmakeBool "GGML_NATIVE" false)
      (lib.cmakeBool "GGML_OPENMP" false)
      (lib.cmakeBool "LLAMA_BUILD_COMMON" true)
      (lib.cmakeBool "LLAMA_BUILD_EXAMPLES" false)
      (lib.cmakeBool "LLAMA_BUILD_SERVER" true)
      (lib.cmakeBool "LLAMA_BUILD_TESTS" false)
      (lib.cmakeBool "LLAMA_BUILD_UI" false)
      (lib.cmakeBool "LLAMA_LLGUIDANCE" false)
      (lib.cmakeBool "LLAMA_OPENSSL" false)
      (lib.cmakeBool "LLAMA_SUBPROCESS" true)
      (lib.cmakeBool "LLAMA_USE_PREBUILT_UI" false)
    ];

    buildTargets = [ "llama-server" ];

    installPhase = ''
      runHook preInstall

      install -Dm555 bin/llama-server "$out/bin/llama-server"
      install -Dm444 ../LICENSE "$out/share/licenses/llama.cpp/LICENSE"

      runHook postInstall
    '';

    meta = {
      description = "Pinned llama.cpp server for Mozkey Zenz correction";
      homepage = "https://github.com/ggml-org/llama.cpp";
      license = lib.licenses.mit;
      mainProgram = "llama-server";
      platforms = lib.platforms.linux;
    };
  };

  model = fetchurl {
    name = "zenz-v3.2-small-Q5_K_M.gguf";
    url = "https://huggingface.co/Miwa-Keita/zenz-v3.2-small-gguf/resolve/c67e03e07d215c869f591b274c1631170d3e11fe/ggml-model-Q5_K_M.gguf";
    hash = "sha256-KcIj1MIzJ7gP0T67WrJVUFekYxeZfV2jkVhP++8NtnM=";
  };
in
stdenvNoCC.mkDerivation {
  pname = "mozkey-zenz-runtime";
  version = "3.2-small";

  dontUnpack = true;

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/bin" "$out/models"
    ln -s ${llamaServer}/bin/llama-server "$out/bin/llama-server"
    ln -s ${model} "$out/models/zenz-v3.2-small-Q5_K_M.gguf"

    runHook postInstall
  '';

  passthru = {
    inherit llamaServer model;
  };

  meta = {
    description = "Local llama.cpp runtime and Zenzai model for Mozkey";
    homepage = "https://github.com/koyasi777/mozkey";
    license = [
      lib.licenses.mit
      lib.licenses.asl20
    ];
    platforms = lib.platforms.linux;
  };
}
