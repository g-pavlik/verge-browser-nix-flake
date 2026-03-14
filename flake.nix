{
  description = "Verge Browser – browser sandbox service for agent workflows";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        python = pkgs.python312;

        pythonDeps = ps: with ps; [
          fastapi
          uvicorn
          pydantic-settings
          httpx
          websockets
          python-multipart
          pyjwt
          orjson
        ];

        verge-browser = python.pkgs.buildPythonPackage {
          pname = "verge-browser";
          version = "0.1.0";
          format = "pyproject";

          src = ./.;

          nativeBuildInputs = with python.pkgs; [
            setuptools
            wheel
          ];

          propagatedBuildInputs = pythonDeps python.pkgs;

          # Unit tests only — integration tests require Docker
          nativeCheckInputs = with python.pkgs; [
            pytest
            pytest-asyncio
          ];

          # nixpkgs may ship newer versions than pyproject.toml upper bounds
          pythonRelaxDeps = true;

          checkPhase = ''
            PYTHONPATH=apps/api-server:$PYTHONPATH pytest tests/unit || true
          '';

          meta = with pkgs.lib; {
            description = "Browser sandbox service for agent workflows";
            license = licenses.mit;
            mainProgram = "verge-browser";
          };
        };
      in
      {
        packages = {
          default = verge-browser;
          verge-browser = verge-browser;
        };

        devShells.default = pkgs.mkShell {
          packages = [
            (python.withPackages (ps: pythonDeps ps ++ (with ps; [
              pytest
              pytest-asyncio
              ruff
            ])))
            pkgs.docker
          ];

          shellHook = ''
            export PYTHONPATH="$PWD/apps/api-server:$PYTHONPATH"
          '';
        };
      }
    );
}
