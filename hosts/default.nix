{ ... }:
{
  my.hosts = {
    maeriberry = import ./maeriberry.nix;
    maeriberry-loaner-wsl = import ./maeriberry-loaner-wsl.nix;
    usami = import ./usami.nix;
  };
}
