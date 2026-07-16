{
  lib,
  stdenv,
  fetchurl,
  rpmextract,
  file,
  patchelf,
  cups,
  ghostscript,
  glibc,
  libxml2_13,
  zlib,
  gtk2,
  glib,
  gdk-pixbuf,
  at-spi2-core,
  popt,
  gnome2,
  pkgsi686Linux,
}:

let
  runtimeLibraries64 = [
    glibc
    stdenv.cc.cc.lib
    cups.lib
    libxml2_13
    zlib
    gtk2
    glib
    gdk-pixbuf
    at-spi2-core
    popt
    gnome2.libglade
  ];
  runtimeLibraries32 = [
    pkgsi686Linux.glibc
    pkgsi686Linux.stdenv.cc.cc.lib
    pkgsi686Linux.libxml2_13
    pkgsi686Linux.popt
  ];
in
stdenv.mkDerivation (finalAttrs: {
  pname = "canon-capt";
  version = "2.71";

  src = fetchurl {
    url = "https://gdlp01.c-wss.com/gds/7/0100003447/08/linux-capt-drv-v271-jp.tar.gz";
    hash = "sha256-X0P3RhIBi1ehZu5vaL81aURt9Lr0cKegLNxRP5aQyj0=";
  };

  sourceRoot = "linux-capt-drv-v271-jp";

  nativeBuildInputs = [
    file
    patchelf
    rpmextract
  ];

  dontBuild = true;
  dontFixup = true;

  installPhase = ''
    runHook preInstall

    sourceDirectory=$PWD
    mkdir -p "$out"
    cd "$out"
    rpmextract "$sourceDirectory/64-bit_Driver/RPM/cndrvcups-common-3.21-1.x86_64.rpm"
    rpmextract "$sourceDirectory/64-bit_Driver/RPM/cndrvcups-capt-2.71-1.x86_64.rpm"

    # Canon's prebuilt filter executes /usr/bin/gs.  Rebuild this small
    # open-source component with Ghostscript's immutable Nix store path.  Its
    # job metadata must keep Canon's original numeric Resolution value even
    # though modern CUPS requires a PPD choice such as "600dpi".
    mkdir -p "$TMPDIR/capt-source"
    tar -xzf "$sourceDirectory/Src/cndrvcups-capt-2.71-1.tar.gz" \
      -C "$TMPDIR/capt-source"
    filterSource="$TMPDIR/capt-source/cndrvcups-capt-2.71/pstocapt3/filter"
    patch -d "$filterSource" -p1 < ${./canon-pstocapt3-resolution.patch}
    $CC \
      -DPROG_PATH='"${ghostscript}/bin"' \
      -I"$out/usr/include" \
      -I${cups.dev}/include \
      -O2 -Wall -fPIC \
      "$filterSource/pstocapt3.c" \
      "$filterSource/paramlist.c" \
      "$out/usr/lib64/libbuftool.a" \
      -L${cups.lib}/lib -lcups \
      -o "$out/usr/lib64/cups/filter/pstocapt3"

    mkdir -p "$out"/{bin,lib/cups/{backend,filter},share/cups/model,rpm,src,doc}
    for binary in "$out"/usr/bin/* "$out"/usr/sbin/* "$out"/usr/local/bin/*; do
      ln -s "$binary" "$out/bin/$(basename "$binary")"
    done
    for backend in "$out"/usr/lib64/cups/backend/*; do
      ln -s "$backend" "$out/lib/cups/backend/$(basename "$backend")"
    done
    for filter in "$out"/usr/lib64/cups/filter/*; do
      ln -s "$filter" "$out/lib/cups/filter/$(basename "$filter")"
    done
    for ppd in "$out"/usr/share/cups/model/*; do
      ln -s "$ppd" "$out/share/cups/model/$(basename "$ppd")"
    done

    substituteInPlace "$out/usr/share/cups/model/CNCUPSLBP9100CCAPTJ.ppd" \
      --replace-fail '*ModelName: "Canon LBP9100C CAPT (JP)"' '*ModelName: "Canon LBP9100C CAPT JP"' \
      --replace-fail '*DefaultResolution: 600' '*DefaultResolution: 600dpi' \
      --replace-fail '*Resolution 600/600 dpi:' '*Resolution 600dpi/600 dpi:' \
      --replace-fail '*opvpDriver: "libcanonc3pl.so"' "*opvpDriver: \"$out/usr/lib64/libcanonc3pl.so\""

    cd "$sourceDirectory"
    cp -v 32-bit_Driver/RPM/*.rpm "$out/rpm/"
    cp -v 64-bit_Driver/RPM/*.rpm "$out/rpm/"
    cp -v Src/*.tar.gz "$out/src/"
    cp -v Doc/* "$out/doc/"

    while IFS= read -r elf; do
      if ! patchelf --print-needed "$elf" >/dev/null 2>&1; then
        continue
      fi

      if file -b "$elf" | grep -q "ELF 32-bit"; then
        patchelf \
          --set-rpath "${lib.makeLibraryPath runtimeLibraries32}:$out/usr/lib" \
          "$elf"
        if patchelf --print-interpreter "$elf" >/dev/null 2>&1; then
          patchelf --set-interpreter ${pkgsi686Linux.glibc}/lib/ld-linux.so.2 "$elf"
        fi
      elif file -b "$elf" | grep -q "ELF 64-bit"; then
        patchelf \
          --set-rpath "${lib.makeLibraryPath runtimeLibraries64}:$out/usr/lib64:$out/usr/local/lib64" \
          "$elf"
        if patchelf --print-interpreter "$elf" >/dev/null 2>&1; then
          patchelf --set-interpreter ${glibc}/lib/ld-linux-x86-64.so.2 "$elf"
        fi
      fi
    done < <(find "$out" -type f)

    runHook postInstall
  '';

  meta = {
    description = "Canon CAPT printer driver for Linux";
    homepage = "https://canon.jp/support/software/os/select?pr=4873";
    license = lib.licenses.unfree;
    platforms = [ "x86_64-linux" ];
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
  };
})
