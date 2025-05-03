{ lib, ... }:
{
  services.tlp = {
    enable = true;
    settings = {
      RUNTIME_PM_ON_AC="auto";
      AHCI_RUNTIME_PM_ON_AC="on";
      SATA_LINKPWR_ON_AC="med_power_with_dipm";
      USB_AUTOSUSPEND=1;
      USB_EXCLUDE_AUDIO=0;
      USB_EXCLUDE_PRINTER=0;
    };
  };
}
