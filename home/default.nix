{
  pkgs,
  config,
  lib,
  ...
}:
let
  cfg = config.my;
  imageViewer = "org.gnome.Loupe.desktop";
  videoViewer = "org.gnome.Totem.desktop";
  imageMimeTypes = [
    "image/jpeg"
    "image/png"
    "image/gif"
    "image/webp"
    "image/tiff"
    "image/x-tga"
    "image/vnd-ms.dds"
    "image/x-dds"
    "image/bmp"
    "image/vnd.microsoft.icon"
    "image/vnd.radiance"
    "image/x-exr"
    "image/x-portable-bitmap"
    "image/x-portable-graymap"
    "image/x-portable-pixmap"
    "image/x-portable-anymap"
    "image/x-qoi"
    "image/qoi"
    "image/svg+xml"
    "image/svg+xml-compressed"
    "image/avif"
    "image/heic"
    "image/jxl"
  ];
  videoMimeTypes = [
    "application/mxf"
    "application/vnd.ms-asf"
    "application/vnd.rn-realmedia"
    "application/vnd.rn-realmedia-vbr"
    "application/x-flash-video"
    "application/x-matroska"
    "application/x-quicktimeplayer"
    "video/3gp"
    "video/3gpp"
    "video/3gpp2"
    "video/dv"
    "video/divx"
    "video/fli"
    "video/flv"
    "video/mp2t"
    "video/mp4"
    "video/mp4v-es"
    "video/mpeg"
    "video/mpeg-system"
    "video/msvideo"
    "video/ogg"
    "video/quicktime"
    "video/vnd.avi"
    "video/vnd.divx"
    "video/vnd.rn-realvideo"
    "video/webm"
    "video/x-anim"
    "video/x-avi"
    "video/x-flc"
    "video/x-fli"
    "video/x-flic"
    "video/x-flv"
    "video/x-m4v"
    "video/x-matroska"
    "video/x-mjpeg"
    "video/x-mpeg"
    "video/x-mpeg2"
    "video/x-ms-asf"
    "video/x-msvideo"
    "video/x-ms-wmv"
    "video/x-ogm+ogg"
    "video/x-theora"
    "video/x-theora+ogg"
  ];
  imageAssociations = lib.genAttrs imageMimeTypes (_: imageViewer);
  videoAssociations = lib.genAttrs videoMimeTypes (_: videoViewer);
  dotfilesRepositoryUpdater = pkgs.writeShellApplication {
    name = "dotfiles-repository-updater";
    runtimeInputs = [ pkgs.git ];
    text = ''
      repo=${lib.escapeShellArg cfg.dotfilesRepositoryPath}

      if ! git -C "$repo" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        exit 0
      fi

      git -C "$repo" fetch --prune origin "+refs/heads/*:refs/remotes/origin/*"
    '';
  };
in
{
  imports = [
    ./hyprland
    ./waybar
    ./zsh.nix
    ./fcitx.nix
  ];

  home = {
    username = cfg.username;
    homeDirectory = cfg.homeDirectory;
    stateVersion = cfg.stateVersion;
  };

  programs.home-manager.enable = true;

  systemd.user.services.dotfiles-repository-update = {
    Unit.Description = "Update local dotfiles repository refs";
    Service = {
      Type = "oneshot";
      ExecStart = "${dotfilesRepositoryUpdater}/bin/dotfiles-repository-updater";
    };
  };

  systemd.user.timers.dotfiles-repository-update = {
    Unit.Description = "Update local dotfiles repository refs periodically";
    Timer = {
      OnBootSec = "2min";
      OnUnitActiveSec = "10min";
      Persistent = true;
    };
    Install.WantedBy = [ "timers.target" ];
  };

  home.packages = with pkgs; [
    bottom
    gping
    dive
    fastfetch
    zellij
    firefox
    loupe
    nautilus
    totem
    nixd
    obs-studio
    libreoffice
    go
    go-tools
    clang-tools
    poppler-utils
    wl-clipboard
    vscode
    discord
    google-chrome
    (pkgs.callPackage ./../pkgs/sh4der-jockey.nix { })
    blender
    gimp
    unzip
    ffmpeg-full
    bubblewrap
  ];

  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "x-scheme-handler/http" = "firefox.desktop";
      "x-scheme-handler/https" = "firefox.desktop";
      "x-scheme-handler/chrome" = "firefox.desktop";
      "text/html" = "firefox.desktop";
      "application/x-extension-htm" = "firefox.desktop";
      "application/x-extension-html" = "firefox.desktop";
      "application/x-extension-shtml" = "firefox.desktop";
      "application/xhtml+xml" = "firefox.desktop";
      "application/x-extension-xhtml" = "firefox.desktop";
      "application/x-extension-xht" = "firefox.desktop";
      "x-scheme-handler/clash-nyanpasu" = "clash-nyanpasu-handler.desktop";
      "x-scheme-handler/clash" = "clash-nyanpasu-handler.desktop";
      "inode/directory" = "org.gnome.Nautilus.desktop";
    }
    // imageAssociations
    // videoAssociations;
    associations.added = {
      "x-scheme-handler/http" = "firefox.desktop";
      "x-scheme-handler/https" = "firefox.desktop";
      "x-scheme-handler/chrome" = "firefox.desktop";
      "text/html" = "firefox.desktop";
      "application/x-extension-htm" = "firefox.desktop";
      "application/x-extension-html" = "firefox.desktop";
      "application/x-extension-shtml" = "firefox.desktop";
      "application/xhtml+xml" = "firefox.desktop";
      "application/x-extension-xhtml" = "firefox.desktop";
      "application/x-extension-xht" = "firefox.desktop";
      "inode/directory" = "org.gnome.Nautilus.desktop";
    }
    // imageAssociations
    // videoAssociations;
  };

  xdg.configFile."mimeapps.list".force = true;
  xdg.dataFile."applications/mimeapps.list".force = true;
}
