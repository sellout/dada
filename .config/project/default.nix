{config, flaky, lib, pkgs, self, ...}: {
  project = {
    name = "dada";
    summary = "A total recursion scheme library for Dhall";

    devPackages = [
      pkgs.cabal-install
      pkgs.dhall
      pkgs.dhall-docs
      pkgs.dhall-lsp-server
      pkgs.graphviz
    ];
  };

  imports = [
    ./github-ci.nix
    ./github-pages.nix
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
      settings.formatter.dhall.includes = ["dhall/*"];
    };
    vale = {
      enable = true;
      excludes = [
        "*.cabal"
        "*.hs"
        "*.lhs"
        "*/.dir-locals.el"
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
    builds.exclude = [
      # TODO: Remove once garnix-io/garnix#285 is fixed.
      "homeConfigurations.x86_64-darwin-${config.project.name}-example"
    ];
  };
  ## FIXME: Shouldn’t need `mkForce` here (or to duplicate the base contexts).
  ##        Need to improve module merging.
  services.github.settings.branches.main.protection.required_status_checks.contexts =
    lib.mkForce
      (map (ghc: "CI / build (${ghc}) (pull_request)") self.lib.nonNixTestedGhcVersions
      ++ lib.concatMap flaky.lib.garnixChecks (
        lib.concatMap (ghc: [
          (sys: "devShell ghc${ghc} [${sys}]")
          (sys: "package ghc${sys}_all [${sys}]")
        ])
        (self.lib.testedGhcVersions pkgs.system)
        ++ [
          (sys: "homeConfig ${sys}-${config.project.name}-example")
          (sys: "package default [${sys}]")
          (sys: "package ${config.project.name} [${sys}]")
          ## FIXME: These are duplicated from the base config
          (sys: "check formatter [${sys}]")
          (sys: "devShell default [${sys}]")
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
