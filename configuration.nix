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
      displayManager.sddm.enable = true;
      desktopManager.plasma5.enable = true;
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
      extraGroups = [ "wheel" "networkmanager" ];
      uid = 1000;
      createHome = true;
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
