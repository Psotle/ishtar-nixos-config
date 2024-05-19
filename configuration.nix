{ config, lib, pkgs, ... }:

{
  imports =
    [
      <nixos-hardware/asus/rog-strix/g513im>
      ./hardware-configuration.nix
      <home-manager/nixos>
      ./cachix.nix
    ];

  nix.settings.trusted-users = [ "root" "psotle"];
  nix.settings.experimental-features = [ "nix-command" "flakes"];
  nixpkgs.config.allowUnfree = true;

  # Enable OpenGL
  hardware.opengl = {
    enable = true;
    driSupport = true;
    driSupport32Bit = true;
  };

  # My model isn't the g513im, it is the g513qm, so the amdgpu address is slightly diff
  hardware.nvidia.prime.amdgpuBusId = lib.mkForce "PCI:06:00:0";

  # Use the grub loader.
  boot.loader.systemd-boot.enable = false;
  boot.loader.grub.enable = true;
  boot.loader.grub.device = "nodev";
  boot.loader.grub.efiSupport = true;
  boot.loader.grub.useOSProber = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernel.sysctl = {
    "vm.swappiness" = 1;
    "net.ipv4.tcp_syncookies" = false;
  };

  security.polkit.enable = true;
  security.rtkit.enable = true;

  # basic networking  
  networking.enableIPv6 = false;
  networking.hostName = "ishtar";
  networking.wireless.enable = false; 
  networking.networkmanager.enable = true;

  # locale
  time.timeZone = "Europe/London";
  i18n.defaultLocale = "en_GB.UTF-8";

  # disable suspend on lid close
  services.logind.lidSwitchExternalPower = "ignore";

  # Enable the X11 windowing system.
  services.xserver = {
    enable = true;
    displayManager.sddm.enable = false;
    displayManager.lightdm.enable = false;
    xkb.layout = "gb";
    windowManager.i3.enable = true;
  };

  services.xrdp = {
    enable = true;
    defaultWindowManager = "i3";
    openFirewall = true;
  };
  
  # Enable sound.
  sound.enable = true;
  hardware.pulseaudio.enable = false;
  services.pipewire = { 
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
    jack.enable = true;
  };

  # dbus broker
  services.dbus.implementation = "broker";

  # Enable touchpad support (enabled default in most desktopManager).
  services.xserver.libinput.enable = true;
  services.xserver.videoDrivers = [ "nvidia" ];

  # mlocate
  services.locate = {
    enable = true;
    localuser = null;
    package = pkgs.plocate;
    interval = "hourly";
  };

  services.gvfs.enable = true;
  services.tumbler.enable = true;

  # gitlab
  services.gitlab = {
    enable = true;
    databaseUsername = "git";
    databasePasswordFile = "/var/keys/gitlab/db_password";
    initialRootPasswordFile = "/var/keys/gitlab/root_password";
    https = false;
    host = "ishtar";
    port = 443;
    user = "git";
    group = "git";
    smtp = {
      enable = false;
    };
    secrets = {
      dbFile = "/var/keys/gitlab/db";
      secretFile = "/var/keys/gitlab/secret";
      otpFile = "/var/keys/gitlab/otp";
      jwsFile = "/var/keys/gitlab/jws";
    };
    extraConfig = {
      gitlab = {
        email_from = "gitlab-no-reply@example.com";
        email_display_name = "Example GitLab";
        email_reply_to = "gitlab-no-reply@example.com";
        default_projects_features = { builds = false; };
      };
    };
  };

  users.users.psotle = {
    shell = pkgs.zsh;
    isNormalUser = true;
    extraGroups = [ "wheel" "docker" "mlocate" "video"];
    packages = with pkgs; [
      firefox
      tree
      vscode
    ];
  };

  programs.light.enable = true;
  programs.zsh = { 
    enable = true;
    enableCompletion = true;
    ohMyZsh = {
      enable = true;
      theme = "eastwood";
      plugins = [
        "sudo"
        "git"
      ];
    };
  };

  programs.thunar.plugins = with pkgs.xfce; [
    thunar-archive-plugin
    thunar-volman
    thunar-media-tags-plugin
  ];
  programs.thunar.enable = true;

  virtualisation.docker.enable = true;
  virtualisation.docker.storageDriver = "btrfs";

  # Home manager
  home-manager.useGlobalPkgs = true;
  home-manager.users.psotle = { pkgs, ... }: {
    home.packages = [ pkgs.atool pkgs.httpie ];
    programs.zsh.enable = true;
    home.stateVersion = "24.05";
    xresources.properties = { 
      "xterm*background" = "black";
      "xterm*foreground" = "white";
      "xterm*faceName" = "Monospace";
      "xterm*faceSize" = "12";
    };
    programs.neovim = {
      enable = true;
      defaultEditor = true;
      viAlias = false;
      vimAlias = true;
      vimdiffAlias = true;
    };
    programs.alacritty = {
      enable = true;
      settings = {
        font.size = 12;
      };
    };
    wayland.windowManager.sway = {
      enable = true;
      config = rec {
        modifier = "Mod4";
        terminal = "alacritty"; 
      };
    };
  };

  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
    "cudatoolkit"
    "vscode"
    "google-chrome"
    "nvidia-x11"
    "nvidia-settings"
  ];
   
  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    # nixos
    cachix
    nix-index

    # desktop
    sublime3
    tageditor
    tigervnc
    deluge
    vlc
     (st.overrideAttrs (oldAttrs: rec {
      buildInputs = oldAttrs.buildInputs ++ [ harfbuzz ];
      src = builtins.fetchTarball {
         url = "https://github.com/lukesmithxyz/st/archive/master.tar.gz";
      };
    }))

    # sway
    grim
    slurp
    wl-clipboard
    mako

    # cli
    ctop
    glxinfo
    mesa-demos
    vim
    wget
    curl
    zsh
    oh-my-zsh
    google-chrome
    pciutils
    htop
    screen

    # dev stuff
    pkgs.devenv
    docker-compose
    protobuf_26
    glibc glibc.dev
    cudatoolkit
    valgrind valgrind.dev
    jdk21
    gmp gmp.dev
    isl
    libffi
    libmpc
    libxcrypt
    mpfr mpfr.dev
    xz xz.dev
    zlib zlib.dev
    m4
    autoconf
    gnumake
    cmake
    meson
    ninja
    bison
    flex
    texinfo
    autogen
    gcc
    stdenv.cc
    stdenv.cc.libc
    stdenv.cc.libc_dev
  ];

  services.openssh.enable = true;
  services.avahi.enable = true;

  system.autoUpgrade.enable  = true;
  system.copySystemConfiguration = true;
  system.stateVersion = "24.05";

}

