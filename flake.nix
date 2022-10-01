{
  description = "Build tauri desktop application";

  inputs = {
    nixpkgs.url = github:NixOS/nixpkgs/nixos-unstable;
    flake-utils = {
      url = "github:numtide/flake-utils";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    rust-overlay.url = "github:oxalica/rust-overlay";
    cargo2nix.url = "github:cargo2nix/cargo2nix/release-0.11.0";
  };

  outputs = inputs: with inputs; flake-utils.lib.eachDefaultSystem (system: let
    pkgs = import nixpkgs {
      inherit system;
      overlays = [
        cargo2nix.overlays.default
        rust-overlay.overlays.default
      ];
    };
    lib = nixpkgs.lib;

    generate_tauri_config = { name, version, ...}@cfg: pkgs.writeTextFile {
      name = "${name}_tauri_conf.json";
      text = builtins.toJSON (lib.attrsets.recursiveUpdate
        (builtins.fromJSON (builtins.readFile (cfg.backend.tauricfg or "${cfg.backend.src}/tauri.conf.json")))
        {
          "$schema" = ./schema.json;
          package = {
            productName = name;
            version = version;
          };
          build.distDir = "${build_tauri_frontend cfg}";
          build.beforeBuildCommand = "";
          tauri.bundle.identifier = "com.${name}.dev";
        }
      );
    };

    default_rust_toolchain = pkgs.rust-bin.fromRustupToolchain {
      channel = "stable";
      targets = let 
        llvmTriple = with lib.systems.parse; tripleFromSystem (mkSystemFromString system);
      in [ llvmTriple ];
      components = [];
    };

    rustPkgs = {
      cargo2nix_file,
      rustVersion,
      target ? null,
      rootFeatures ? [],
      rustToolchain ? default_rust_toolchain,
      add_overrides ? [],
    ... }: pkgs.rustBuilder.makePackageSet {
      inherit target rootFeatures rustVersion;
      fetchCrateAlternativeRegistry = pkgs.rustBuilder.rustLib.fetchCrateAlternativeRegistryExpensive;
      packageOverrides = pkgs: pkgs.rustBuilder.overrides.all ++ add_overrides;
      packageFun = import cargo2nix_file;
    };

    debugBuildDep = name: deps: pkgs.rustBuilder.rustLib.makeOverride {
      inherit name;
      overrideAttrs = drv: {
        # propagatedBuildInputs = drv.propagatedBuildInputs or [ ] ++ deps;
        propagatedNativeBuildInputs = drv.propagatedNativeBuildInputs or [] ++ deps;
      };
    };

    addBuildDep = name: deps: pkgs.rustBuilder.rustLib.makeOverride {
      inherit name;
      overrideAttrs = drv: { propagatedBuildInputs = drv.propagatedBuildInputs or [ ] ++ deps; };
    };

    build_tauri_backend = cfg: ((rustPkgs (cfg.backend // {
      add_overrides = let
        builddepsall = with pkgs; [
          pkg-config
          # gtk3.dev
          gtk3-x11.dev
          wayland.bin
          wayland.dev
          wayland-utils
          wayland-protocols
          dbus
          webkitgtk
          cmake
          libsoup
          indicator-application-gtk3
          libayatana-indicator-gtk3
          glib.dev
          cairo.dev
          atk.dev
          gdk-pixbuf.dev
          webkitgtk.dev
          freetype
        ];
      in with pkgs; [
        (addBuildDep "glib-sys" [ glib.dev ])
        (addBuildDep "cairo-sys-rs" [ cairo.dev ])
        (addBuildDep "atk-sys" [ atk.dev ])
        (addBuildDep "gdk-pixbuf-sys" [ gdk-pixbuf.dev ])
        (addBuildDep "javascriptcore-rs-sys" [ webkitgtk.dev ])
        (addBuildDep "pango-sys" [ pango.dev ])
        (addBuildDep "soup2-sys" [ libsoup.dev ])

        (debugBuildDep "gdk-sys" [ pkg-config gtk3.dev ])
        (debugBuildDep "gdk" [ pkg-config gtk3.dev ])
        (debugBuildDep "gdkx11-sys" [ pkg-config gtk3.dev ])
      ];
    })).workspace.${cfg.name} { }).bin;

    build_tauri_frontend = cfg: import ./build_frontend.nix {
      name = "${cfg.name}_frontend";
      src = cfg.src;
      inherit pkgs;
      type = cfg.frontend.type;
    };

    build_tauri_app = {
      name, version,
      src, sourceRoot ? "${builtins.baseNameOf src}/src-tauri",
      ...
    }@cfg: pkgs.rustPlatform.buildRustPackage rec {
      pname = name;
      inherit version src;
      sourceRoot = "${builtins.baseNameOf src}/${builtins.baseNameOf cfg.backend.src}";
      cargoLock.lockFile = cfg.backend.lockfile or "${cfg.backend.src}/Cargo.lock";

      nativeBuildInputs = [ pkgs.pkg-config ];
      buildInputs = with pkgs; [ dbus openssl freetype libsoup gtk3 webkitgtk cmake ];
      checkFlags = [ "--skip=test_file_operation" ];

      postPatch = ''
        cp ${generate_tauri_config cfg} ./tauri.conf.json
        ls ${build_tauri_backend cfg}/
      '';
    };

  in {
    packages.default = build_tauri_app {
      name = "template";
      version = "0.1.0";
      src = ./test;

      frontend = {
        type = "react";
      };

      backend = {
        rustVersion = "1.63.0";
        rustChannel = "stable";
        src = ./test/src-tauri;
        cargo2nix_file = ./test/src-tauri/Cargo.nix;
      };
    };
  });
}
