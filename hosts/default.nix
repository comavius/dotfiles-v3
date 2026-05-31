{ ... }:
{
  my.hosts = {
    maeriberry = import ./maeriberry.nix;
    usami = import ./usami.nix;
  };
}
