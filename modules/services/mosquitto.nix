{ config, ... }:
let portNumber = 1883;
in {

  services.mosquitto = {
    enable = true;
    listeners = [{
      address = "mqtt.home2.garrettruffner.com";
      port = portNumber;
      users.root = {
        acl = [ "readwrite #" ];
        hashedPassword =
          ":$7$101$Ond+QX1drz3jScSM$i6JkyLONUv4dxa9SCgtjJ2ni7pJ90Sb2zxlMJeXZ/EPqVb76jzfhBUbdhZh8B2dGDflMjEoD+NLbv7TuZjVAjg==";
      };
      users.devices = {
        acl = [ "readwrite #" ];
        hashedPassword =
          "$7$101$jSp4dovxSYpeNftl$YaaJ86zSaqLB/Ggkaxwq6evbUPvSUsxKKGemqIDLrm23wxJ0TIC50a1sVIuJGH+casb8bGskKp+DwSVy31PHIA==";
      };

    }];
  };

  services.traefik-wrapper.service-definitions = builtins.listToAttrs [{
    name = "mqtt";
    value = { url = "http://127.0.0.1:${toString portNumber}"; };
  }];
}
