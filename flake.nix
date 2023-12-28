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
    sandbox = "relaxed";
  };

  ### This is a complicated flake. Here’s the rundown:
  ###
  ### overlays.default – includes all of the packages from cabal.project
  ### packages = {
  ###   default = points to `packages.dada`
  ###  dada = the Dhall project
  ###   <ghcVersion>-<cabal-package> = an individual package compiled for one
  ###                                  GHC version
  ###   <ghcVersion>-all = all of the packages in cabal.project compiled for one
  ###                      GHC version
  ### };
  ### devShells = {
  ###   default = points to `devShells.${defaultGhcVersion}`
  ###   <ghcVersion> = a shell providing all of the dependencies for all
  ###                  packages in cabal.project compiled for one GHC version
  ### };
  outputs = {
    bash-strict-mode,
    concat,
    dhall-bhat,
    flake-utils,
    flaky,
    nixpkgs,
    self,
  }: let
    pname = "dada";

    ## TODO: dhall-bhat doesn’t yet support i686-linux.
    supportedSystems = nixpkgs.lib.remove "i686-linux" flaky.lib.defaultSystems;

    cabalPackages = pkgs: hpkgs:
      concat.lib.cabalProject2nix
      ./cabal.project
      pkgs
      hpkgs
      (old: {
        configureFlags = old.configureFlags ++ ["--ghc-options=-Werror"];
      });
  in
    {
      schemas = {
        inherit
          (flaky.schemas)
          overlays
          homeConfigurations
          packages
          devShells
          projectConfigurations
          checks
          formatter
          ;
      };

      overlays = {
        default =
          nixpkgs.lib.composeExtensions
          (final: prev: {
            dhallPackages = prev.dhallPackages.override (old: {
              overrides =
                final.lib.composeExtensions
                (old.overrides or (_: _: {}))
                (self.overlays.dhall final prev);
            });
          })
          self.overlays.cabalPackages;

        # see these issues and discussions:
        # - NixOS/nixpkgs#16394
        # - NixOS/nixpkgs#25887
        # - NixOS/nixpkgs#26561
        # - https://discourse.nixos.org/t/nix-haskell-development-2020/6170
        cabalPackages =
          nixpkgs.lib.composeExtensions
          self.overlays.haskellDependencies
          (concat.lib.overlayHaskellPackages
            (self.lib.supportedGhcVersions "")
            self.overlays.haskell);

        haskellDependencies = final: prev: {
          haskell =
            prev.haskell
            // {
              packages =
                prev.haskell.packages
                // (
                  if prev.system == "aarch64-linux"
                  then {
                    ghc942 = prev.haskell.packages.ghc942.extend (hfinal: hprev: {
                      ## A couple test cases fail on this system/GHC combo.
                      foundation = prev.haskell.lib.dontCheck hprev.foundation;
                    });
                    ghc962 = prev.haskell.packages.ghc962.extend (hfinal: hprev: {
                      ## The default tls version (1.6.0) doesn’t build on this
                      ## system/GHC combo.
                      tls = hprev.tls_1_9_0;
                    });
                  }
                  else {}
                );
            };
        };

        dhall = final: prev: dfinal: dprev: {
          ${pname} = self.packages.${final.system}.${pname};
        };

        haskell = concat.lib.haskellOverlay cabalPackages;
      };

      homeConfigurations =
        builtins.listToAttrs
        (builtins.map
          (flaky.lib.homeConfigurations.example
            pname
            self
            [
              ({pkgs, ...}: {
                home.packages = [
                  ## TODO: Is there something more like `dhallWithPackages`?
                  pkgs.dhallPackages.${pname}
                  (pkgs.haskellPackages.ghcWithPackages (hpkgs: [
                    hpkgs.${pname}
                  ]))
                ];
              })
            ])
          supportedSystems);

      lib = {
        ## TODO: Extract this automatically from `pkgs.haskellPackages`.
        defaultCompiler = "ghc948";

        ## Test the oldest revision possible for each minor release. If it’s not
        ## available in nixpkgs, test the oldest available, then try an older
        ## one via GitHub workflow. Additionally, check any revisions that have
        ## explicit conditionalization. And check whatever version `pkgs.ghc`
        ## maps to in the nixpkgs we depend on.
        testedGhcVersions = system: [
          self.lib.defaultCompiler
          "ghc8107"
          "ghc902"
          "ghc924"
          "ghc942"
          "ghc962"
          # "ghc981" # included dhall dependency versions fail
          # "ghcHEAD" # doctest doesn’t work on current HEAD
        ];
        ## dependency compiler-rt-libc-7.1.0 is broken in on aarch64-darwin.
        # TODO: included dependency versions fail
        # ++ nixpkgs.lib.optional (system != "aarch64-darwin") "ghc884";

        ## The versions that are older than those supported by Nix that we
        ## prefer to test against.
        nonNixTestedGhcVersions = [
          ## Dhall 1.34+ doesn’t support GHC before 8.4.
          # "8.4.1" # dependencies of dhall fail to build
          # "8.6.1" # dependencies of dhall fail to build
          "8.8.1"
          "8.10.1"
          "9.0.1"
          "9.2.1"
          "9.4.1"
          "9.6.1"
        ];

        ## However, provide packages in the default overlay for _every_
        ## supported version.
        supportedGhcVersions = system:
          self.lib.testedGhcVersions system
          ++ [
            "ghc925"
            "ghc926"
            "ghc927"
            "ghc928"
            "ghc943"
            "ghc944"
            "ghc945"
            "ghc946"
            "ghc947"
            "ghc948"
            "ghc963"
          ];
      };
    }
    // flake-utils.lib.eachSystem supportedSystems
    (system: let
      pkgs = import nixpkgs {
        inherit system;
        overlays = [
          dhall-bhat.overlays.default
          ## NB: This uses `self.overlays.cabalPackages` because packages need
          ##     to be able to find other packages in this flake as
          ##     dependencies.
          self.overlays.cabalPackages
        ];
      };

      src = nixpkgs.lib.cleanSource ./.;
    in {
      packages =
        {
          default = self.packages.${system}.${pname};

          "${pname}" =
            bash-strict-mode.lib.checkedDrv
            pkgs
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
        // concat.lib.mkPackages
        pkgs
        (self.lib.testedGhcVersions system)
        cabalPackages;

      projectConfigurations =
        flaky.lib.projectConfigurations.default {inherit pkgs self;};

      devShells =
        {default = self.devShells.${system}.${self.lib.defaultCompiler};}
        // concat.lib.mkDevShells
        pkgs
        (
          if system == "aarch64-darwin"
          then
            nixpkgs.lib.subtractLists
            ## NB: These devShells don’t work when sandboxed. See
            ##     NixOS/nix#4119.
            ## TODO: Just disable the sandbox, don’t omit these devShells.
            ["ghc902" "ghc924" "ghc942" "ghc962"]
            (self.lib.testedGhcVersions system)
          else self.lib.testedGhcVersions system
        )
        cabalPackages
        (hpkgs:
          [self.projectConfigurations.${system}.packages.path]
          ## NB: Haskell Language Server no longer supports GHC <9.
          ## TODO: HLS also apparently broken on 9.8.1
          ++ nixpkgs.lib.optional
          (nixpkgs.lib.versionAtLeast hpkgs.ghc.version "9"
            && builtins.compareVersions hpkgs.ghc.version "9.8.1" != 0)
          hpkgs.haskell-language-server);

      checks = self.projectConfigurations.${system}.checks;
      formatter = self.projectConfigurations.${system}.formatter;
    });

  inputs = {
    bash-strict-mode = {
      inputs = {
        flake-utils.follows = "flake-utils";
        flaky.follows = "flaky";
        nixpkgs.follows = "nixpkgs";
      };
      url = "github:sellout/bash-strict-mode";
    };

    # Currently contains our Haskell/Nix lib that should be extracted into its
    # own flake.
    concat = {
      inputs = {
        flake-utils.follows = "flake-utils";
        nixpkgs.follows = "nixpkgs";
      };
      url = "github:compiling-to-categories/concat";
    };

    dhall-bhat = {
      inputs = {
        ## TODO: The version currently used by dhall-bhat is quite old..
        bash-strict-mode.follows = "flaky/bash-strict-mode";
        flaky.follows = "flaky";
        nixpkgs.follows = "nixpkgs";
      };
      url = "github:sellout/dhall-bhat";
    };

    flake-utils.url = "github:numtide/flake-utils";

    flaky = {
      inputs = {
        bash-strict-mode.follows = "bash-strict-mode";
        flake-utils.follows = "flake-utils";
        nixpkgs.follows = "nixpkgs";
      };
      url = "github:sellout/flaky";
    };

    nixpkgs.url = "github:NixOS/nixpkgs/release-23.11";
  };
}
