# dada

A total recursion scheme library for Dhall

Recursion schemes provide a total way to support recursion. The decomposition they encourage also enhances composability and reusability.

## development environment

We recommend the following steps to make working in this repo as easy as possible.

### `direnv allow`

This command ensures that any work you do within this repo is done within a consistent reproducible environment. That environment provides various debugging tools, etc. When you leave this directory, you will leave that environment behind, so it doesn’t impact anything else on your system.

### `git config --local include.path ../.config/git/config`

This will apply our repo-specific Git configuration to `git` commands run against this repo. It is very lightweight (you should definitely look at it before applying this command) – it does things like telling `git blame` to ignore formatting-only commits.

## building & development

Especially if you are unfamiliar with the dhall ecosystem, there is a Nix build (both with and without a flake). If you are unfamiliar with Nix, [Nix adjacent](...) can help you get things working in the shortest time and least effort possible.

### if you have `nix` installed

`nix build` will build and test the project fully.

`nix develop` will put you into an environment where the traditional build tooling works. If you also have `direnv` installed, then you should automatically be in that environment when you're in a directory in this project.


## versioning

In the absolute, almost every change is a breaking change. This section describes how we mitigate that to provide minor updates and revisions.



## comparisons

Other projects similar to this one, and how they differ.
