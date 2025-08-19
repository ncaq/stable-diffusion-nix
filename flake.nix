{
  description = "Stable Diffusion WebUI managed by Nix";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    flake-parts.url = "github:hercules-ci/flake-parts";
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    stable-diffusion-webui = {
      url = "github:AUTOMATIC1111/stable-diffusion-webui/dev";
      flake = false;
    };
  };

  outputs =
    inputs@{
      flake-parts,
      treefmt-nix,
      ...
    }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        treefmt-nix.flakeModule
      ];

      systems = [ "x86_64-linux" ];

      perSystem =
        {
          system,
          ...
        }:
        let
          # Python package overlay for custom packages
          pythonOverlay = _final: prev: {
            python313 = prev.python313.override {
              packageOverrides = pyFinal: _pyPrev: {
                blendmodes = pyFinal.buildPythonPackage rec {
                  pname = "blendmodes";
                  version = "2022";
                  src = pyFinal.fetchPypi {
                    inherit pname version;
                    sha256 = "sha256-k2jxwekOhzS0lo8MrANpbg5acU/VfnS8bu/SXAQY/QM=";
                  };
                  propagatedBuildInputs = with pyFinal; [ numpy ];
                  doCheck = false; # No tests
                };

                facexlib = pyFinal.buildPythonPackage rec {
                  pname = "facexlib";
                  version = "0.3.0";
                  src = pyFinal.fetchPypi {
                    inherit pname version;
                    sha256 = "sha256-eueEpSDrUuBVg+i/n2j3f0UIMjmsdU1kbWNQF7Sed2M=";
                  };
                  postPatch = ''
                    substituteInPlace setup.py \
                      --replace "version=get_version()," "version='${version}',"
                  '';
                  nativeBuildInputs = with pyFinal; [
                    cython
                  ];
                  propagatedBuildInputs = with pyFinal; [
                    numpy
                    opencv4
                    pillow
                    torch
                    torchvision
                    tqdm
                    numba
                    scipy
                    filterpy
                  ];
                  doCheck = false; # Tests require model downloads
                };

                pillow-avif-plugin = pyFinal.buildPythonPackage rec {
                  pname = "pillow-avif-plugin";
                  version = "1.5.2";
                  src = pyFinal.fetchPypi {
                    pname = "pillow_avif_plugin";
                    inherit version;
                    sha256 = "sha256-gR4NyL4eRDk9Ljhl7DMKiooRlLlOuM/Kb6d44/R21kk=";
                  };
                  propagatedBuildInputs = with pyFinal; [ pillow ];
                  buildInputs = with prev; [ libavif ];
                  doCheck = false; # Tests require specific image files
                };

                spandrel = pyFinal.buildPythonPackage rec {
                  pname = "spandrel";
                  version = "0.4.0";
                  src = pyFinal.fetchPypi {
                    inherit pname version;
                    sha256 = "sha256-9FUmiT+SOhLvN1QsROREsSCJdlk7x8zfpU/QTHw+gMo=";
                  };
                  format = "pyproject";
                  nativeBuildInputs = with pyFinal; [
                    setuptools
                    wheel
                  ];
                  propagatedBuildInputs = with pyFinal; [
                    torch
                    torchvision
                    safetensors
                    numpy
                    einops
                  ];
                  doCheck = false; # Tests require model downloads
                };

                spandrel-extra-arches = pyFinal.buildPythonPackage rec {
                  pname = "spandrel_extra_arches";
                  version = "0.2.0";
                  src = pyFinal.fetchPypi {
                    inherit pname version;
                    sha256 = "sha256-khaHfsq8nJfgAa1dScT40rH2xvgtHnfI4rNQxYa25ko=";
                  };
                  format = "pyproject";
                  nativeBuildInputs = with pyFinal; [
                    setuptools
                    wheel
                  ];
                  propagatedBuildInputs = with pyFinal; [
                    spandrel
                  ];
                  doCheck = false; # No tests
                };

                tomesd = pyFinal.buildPythonPackage rec {
                  pname = "tomesd";
                  version = "0.1.3";
                  src = pyFinal.fetchPypi {
                    inherit pname version;
                    sha256 = "sha256-Fbui6VL0ZDyDVZUeiS/akY3cy9/yI43DaNQr0Hj87ck=";
                  };
                  propagatedBuildInputs = with pyFinal; [ torch ];
                  doCheck = false; # No tests
                };
              };
            };
          };

          # Apply overlay
          pkgs' = import inputs.nixpkgs {
            inherit system;
            config.allowUnfree = true;
            overlays = [ pythonOverlay ];
          };

          # Python environment with all dependencies
          pythonEnv = pkgs'.python313.withPackages (
            ps: with ps; [
              accelerate
              blendmodes
              clean-fid
              diskcache
              einops
              facexlib
              fastapi
              gitpython
              gradio
              httpcore
              httpx
              inflection
              jsonmerge
              kornia
              lark
              numpy
              omegaconf
              open-clip-torch
              piexif
              pillow
              pillow-avif-plugin
              protobuf
              psutil
              pytorch-lightning
              resize-right
              safetensors
              scikit-image
              spandrel
              spandrel-extra-arches
              tomesd
              torch
              torchdiffeq
              torchsde
              transformers
            ]
          );

          stable-diffusion-webui = pkgs'.stdenv.mkDerivation {
            pname = "stable-diffusion-webui";
            version = "unstable-2024-07-25";
            src = inputs.stable-diffusion-webui;
            buildInputs = with pkgs'; [
              cudaPackages.cudatoolkit
              cudaPackages.cudnn
              git
              pythonEnv
            ];
            installPhase = ''
              mkdir -p $out/share/stable-diffusion-webui
              cp -r . $out/share/stable-diffusion-webui/
            '';
          };
        in
        {
          treefmt.config = {
            projectRootFile = "flake.nix";
            programs = {
              deadnix.enable = true;
              nixfmt.enable = true;
              prettier.enable = true;
              shellcheck.enable = true;
              shfmt.enable = true;
            };
          };
          packages.default = stable-diffusion-webui;
          devShells.default = pkgs'.mkShell {
            buildInputs = [ pythonEnv ];
          };
        };
    };

  nixConfig = {
    extra-substituters = [
      "https://cache.nixos.org/"
      "https://nix-community.cachix.org"
      "https://cuda-maintainers.cachix.org"
    ];
    extra-trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "cuda-maintainers.cachix.org-1:0dq3bujKpuEPMCX6U4WylrUDZ9JyUG0VpVZa7CNfq5E="
    ];
  };
}
