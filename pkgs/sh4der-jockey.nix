{
  lib,
  rustPlatform,
  fetchFromGitHub,
  makeWrapper,
  pkg-config,
  alsa-lib,
  gtk3,
  ndi,
  libGL,
  libX11,
  libXcursor,
  libXi,
  libXrandr,
  libxcb,
  udev,
  wayland,
}:

rustPlatform.buildRustPackage rec {
  pname = "sh4der-jockey";
  version = "0.3.1";

  src = fetchFromGitHub {
    owner = "slerpyyy";
    repo = "sh4der-jockey";
    rev = "02eeda6b047a08c536599096aedf999239cac282";
    hash = "sha256-N22e914/begOH3eRPE+oOYh10TZWd/dkr9BIJ8Q01vk=";
  };

  cargoLock = {
    lockFile = "${src}/Cargo.lock";
    outputHashes = {
      "alloca-0.3.3" = "sha256-/MaUlbYuqLAOcbK/a4l/ijzWH00fMa9pKih2Sfhdlkg=";
      "imgui-0.7.0" = "sha256-do0vpOT7ySdmvwMP+H/64pKI+2/ZLCgyZ9L9FwfWoNs=";
      "imgui-opengl-renderer-0.11.0" = "sha256-PhcLNO0kzTcowYFjTELFNILUx7RgMF0WbHqWuVASTFU=";
      "imgui-sys-0.7.0" = "sha256-do0vpOT7ySdmvwMP+H/64pKI+2/ZLCgyZ9L9FwfWoNs=";
      "imgui-winit-support-0.7.1" = "sha256-do0vpOT7ySdmvwMP+H/64pKI+2/ZLCgyZ9L9FwfWoNs=";
      "ndi-0.1.1" = "sha256-NqGBlS52cmAg+P2Sx4oG8/AyDcDk9RpU+T3E6J/kp3Q=";
      "nfd-0.0.4" = "sha256-MnACubjW0tbTJpBHNRZSKvslG76J/qhadgJFGKrSNT0=";
    };
  };

  postPatch = ''
    substituteInPlace build.rs \
      --replace-fail "    vergen(Config::default())" "    println!(\"cargo:rustc-env=VERGEN_GIT_SHA=${src.rev}\");
    let mut config = Config::default();
    *config.git_mut().enabled_mut() = false;
    vergen(config)"
  '';

  nativeBuildInputs = [
    makeWrapper
    pkg-config
  ];

  buildInputs = [
    alsa-lib
    gtk3
    libGL
    libX11
    libXcursor
    libXi
    libXrandr
    libxcb
    udev
    wayland
  ];

  postInstall = ''
    ln -s ${ndi}/lib/libndi.so "$out/bin/libndi.so"
    ln -s ${ndi}/lib/libndi.so "$out/bin/libndi"

    wrapProgram "$out/bin/sh4der-jockey" \
      --prefix LD_LIBRARY_PATH : "${
        lib.makeLibraryPath [
          ndi
          libGL
          libX11
          libXcursor
          libXi
          libXrandr
        ]
      }" \
      --run 'if [ -n "''${DISPLAY:-}" ] && [ -z "''${WINIT_UNIX_BACKEND:-}" ]; then export WINIT_UNIX_BACKEND=x11; fi'
  '';

  meta = {
    description = "A tool for shader coding and live performances";
    homepage = "https://github.com/slerpyyy/sh4der-jockey";
    license = with lib.licenses; [
      asl20
      mit
    ];
    mainProgram = "sh4der-jockey";
    platforms = lib.platforms.linux;
  };
}
