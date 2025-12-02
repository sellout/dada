{
  description = "A total recursion scheme library for Dhall";

  nixConfig = {
    ## NB: This is a consequence both of the prevailing Haskell infrastructure
    ##     and of using `self.pkgsLib.runEmptyCommand`, which allows us to
    ##     sandbox derivations that otherwise can’t be. Even once we migrate to
    ##     non-IFD Haskell infra, this will probably still need to be enabled
    ##     for the other reason.
    allow-import-from-derivation = true;
    ## https://github.com/NixOS/rfcs/blob/master/rfcs/0045-deprecate-url-syntax.md
    extra-experimental-features = ["no-url-literals"];
    extra-substituters = [
      "https://cache.dhall-lang.org"
      "https://cache.garnix.io"
      "https://dhall.cachix.org"
      "https://sellout.cachix.org"
    ];
    extra-trusted-public-keys = [
      "cache.dhall-lang.org:I9/H18WHd60olG5GsIjolp7CtepSgJmM2CsO813VTmM="
      "cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g="
      "dhall.cachix.org-1:8laGciue2JBwD49ICFtg+cIF8ddDaW7OFBjDb/dHEAo="
      "sellout.cachix.org-1:v37cTpWBEycnYxSPAgSQ57Wiqd3wjljni2aC0Xry1DE="
    ];
    ## Isolate the build.
    sandbox = "relaxed";
    use-registries = false;
  };

  ### This is a complicated flake. Here’s the rundown:
  ###
  ### overlays.default – includes all of the packages from cabal.project
  ### packages = {
  ###   default = points to `packages.${defaultGhcVersion}`
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
  ### checks.format = verify that code matches Ormolu expectations
  outputs = {
    dhall-bhat,
    flake-utils,
    flaky,
    flaky-haskell,
    nixpkgs,
    self,
    systems,
  }: let
    pname = "dada";

    supportedSystems = import systems;

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

      # see these issues and discussions:
      # - NixOS/nixpkgs#16394
      # - NixOS/nixpkgs#25887
      # - NixOS/nixpkgs#26561
      # - https://discourse.nixos.org/t/nix-haskell-development-2020/6170
      overlays = {
        default = final:
          nixpkgs.lib.composeManyExtensions [
            flaky.overlays.default
            (final: prev: {
              dhallPackages = prev.dhallPackages.override (old: {
                overrides =
                  final.lib.composeExtensions
                  (old.overrides or (_: _: {}))
                  (self.overlays.dhall final prev);
              });
            })
            (flaky-haskell.lib.overlayHaskellPackages
              (map self.lib.nixifyGhcVersion
                (self.lib.supportedGhcVersions final.system))
              (final: prev:
                nixpkgs.lib.composeManyExtensions [
                  ## TODO: I think this overlay is only needed by formatters,
                  ##       devShells, etc., so it shouldn’t be included in the
                  ##       standard overlay.
                  (flaky.overlays.haskellDependencies final prev)
                  (self.overlays.haskell final prev)
                  (self.overlays.haskellDependencies final prev)
                ]))
          ]
          final;

        dhall = final: prev: dfinal: dprev: {
          ${pname} = self.packages.${final.system}.${pname};
        };

        haskell = flaky-haskell.lib.haskellOverlay cabalPackages;

        ## NB: Dependencies that are overridden because they are broken in
        ##     Nixpkgs should be pushed upstream to Flaky. This is for
        ##     dependencies that we override for reasons local to the project.
        haskellDependencies = final: prev: hfinal: hprev: {
          network = final.haskell.lib.dontCheck hprev.network;
          repline = final.haskell.lib.doJailbreak hprev.repline;
          warp = final.haskell.lib.dontCheck hprev.warp;
        };
      };

      homeConfigurations =
        builtins.listToAttrs
        (builtins.map
          (flaky.lib.homeConfigurations.example self [
            ({pkgs, ...}: {
              home.packages = [
                ## TODO: Is there something more like `dhallWithPackages`?
                pkgs.dhallPackages.${pname}
                (pkgs.haskellPackages.ghcWithPackages (hpkgs: [hpkgs.${pname}]))
              ];
            })
          ])
          supportedSystems);

      lib = {
        nixifyGhcVersion = version:
          "ghc" + nixpkgs.lib.replaceStrings ["."] [""] version;

        ## TODO: Extract this automatically from `pkgs.haskellPackages`.
        defaultGhcVersion = "9.8.4";

        ## Test the oldest revision possible for each minor release. If it’s not
        ## available in nixpkgs, test the oldest available, then try an older
        ## one via GitHub workflow. Additionally, check any revisions that have
        ## explicit conditionalization. And check whatever version `pkgs.ghc`
        ## maps to in the nixpkgs we depend on.
        testedGhcVersions = system: [
          self.lib.defaultGhcVersion
          "9.6.3"
          "9.8.1"
          "9.10.1"
          # "9.12.1" # Yaya doesn’t yet support GHC 9.12
          # "ghcHEAD" # doctest doesn’t work on current HEAD
        ];

        ## The versions that are older than those supported by Nix that we
        ## prefer to test against.
        nonNixTestedGhcVersions = [
          "9.6.1"
          ## since `cabal-plan-bounds` doesn’t work under Nix
          "9.8.1"
          "9.10.1"
          # "9.12.1" # Yaya doesn’t yet support GHC 9.12
        ];

        ## However, provide packages in the default overlay for _every_
        ## supported version.
        supportedGhcVersions = system:
          self.lib.testedGhcVersions system
          ++ [
            "9.6.4"
            "9.6.5"
            "9.8.2"
            "9.8.3"
            "9.10.2"
            "9.12.2"
          ];
      };
    }
    // flake-utils.lib.eachSystem supportedSystems (system: let
      pkgs = nixpkgs.legacyPackages.${system}.appendOverlays [
        dhall-bhat.overlays.default
        ## NB: This uses `self.overlays.default` because packages need to be
        ##     able to find other packages in this flake as dependencies.
        self.overlays.default
      ];

      src = nixpkgs.lib.cleanSource ./.;
    in {
      packages =
        {
          default = self.packages.${system}.${pname};

          "${pname}" = pkgs.checkedDrv (pkgs.dhallPackages.buildDhallDirectoryPackage {
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
        (map self.lib.nixifyGhcVersion (self.lib.supportedGhcVersions system))
        cabalPackages;

      devShells =
        self.projectConfigurations.${system}.devShells
        // {default = flaky.lib.devShells.default system self [] "";}
        // flaky-haskell.lib.mkDevShells
        pkgs
        (map self.lib.nixifyGhcVersion (self.lib.supportedGhcVersions system))
        cabalPackages
        (hpkgs:
          [self.projectConfigurations.${system}.packages.path]
          ## NB: Haskell Language Server no longer supports GHC <9.4.
          ++ nixpkgs.lib.optional
          (nixpkgs.lib.versionAtLeast hpkgs.ghc.version "9.4")
          hpkgs.haskell-language-server);

      projectConfigurations = flaky.lib.projectConfigurations.dhall {
        inherit pkgs self;
        modules = [flaky.projectModules.haskell];
      };

      checks = self.projectConfigurations.${system}.checks;
      formatter = self.projectConfigurations.${system}.formatter;
    });

  inputs = {
    ## Flaky should generally be the source of truth for its inputs.
    flaky = {
      inputs.systems.follows = "systems";
      url = "github:sellout/flaky";
    };

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

    ## This doesn’t follow Flaky because Dada doesn’t support i686.
    systems.url = "github:nix-systems/default";
  };
}
