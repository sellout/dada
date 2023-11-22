{
  description = "A total recursion scheme library for Dhall";

  nixConfig = {
    ## https://github.com/NixOS/rfcs/blob/master/rfcs/0045-deprecate-url-syntax.md
    extra-experimental-features = ["no-url-literals"];
    extra-substituters = [
      "https://cache.dhall-lang.org"
      "https://cache.garnix.io"
      "https://dhall.cachix.org"
    ];
    extra-trusted-public-keys = [
      "cache.dhall-lang.org:I9/H18WHd60olG5GsIjolp7CtepSgJmM2CsO813VTmM="
      "cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g="
      "dhall.cachix.org-1:8laGciue2JBwD49ICFtg+cIF8ddDaW7OFBjDb/dHEAo="
    ];
    ## Isolate the build.
    registries = false;
    sandbox = true;
  };

  outputs = inputs: let
    pname = "dada";

    supportedGhcVersions = [
      # "ghc884" # dependency compiler-rt-libc is broken in nixpkgs 23.05
      "ghc8107"
      "ghc902"
      "ghc928"
      "ghc945"
      "ghc961"
      # "ghcHEAD" # doctest doesn’t work on current HEAD
    ];

    cabalPackages = pkgs: hpkgs:
      inputs.concat.lib.cabalProject2nix
      ./cabal.project
      pkgs
      hpkgs
      (old: {
        configureFlags = old.configureFlags ++ ["--ghc-options=-Werror"];
      });
  in
    {
      # see these issues and discussions:
      # - NixOS/nixpkgs#16394
      # - NixOS/nixpkgs#25887
      # - NixOS/nixpkgs#26561
      # - https://discourse.nixos.org/t/nix-haskell-development-2020/6170
      overlays = {
        default =
          inputs.nixpkgs.lib.composeExtensions
          (final: prev: {
            dhallPackages = prev.dhallPackages.override (old: {
              overrides =
                final.lib.composeExtensions
                (old.overrides or (_: _: {}))
                (inputs.self.overlays.dhall final prev);
            });
          })
          (
            inputs.concat.lib.overlayHaskellPackages
            supportedGhcVersions
            inputs.self.overlays.haskell
          );

        dhall = final: prev: dfinal: dprev: {
          ${pname} = inputs.self.packages.${final.system}.${pname};
        };

        haskell = inputs.concat.lib.haskellOverlay cabalPackages;
      };

      homeConfigurations =
        builtins.listToAttrs
        (builtins.map
          (inputs.flaky.lib.homeConfigurations.example
            pname
            inputs.self
            [
              ({pkgs, ...}: {
                home.packages = [
                  pkgs.dhallPackages.${pname}
                  (pkgs.haskellPackages.ghcWithPackages (hpkgs: [
                    hpkgs.${pname}
                  ]))
                ];
              })
            ])
          inputs.flake-utils.lib.defaultSystems);
    }
    // inputs.flake-utils.lib.eachDefaultSystem (system: let
      pkgs = import inputs.nixpkgs {
        inherit system;
        overlays = [inputs.dhall-bhat.overlays.default];
      };

      src = pkgs.lib.cleanSource ./.;

      format = inputs.flaky.lib.format pkgs {
        ## FIXME: All the non-dhall or -haskell config here should be inherited
        ##        from flaky.
        programs = {
          alejandra.enable = true;
          hlint.enable = true;
          ormolu.enable = true;
          shellcheck.enable = true;
          shfmt.enable = true;
        };
        ## subsumes dhall (format)
        ## TODO: Add an option like `programs.dhall.lint = true;` to treefmt-nix
        settings.formatter.dhall-lint = {
          command = pkgs.dhall;
          includes = ["dhall/*"];
          options = ["lint"];
        };
      };

      ## TODO: Extract this automatically from `pkgs.haskellPackages`.
      defaultCompiler = "ghc928";
    in {
      packages =
        {
          default = inputs.self.packages.${system}.${pname};

          "${pname}" =
            inputs.bash-strict-mode.lib.checkedDrv pkgs
            (pkgs.dhallPackages.buildDhallDirectoryPackage {
              src = "${src}/dhall";

              name = pname;

              dependencies = [
                pkgs.dhallPackages.Prelude
                pkgs.dhallPackages.dhall-bhat
              ];

              document = true;
            });
        }
        // inputs.concat.lib.mkPackages pkgs supportedGhcVersions cabalPackages;

      devShells =
        {default = inputs.self.devShells.${system}.${defaultCompiler};}
        // inputs.concat.lib.mkDevShells
        pkgs
        supportedGhcVersions
        cabalPackages
        (hpkgs: [
          hpkgs.haskell-language-server
          pkgs.cabal-install
          pkgs.dhall
          pkgs.dhall-docs
          pkgs.graphviz
        ]);

      checks.format = format.check inputs.self;

      formatter = format.wrapper;
    });

  inputs = {
    bash-strict-mode = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:sellout/bash-strict-mode";
    };

    # Currently contains our Haskell/Nix lib that should be extracted into its
    # own flake.
    concat = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:compiling-to-categories/concat";
    };

    dhall-bhat = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:sellout/dhall-bhat";
    };

    flake-utils.url = "github:numtide/flake-utils";

    flaky.url = "github:sellout/flaky";

    nixpkgs.url = "github:NixOS/nixpkgs/release-23.11";
  };
}
