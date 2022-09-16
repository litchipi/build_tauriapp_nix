let 
  build_tauri_app {
    # Override package.productName in config
    name = "template";
    # Override package.version in config
    version = "0.1.0";

    # Override icon in config
    icon_dir = ./icons;

    ui = {
      # Override devPath in config
      src = ./src;
      # Override distDir in config
      type = "react";
    };

    backend = {
      src = ./src-tauri;
      config_file = ./tauri.conf.json;
      override_config = {
        tauri.bundle = {
          active = true;
          copyright = "GPL3";
        };
      };
      rustChannel = "stable";
      rustVersion = "1.63.0";
    };
  };

  build_tauri_update {
    version = "0.1.1";
  };
in
