# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  boot = {
    loader = {
      # Use the systemd-boot EFI boot loader.
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
    kernelParams = [ "intel_iommu=on" ];
    blacklistedKernelModules = [ "nvidia" "nouveau" ];
    kernelModules = [ "vfio_virqfd" "vfio_pci" "vfio_iommu_type1" "vfio" ];
    extraModprobeConfig = "options vfio-pci ids=8086:1901,10de:17c8,10de:0fb0";
  };

  networking = {
    hostName = "noir"; # Define your hostname.
    # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.
    networkmanager.enable = true;
    interfaces = {
      eth0 = {
        ipv4.addresses = []; # uses DHCP
      };
      eth1 = {
        ipv4.addresses = [{
          address = "192.168.2.100";
          prefixLength = 24;
        }];
        # no DNS necessary as this is a PTP link with static IP endpoints
      };
    };
  };

  fileSystems = {
    "/mnt/nas" = {
      device = "//192.168.2.1/DataVolume";
      fsType = "cifs";
      options = let
        automount_options = "x-systemd.automount,noauto,x-systemd.idle-timeout=60,x-systemd.device-timeout=5s,x-systemd.mount-timeout=5s";
      in ["${automount_options},credentials=/etc/nixos/smb-secrets"];
    };
  };

  virtualisation = {
    libvirtd = {
      enable = true;
      qemuOvmf = true; # true by default, but I would like to be reminded of its presence, until otherwise noted
    };
  };

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Select internationalisation properties.
  # i18n = {
  #   consoleFont = "Lat2-Terminus16";
  #   consoleKeyMap = "us";
  #   defaultLocale = "en_US.UTF-8";
  # };

  # Set your time zone.
  time.timeZone = "America/Kentucky/Louisville";

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    wget
    vim
    networkmanager
    git
    w3m

    usbutils
    pciutils
    virtmanager

    firefox
  ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = { enable = true; enableSSHSupport = true; };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # Enable CUPS to print documents.
  # services.printing.enable = true;

  # Enable sound.
  # sound.enable = true;
  # hardware.pulseaudio.enable = true;

  # Enable the X11 windowing system.
  # services.xserver.enable = true;
  # services.xserver.layout = "us";
  # services.xserver.xkbOptions = "eurosign:e";

  # Enable touchpad support.
  # services.xserver.libinput.enable = true;

  # Enable the KDE Desktop Environment.
  # services.xserver.displayManager.sddm.enable = true;
  # services.xserver.desktopManager.plasma5.enable = true;
  services = {
    ntp = { 
      enable = true; 
    };
    xserver = {
      enable = true;
      # autorun = false;
      layout = "us";
      displayManager = {
        sddm.enable = true;
      };
      desktopManager = {
        xterm.enable = false; # ...why?
        plasma5.enable = true;
      };
    };
    udev.extraRules = ''
    KERNEL=="eth*", ATTR{address}=="d0:50:99:98:1a:cf", NAME="eth0"
    KERNEL=="eth*", ATTR{address}=="d0:50:99:98:1a:cd", NAME="eth1"
    '';
  };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  # users.users.guest = {
  #   isNormalUser = true;
  #   uid = 1000;
  # };
  users = {
    mutableUsers = false;
    users.rob = {
      hashedPassword = "$6$DNPRqZfOcuCU8$5vZ6bbh.WyFywdjAcoXsXcygAg9aJ30G2Dbwe8Ap7f/vAij4KQKpzP0R0tJy9nDM4RlhBjPxIQ2R6FkSztqvp1";
      isNormalUser = true;
      home = "/home/rob";
      extraGroups = [ "wheel" "networkmanager" "libvirtd" ];
      uid = 1000;
      createHome = true;
      openssh.authorizedKeys.keys = [
        "ssh-rsa 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 rsa-key-20190103"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIENjSG7mFgxPXR088X02lmTcxqP3iW8elXA3/Wwdocw/ ed25519-key-20190103"
      ];
    };
  };

  programs = {
    tmux = {
      enable = true;
      baseIndex = 1;
      clock24 = true;
      newSession = true;
      secureSocket = true;
      extraTmuxConf = ''
        set -g renumber-windows on
        set -g status-position top
        set -g status-fg white
        set -g status-bg black
        set -g status-attr dim
        set -g status-left '#{?client_prefix,^, } '
        set -g status-right '%H:%M %d-%b-%y @#{host}'
        set -g window-status-current-attr bold
        bind -n M-Tab last-window
      '';
    };
  };

  # This value determines the NixOS release with which your system is to be
  # compatible, in order to avoid breaking some software such as database
  # servers. You should change this only after NixOS release notes say you
  # should.
  system.stateVersion = "18.09"; # Did you read the comment?

}
