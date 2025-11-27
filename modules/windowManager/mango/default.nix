# modules/mango/default.nix
{ config, lib, inputs, pkgs, pkgs-unstable, ... }:

let
  cfg = config.desktop.mango;
in
{
  options.desktop.mango = {
    enable = lib.mkEnableOption "MangoWC (mango) compositor with NixOS + Home-Manager";
    extraPackages = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [ ];
      description = "Additional packages for the mango desktop";
    };

    enableDms = lib.mkEnableOption "Enable DankMaterialShell / dms";
  };

  imports = [
    inputs.mangowc.nixosModules.mango
    inputs.dankMaterialShell.nixosModules.greeter
  ];

  config = lib.mkIf cfg.enable {


    # Enable CUPS to print documents.
    services.printing.enable = true;

    # Enable sound with pipewire.
    services.pulseaudio.enable = false;
    security.rtkit.enable = true;
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };

    xdg.portal = {
      enable = true;
      extraPortals = [ pkgs.xdg-desktop-portal-wlr pkgs.xdg-desktop-portal-gtk ];
      xdgOpenUsePortal = true;
      wlr.enable = true;
      wlr.settings = {
        screencast = {
          output_name = "HDMI-A-1";
          max_fps = 30;
          exec_before = "disable_notifications.sh";
          exec_after = "enable_notifications.sh";
          chooser_type = "simple";
          chooser_cmd = "${pkgs.slurp}/bin/slurp -f %o -or";
        };
      };

      config = {
        common = { "org.freedesktop.impl.portal.ScreenCast" = [ "wlr" ]; };
      };
    };

    fonts = {
      enableDefaultPackages = true;

      packages = with pkgs; [ 
        nerd-fonts.jetbrains-mono 
        nerd-fonts.fira-code
        inter
        material-symbols
      ];
    };

    programs.mango.enable = true;

    nixpkgs.overlays =
      [ (final: prev: { quickshell = pkgs-unstable.quickshell; }) ];

    environment.systemPackages = 
      (with pkgs; [
        adwaita-qt
        adwaita-icon-theme
        quickshell
        foot
        sox
        wlr-randr
        pipewire
        wireplumber
        xdg-desktop-portal
        xdg-desktop-portal-gtk
        xdg-desktop-portal-wlr
        grim
        slurp

        coreutils-full
        gnumake
        tree
        git
        lazygit
        tmux
        vim
        wget
        kitty
        brave

        # Audio/video
        pavucontrol
        playerctl

        matugen
      ])
      ++ lib.optionals cfg.enableDms (
        let
          dmsPackages = inputs.dankMaterialShell.packages.${pkgs.system};
        in [
          dmsPackages.dms
          dmsPackages.dmsCli
        ]
      )
      ++ cfg.extraPackages;

    home-manager.users.sebi.imports = [
      inputs.mangowc.hmModules.mango
      inputs.dankMaterialShell.homeModules.dankMaterialShell.default

      ({ ... }: {
        wayland.windowManager.mango = {
          enable = true;
          settings = ''
                    # Window effect
                    blur=1
                    blur_layer=0
                    blur_optimized=1
                    blur_params_num_passes = 2
                    blur_params_radius = 5
                    blur_params_noise = 0.02
                    blur_params_brightness = 0.9
                    blur_params_contrast = 0.9
                    blur_params_saturation = 1.2
  
                    shadows = 1
                    layer_shadows = 0
                    shadow_only_floating = 1
                    shadows_size = 10
                    shadows_blur = 15
                    shadows_position_x = 0
                    shadows_position_y = 0
                    shadowscolor= 0x0000ff
  
                    border_radius=16
                    no_radius_when_single=0
                    focused_opacity=0.96
                    unfocused_opacity=0.85
  
                    # Animation Configuration(support type:zoom,slide)
                    # tag_animation_direction: 0-horizontal,1-vertical
                    animations=1
                    layer_animations=1
                    animation_type_open=slide
                    animation_type_close=slide
                    animation_fade_in=1
                    animation_fade_out=1
                    tag_animation_direction=1
                    zoom_initial_ratio=0.3
                    zoom_end_ratio=0.8
                    fadein_begin_opacity=0.5
                    fadeout_begin_opacity=0.85
                    animation_duration_move=500
                    animation_duration_open=400
                    animation_duration_tag=350
                    animation_duration_close=800
                    animation_duration_focus=0
                    animation_curve_open=0.46,1.0,0.29,1
                    animation_curve_move=0.46,1.0,0.29,1
                    animation_curve_tag=0.46,1.0,0.29,1
                    animation_curve_close=0.08,0.92,0,1
                    animation_curve_focus=0.46,1.0,0.29,1
  
                    # Scroller Layout Setting
                    scroller_structs=20
                    scroller_default_proportion=0.66
                    scroller_focus_center=0
                    scroller_prefer_center=0
                    edge_scroller_pointer_focus=1
                    scroller_default_proportion_single=0.66
                    scroller_proportion_preset=0.33,0.5,0.66,0.8,1.0
  
                    # Master-Stack Layout Setting
                    new_is_master=1
                    default_mfact=0.65
                    default_nmaster=1
                    smartgaps=0
  
                    # Overview Setting
                    hotarea_size=10
                    enable_hotarea=1
                    ov_tab_mode=0
                    overviewgappi=5
                    overviewgappo=30
  
                    # Misc
                    no_border_when_single=0
                    axis_bind_apply_timeout=100
                    focus_on_activate=1
                    inhibit_regardless_of_visibility=0
                    sloppyfocus=1
                    warpcursor=1
                    focus_cross_monitor=0
                    focus_cross_tag=0
                    enable_floating_snap=0
                    snap_distance=30
                    cursor_size=24
                    drag_tile_to_tile=1
  
                    # keyboard
                    repeat_rate=25
                    repeat_delay=600
                    numlockon=0
                    xkb_rules_layout=us,de
                    xkb_rules_options=grp:win_space_toggle
  
                    # Trackpad
                    # need relogin to make it apply
                    disable_trackpad=0
                    tap_to_click=1
                    tap_and_drag=1
                    drag_lock=1
                    trackpad_natural_scrolling=0
                    disable_while_typing=1
                    left_handed=0
                    middle_button_emulation=0
                    swipe_min_threshold=1
  
                    # mouse
                    # need relogin to make it apply
                    mouse_natural_scrolling=0
  
                    # Appearance - Catppuccin inspired colors
                    gappih=5
                    gappiv=5
                    gappoh=10
                    gappov=10
                    scratchpad_width_ratio=0.8
                    scratchpad_height_ratio=0.9
                    borderpx=4
                    rootcolor=0x1e1e2eff
                    bordercolor=0x313244ff
                    focuscolor=0x89b4faff
                    maximizescreencolor=0x45475aff
                    urgentcolor=0xf38ba8ff
                    scratchpadcolor=0x585b70ff
                    globalcolor=0xb4befe
                    overlaycolor=0xa6adc8ff
  
                    # layout support:
                    # tile,scroller,grid,deck,monocle,center_tile,vertical_tile,vertical_scroller
                    tagrule=id:1,layout_name:vertical_scroller
                    tagrule=id:2,layout_name:scroller
                    tagrule=id:3,layout_name:scroller
                    tagrule=id:4,layout_name:scroller
                    tagrule=id:5,layout_name:scroller
  
                    tagrule=id:6,monitor_name:DVI-D-1,layout_name:tile
                    tagrule=id:7,monitor_name:DVI-D-1,layout_name:tile
                    tagrule=id:8,monitor_name:DVI-D-1,layout_name:tile
                    tagrule=id:9,monitor_name:DVI-D-1,layout_name:tile
  
                    # Key Bindings
                    # key name refer to `xev` or `wev` command output,
                    # mod keys name: super,ctrl,alt,shift,none
  
                    # reload config
                    bind=SUPER,r,reload_config
  
                    # menu and terminal
                    bind=SUPER,Return,spawn,kitty
                    bind=SUPER+SHIFT,f,spawn,brave
                    bind=SUPER,d,spawn,dms ipc call spotlight open
                    bind=SUPER+SHIFT,s,spawn,./scripts/take_screenshot
  
                    # monitor switch
                    bind=alt+shift,h,focusmon,left
                    bind=alt+shift,l,focusmon,right
                    bind=SUPER+Alt,h,tagmon,left
                    bind=SUPER+Alt,l,tagmon,right
  
                    # exit
                    bind=SUPER+SHIFT,e,quit
                    bind=SUPER+SHIFT,q,killclient
  
                    # switch window focus
                    bind=SUPER,Tab,focusstack,next
                    bind=SUPER,h,focusdir,left
                    bind=SUPER,l,focusdir,right
                    bind=SUPER,k,focusdir,up
                    bind=SUPER,j,focusdir,down
  
                    # swap window
                    bind=SUPER+SHIFT,h,exchange_client,left
                    bind=SUPER+SHIFT,l,exchange_client,right
                    bind=SUPER+SHIFT,k,exchange_client,up
                    bind=SUPER+SHIFT,j,exchange_client,down
  
                    # switch window status
                    # bind=SUPER,g,toggleglobal
                    bind=SUPER,o,toggleoverview
                    bind=SUPER,m,togglefloating
                    bind=SUPER+SHIFT,m,togglemaximizescreen
                    bind=SUPER,f,togglefullscreen
                    bind=SUPER,u,toggle_scratchpad
                    bind=SUPER,i,minimized
                    bind=SUPER+SHIFT,I,restore_minimized
  
                    # scroller layout
                    bind=SUPER,minus,set_proportion,0.5
                    bind=SUPER,plus,set_proportion,0.8
                    bind=SUPER,equal,switch_proportion_preset
  
                    # switch layout
                    bind=SUPER,g,switch_layout
                    bind=SUPER,s,setlayout,scroller
                    bind=SUPER,v,setlayout,vertical_scroller
                    bind=SUPER,c,setlayout,center_tile
                    bind=SUPER,t,setlayout,tile
  
                    # tag switch
                    bind=SUPER,Left,viewtoleft,0
                    bind=SUPER,Right,viewtoright,0
                    bind=SUPER+CTRL,Left,tagtoleft,0
                    bind=SUPER+CTRL,Right,tagtoright,0
  
                    bind=SUPER,1,view,1,0
                    bind=SUPER,2,view,2,0
                    bind=SUPER,3,view,3,0
                    bind=SUPER,4,view,4,0
                    bind=SUPER,5,view,5,0
                    bind=SUPER,6,view,6,0
                    bind=SUPER,7,view,7,0
                    bind=SUPER,8,view,8,0
                    bind=SUPER,9,view,9,0
  
                    # tag: move client to the tag and focus it
                    bind=SUPER+SHIFT,1,tag,1,0
                    bind=SUPER+SHIFT,2,tag,2,0
                    bind=SUPER+SHIFT,3,tag,3,0
                    bind=SUPER+SHIFT,4,tag,4,0
                    bind=SUPER+SHIFT,5,tag,5,0
                    bind=SUPER+SHIFT,6,tag,6,0
                    bind=SUPER+SHIFT,7,tag,7,0
                    bind=SUPER+SHIFT,8,tag,8,0
                    bind=SUPER+SHIFT,9,tag,9,0
  
                    # gaps
                    bind=SUPER+SHIFT,x,incgaps,5
                    bind=SUPER+SHIFT,z,incgaps,-5
                    bind=SUPER+SHIFT,r,togglegaps
  
                    # Mouse Button Bindings
                    # NONE mode key only work in ov mode
                    mousebind=SUPER,btn_left,moveresize,curmove
                    mousebind=SUPER,btn_right,moveresize,curresize
                    mousebind=SUPER+CTRL,btn_right,killclient
                    mousebind=NONE,btn_middle,togglemaximizescreen,0
                    mousebind=NONE,btn_left,toggleoverview,1
                    mousebind=NONE,btn_right,killclient,0
  
                    # Environment variables
                    env=XCURSOR_SIZE,24
                    env=XCURSOR_THEME,Adwaita-dark
                    env=WAYLAND_DISPLAY,wlroots
                    env=XDG_CURRENT_DESKTOP,wlroots
                    
                    # Additional environment variables for theming
                    env=GTK_THEME,Adwaita-dark
                    env=ICON_THEME,Adwaita-dark
          '';

          # und dein autostart.sh Pendant
          autostart_sh = ''
                    set -e

                    # wichtige envs an systemd/dbus durchreichen (hilft bei App-Autostart)
                    dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP=wlroots
                    
                    # optional: kleines Delay damit Mango fertig ist
                    sleep 0.5
                    
                    wlr-randr --output HDMI-A-1 --output DVI-D-1 --right-of HDMI-A-1 &
                    
                    # DankMaterialShell starten
                    dms run -d
          '';
        };

        gtk = {
          enable = true;
          theme = {
            name = "Adwaita-dark";
            package = pkgs.gnome-themes-extra;
          };
          iconTheme = {
            name = "Adwaita";
            package = pkgs.gnome-themes-extra;
          };
        };

        qt = {
          enable = true;
          platformTheme = "gtk";
          style.name = "Adwaita-Dark";
        };

        programs.dankMaterialShell = {
          enable = true;
          #quickshell.package = pkgs-unstable.quickshell;
          systemd = {
            enable = true;             # Systemd service for auto-start
            restartIfChanged = true;   # Auto-restart dms.service when dankMaterialShell changes
          };
          
          # Core features
          enableSystemMonitoring = true;     # System monitoring widgets (dgop)
          enableClipboard = true;            # Clipboard history manager
          enableVPN = true;                  # VPN management widget
          enableBrightnessControl = true;    # Backlight/brightness controls
          enableColorPicker = true;          # Color picker tool
          enableDynamicTheming = true;       # Wallpaper-based theming (matugen)
          enableAudioWavelength = true;      # Audio visualizer (cava)
          enableCalendarEvents = true;       # Calendar integration (khal)
          enableSystemSound = true;          # System sound effects
        };
      })
    ];
  };
}
