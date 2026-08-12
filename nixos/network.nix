{ config, lib, ... }:

{
  services.tailscale = {
    enable = true;
    extraSetFlags = lib.optionals (config.my.hostname == "maeriberry") [ "--accept-routes=true" ];
  };
}
