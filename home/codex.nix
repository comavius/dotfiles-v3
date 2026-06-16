{ pkgs, ... }:
let
  codexBin = "%h/.codex/packages/standalone/current/codex";
in
{
  home.file.".codex/packages/standalone/current/codex" = {
    source = "${pkgs.codex}/bin/codex";
    executable = true;
  };

  systemd.user.services.codex-remote-control = {
    Unit.Description = "Codex remote control";
    Service = {
      Type = "oneshot";
      ExecStart = "${codexBin} remote-control start";
      ExecStop = "${codexBin} remote-control stop";
      RemainAfterExit = true;
    };
    Install.WantedBy = [ "default.target" ];
  };
}
