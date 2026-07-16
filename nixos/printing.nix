{
  config,
  lib,
  pkgs,
  ...
}:
let
  username = config.my.username;
  isMaeriberry = config.my.hostname == "maeriberry";
  ghostscriptCapt = pkgs.ghostscript.overrideAttrs (previousAttrs: {
    patches = (previousAttrs.patches or [ ]) ++ [ ../pkgs/ghostscript-opvp-string.patch ];
  });
  canonCapt = pkgs.callPackage ../pkgs/canon-capt.nix {
    ghostscript = ghostscriptCapt;
  };
in
{
  services.printing = {
    enable = true;
    browsing = true;
    openFirewall = true;
    webInterface = true;
    drivers =
      (with pkgs; [
        gutenprint
        hplip
      ])
      ++ lib.optional isMaeriberry canonCapt;
  };

  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
  };

  users.users."${username}".extraGroups = [ "lpadmin" ];

  environment.systemPackages =
    (with pkgs; [
      cups
      system-config-printer
    ])
    ++ lib.optional isMaeriberry canonCapt;

  boot = lib.mkIf isMaeriberry {
    # The CAPT daemon talks to /dev/usb/lp*, unlike modern CUPS' libusb
    # backend.  services.printing blacklists usblp by default.
    blacklistedKernelModules = lib.mkForce [ ];
    kernelModules = [ "usblp" ];
  };

  services.udev.extraRules = lib.mkIf isMaeriberry ''
    SUBSYSTEM=="usbmisc", KERNEL=="lp[0-9]*", ATTRS{idVendor}=="04a9", ATTRS{idProduct}=="26ea", GROUP="lp", MODE="0660", SYMLINK+="usb/lbp9100c", TAG+="systemd", ENV{SYSTEMD_WANTS}+="ccpd.service"
  '';

  environment.etc = lib.mkIf isMaeriberry {
    "ccpd.conf".text = ''
      <Path>
      CUPS_ConfigPath /etc/cups/
      LogDirectoryPath /var/log/CCPD/
      </Path>

      <Printer LBP9100C>
      DevicePath /dev/usb/lbp9100c
      </Printer>

      <Ports>
      UI_Port 59787
      PDATA_Port 59687
      </Ports>
    '';
  };

  # CAPT 2.71 predates NixOS and contains several absolute /usr paths.
  systemd.tmpfiles.rules = lib.mkIf isMaeriberry [
    "d /var/log/CCPD 0755 root root -"
    "d /usr/lib 0755 root root -"
    "L+ /usr/bin/c3pldrv - - - - ${canonCapt}/bin/c3pldrv"
    "L+ /usr/bin/captdrv - - - - ${canonCapt}/bin/captdrv"
    "L+ /usr/bin/captfilter - - - - ${canonCapt}/bin/captfilter"
    "L+ /usr/bin/ccpd - - - - ${canonCapt}/bin/ccpd"
    "L+ /usr/lib/libc3pl.so - - - - ${canonCapt}/usr/lib/libc3pl.so"
    "L+ /usr/share/caepcm - - - - ${canonCapt}/usr/share/caepcm"
    "L+ /usr/share/captfilter - - - - ${canonCapt}/usr/share/captfilter"
    "L+ /usr/share/ccpd - - - - ${canonCapt}/usr/share/ccpd"
  ];

  systemd.services = lib.mkIf isMaeriberry {
    ensure-lbp9100c = {
      description = "Ensure the Canon LBP9100C CUPS queue";
      wantedBy = [ "multi-user.target" ];
      requires = [ "cups.service" ];
      after = [ "cups.service" ];
      before = [ "ccpd.service" ];

      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };

      script = ''
        ${pkgs.cups}/bin/lpadmin \
          -p LBP9100C \
          -P ${canonCapt}/share/cups/model/CNCUPSLBP9100CCAPTJ.ppd \
          -v ccp://localhost:59687 \
          -D "Canon LBP9100C CAPT" \
          -L "maeriberry USB" \
          -o PageSize=A4 \
          -E
        ${pkgs.cups}/bin/lpadmin -d LBP9100C
      '';
    };

    ccpd = {
      description = "Canon CAPT printer daemon";
      wantedBy = [ "multi-user.target" ];
      requires = [ "ensure-lbp9100c.service" ];
      after = [
        "ensure-lbp9100c.service"
        "systemd-modules-load.service"
      ];

      preStart = ''
        ${pkgs.kmod}/bin/modprobe usblp
        ${pkgs.systemd}/bin/udevadm settle

        attempt=0
        while [ ! -e /dev/usb/lbp9100c ] && [ "$attempt" -lt 50 ]; do
          attempt=$((attempt + 1))
          ${pkgs.coreutils}/bin/sleep 0.1
        done

        if [ ! -e /dev/usb/lbp9100c ]; then
          echo "Canon LBP9100C device node was not created" >&2
          exit 1
        fi
      '';

      serviceConfig = {
        Type = "forking";
        ExecStart = "${canonCapt}/bin/ccpd";
        Restart = "on-failure";
        RestartSec = "10s";
        TimeoutStopSec = "10s";
      };
    };
  };
}
