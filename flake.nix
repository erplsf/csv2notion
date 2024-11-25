{
  description = "An alternative way to import *.csv files to Notion.so.";

  inputs.flake-utils.url = "github:numtide/flake-utils";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/release-23.05";
  inputs.poetry2nix = {
    url = "github:nix-community/poetry2nix";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, flake-utils, poetry2nix }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        # see https://github.com/nix-community/poetry2nix/tree/master#api for more functions and examples.
        inherit (poetry2nix.legacyPackages.${system})
          mkPoetryApplication defaultPoetryOverrides;
        pkgs = nixpkgs.legacyPackages.${system};
        build-packages =
          { # attribute is the name of package that's missing, list contains packages that want to have it
            setuptools = [
              "types-emoji"
              "bs4"
              "flake8-commas"
              "flake8-quotes"
              "flake8-string-format"
              "flake8-rst-docstrings"
              "flakehell"
              "flake8-comprehensions"
            ];
            poetry = [
              "flake8-eradicate"
              "notion-vzhd1701-fork"
              "flake8-broken-line"
              "wemake-python-styleguide"
            ];
          };
        build-overlays =
          self: super: # TODO: refactor into simpler, smaller functions, add description
          builtins.listToAttrs (nixpkgs.lib.flatten (builtins.attrValues
            (builtins.mapAttrs (buildPkg: pkgs:
              map (pkg: {
                name = pkg;
                value = super."${pkg}".overridePythonAttrs (old: {
                  buildInputs = (old.buildInputs or [ ])
                    ++ [ super."${buildPkg}" ];
                });
              }) pkgs) build-packages)));
      in {
        packages = {
          csv2notion = mkPoetryApplication {
            projectDir = self;

            overrides = defaultPoetryOverrides.extend
              (self: super: build-overlays self super);
          };

          default = self.packages.${system}.csv2notion;
        };

        devShells.default =
          pkgs.mkShell { packages = [ poetry2nix.packages.${system}.poetry ]; };
      });
}
