_: {
  disko = {
    memSize = "64GB";
    devices = {
      disk = {
        main = {
          device = "/dev/disk/by-id/ata-ST2000DM001-1ER164_S4Z0JCGG";
          #device = "/dev/sda";
          type = "disk";
          imageSize = "32G";
          content = {
            type = "gpt";
            partitions = {
              boot = {
                name = "ESP";
                size = "500M";
                type = "EF00";
                content = {
                  type = "filesystem";
                  format = "vfat";
                  mountpoint = "/boot";
                  mountOptions = ["umask=0077"];
                };
              };
              root = {
                name = "root";
                size = "100%";
                content = {
                  type = "lvm_pv";
                  vg = "pool";
                };
              };
            };
          };
        };
        mini = {
          device = "/dev/disk/by-id/ata-WDC_WD10EZEX-08M2NA0_WD-WMC3F1533317";
          #device = "/dev/sdb/";
          type = "disk";
          imageSize = "32G";
          content = {
            type = "gpt";
            partitions = {
              root = {
                name = "root";
                size = "100%";
                content = {
                  type = "lvm_pv";
                  vg = "pool";
                };
              };
            };
          };
        };
      };
      lvm_vg = {
        pool = {
          type = "lvm_vg";
          lvs = {
            #           swap = {
            #             size = "8G";
            #             content = {
            #               type = "swap";
            #               discardPolicy = "both";
            #               resumeDevice = true;
            #             };
            #           };
            root = {
              size = "100%FREE";
              content = {
                type = "filesystem";
                format = "ext4";
                mountpoint = "/";
                mountOptions = [
                  "defaults"
                ];
              };
            };
          };
        };
      };
    };
  };
}
