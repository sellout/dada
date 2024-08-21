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
    dhall-bhat,
    flake-utils,
    flaky,
    flaky-haskell,
    nixpkgs,
    self,
  }: let
    pname = "dada";

    supportedSystems =
      nixpkgs.lib.remove
      ## NB: cborg-0.2.9.0, needed by Dhall, doesn’t compile on i686-linux.
      flake-utils.lib.system.i686-linux
      flaky.lib.defaultSystems;

    cabalPackages = pkgs: hpkgs:
      flaky-haskell.lib.cabalProject2nix
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
          (flaky-haskell.lib.overlayHaskellPackages
            (self.lib.supportedGhcVersions "")
            self.overlays.haskell);

        haskellDependencies = final: prev: {};

        dhall = final: prev: dfinal: dprev: {
          ${pname} = self.packages.${final.system}.${pname};
        };

        haskell = flaky-haskell.lib.haskellOverlay cabalPackages;
      };

      homeConfigurations =
        builtins.listToAttrs
        (builtins.map
          (flaky.lib.homeConfigurations.example
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
        defaultCompiler = "ghc965";

        ## Test the oldest revision possible for each minor release. If it’s not
        ## available in nixpkgs, test the oldest available, then try an older
        ## one via GitHub workflow. Additionally, check any revisions that have
        ## explicit conditionalization. And check whatever version `pkgs.ghc`
        ## maps to in the nixpkgs we depend on.
        testedGhcVersions = system:
          [
            self.lib.defaultCompiler
            "ghc8107"
            "ghc902"
            "ghc925"
            "ghc945"
            "ghc963"
            "ghc981"
            "ghc9101"
            # "ghcHEAD" # doctest doesn’t work on current HEAD
          ]
          ## dependency compiler-rt-libc-7.1.0 is broken in on aarch64-darwin.
          ++ nixpkgs.lib.optional (system != "aarch64-darwin") "ghc884";

        ## The versions that are older than those supported by Nix that we
        ## prefer to test against.
        nonNixTestedGhcVersions = [
          ## Dhall 1.34+ doesn’t support GHC before 8.4.
          "8.4.1"
          "8.6.1"
          "8.8.1"
          "8.10.1"
          "9.0.1"
          "9.2.1"
          "9.4.1"
          "9.6.1"
          ## since `cabal-plan-bounds` doesn’t work under Nix
          "9.8.1"
          "9.10.1"
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
    // flake-utils.lib.eachSystem supportedSystems (system: let
      pkgs = import nixpkgs {
        inherit system;
        ## FIXME: This is for Yaya.
        config.allowBroken = true;
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
        // flaky-haskell.lib.mkPackages
        pkgs
        (self.lib.testedGhcVersions system)
        cabalPackages;

      projectConfigurations = flaky.lib.projectConfigurations.default {
        inherit pkgs self supportedSystems;
      };

      devShells =
        {default = self.devShells.${system}.${self.lib.defaultCompiler};}
        // self.projectConfigurations.${system}.devShells
        // flaky-haskell.lib.mkDevShells
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
    ## Flaky should generally be the source of truth for its inputs.
    flaky.url = "github:sellout/flaky";

    bash-strict-mode.follows = "flaky/bash-strict-mode";
    flake-utils.follows = "flaky/flake-utils";
    nixpkgs.follows = "flaky/nixpkgs";

    dhall-bhat = {
      inputs.flaky.follows = "flaky";
      url = "github:sellout/dhall-bhat";
    };

    flaky-haskell = {
      inputs.flaky.follows = "flaky";
      url = "github:sellout/flaky-haskell";
    };
  };
}
