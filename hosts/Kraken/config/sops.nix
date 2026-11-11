{
  sops = {
    age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" "/etc/ssh/bangbox_ssh_host_ed25519_key"];
    secrets.homeassistantPrometheusToken = {
      sopsFile = ./homeassistant-prometheus-token.bin;
      format = "binary";
      owner = "prometheus";
      mode = "0400";
      restartUnits = [ "prometheus.service" ];
    };
  };
}
