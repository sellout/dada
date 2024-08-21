{
  config,
  flaky,
  lib,
  pkgs,
  self,
  supportedSystems,
  ...
}: let
  githubSystems = ["macos-13" "ubuntu-22.04" "windows-2022"];
in {
  project = {
    name = "dada";
    summary = "A total recursion scheme library for Dhall";

    devPackages = [
      pkgs.cabal-install
      pkgs.dhall
      pkgs.dhall-docs
      pkgs.dhall-lsp-server
      pkgs.graphviz
      ## So cabal-plan(-bounds) can be built in a devShell, since it doesn’t
      ## work in Nix proper.
      pkgs.zlib
    ];
  };

  imports = [
    (import ./github-ci.nix githubSystems [config.project.name])
    ./github-pages.nix
    ./hackage-publish.nix
    ./hlint.nix
  ];

  ## dependency management
  services.renovate.enable = true;

  ## development
  programs = {
    direnv.enable = true;
    # This should default by whether there is a .git file/dir (and whether it’s
    # a file (worktree) or dir determines other things – like where hooks
    # are installed.
    git = {
      enable = true;
      ignores = [
        # Cabal build
        "dist-newstyle"
      ];
    };
  };

  ## formatting
  editorconfig.enable = true;
  programs = {
    treefmt = {
      enable = true;
      programs = {
        dhall.enable = true;
        ## Haskell formatter
        ormolu.enable = true;
      };
      settings.formatter = {
        dhall.includes = ["dhall/*"];
        prettier.excludes = ["*/docs/license-report.md"];
      };
    };
    vale = {
      enable = true;
      excludes = [
        "*.cabal"
        "*.hs"
        "*.lhs"
        "*/.dir-locals.el"
        "./.config/emacs/.dir-locals.el"
        "./.gitattributes"
        "./.github/settings.yml"
        "./.shellcheckrc"
        "./cabal.project"
        "./dhall/*"
      ];
      vocab.${config.project.name}.accept = [
        "bugfix"
        "comonad"
        "composability"
        "conditionalize"
        "Dhall"
        "functor"
        "GADT"
        "Kleisli"
        "Kmett"
        "reusability"
      ];
    };
  };
  project.file.".dir-locals.el".source = lib.mkForce ../emacs/.dir-locals.el;

  ## CI
  services.garnix = {
    enable = true;
    builds = {
      ## TODO: Remove once garnix-io/garnix#285 is fixed.
      exclude = ["homeConfigurations.x86_64-darwin-example"];
      include = lib.mkForce (
        [
          "homeConfigurations.*"
          "nixosConfigurations.*"
        ]
        ++ flaky.lib.forGarnixSystems supportedSystems (
          sys:
            [
              "checks.${sys}.*"
              "devShells.${sys}.default"
              "packages.${sys}.default"
              "packages.${sys}.${config.project.name}"
            ]
            ++ lib.concatMap (ghc: [
              "devShells.${sys}.${ghc}"
              "packages.${sys}.${ghc}_all"
            ])
            (self.lib.testedGhcVersions sys)
        )
      );
    };
  };
  ## FIXME: Shouldn’t need `mkForce` here (or to duplicate the base contexts).
  ##        Need to improve module merging.
  services.github.settings.branches.main.protection.required_status_checks.contexts =
    lib.mkForce
    (["check-bounds"]
      ++ lib.concatMap (sys:
        lib.concatMap (ghc: [
          "build (${ghc}, ${sys})"
          "build (--prefer-oldest, ${ghc}, ${sys})"
        ])
        self.lib.nonNixTestedGhcVersions)
      githubSystems
      ++ flaky.lib.forGarnixSystems supportedSystems (sys:
        lib.concatMap (ghc: [
          "devShell ${ghc} [${sys}]"
          "package ${ghc}_all [${sys}]"
        ])
        (self.lib.testedGhcVersions sys)
        ++ [
          "homeConfig ${sys}-example"
          "package default [${sys}]"
          "package ${config.project.name} [${sys}]"
          ## FIXME: These are duplicated from the base config
          "check formatter [${sys}]"
          "check project-manager-files [${sys}]"
          "check vale [${sys}]"
          "devShell default [${sys}]"
        ]));

  ## publishing
  programs.git.attributes = ["/dhall/** linguist-language=Dhall"];
  services.flakehub.enable = true;
  services.github.enable = true;
  services.github.settings.repository = {
    homepage = "https://sellout.github.io/${config.project.name}";
    topics = ["library"];
  };
}
