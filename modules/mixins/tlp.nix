{ lib, ... }:
{
  services.tlp = {
    enable = true;
    settings = {
      RUNTIME_PM_ON_AC="auto";
      AHCI_RUNTIME_PM_ON_AC="on";
      SATA_LINKPWR_ON_AC="med_power_with_dipm";
    };
  };
}
