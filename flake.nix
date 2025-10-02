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
          pythonOverlay = _final: prev: {
            python312 = prev.python312.override {
              packageOverrides = pyFinal: _pyPrev: {
                blendmodes = pyFinal.buildPythonPackage rec {
                  pname = "blendmodes";
                  version = "2022";
                  src = pyFinal.fetchPypi {
                    inherit pname version;
                    sha256 = "sha256-k2jxwekOhzS0lo8MrANpbg5acU/VfnS8bu/SXAQY/QM=";
                  };
                  propagatedBuildInputs = with pyFinal; [
                    numpy
                    aenum
                  ];
                };

                clip = pyFinal.buildPythonPackage {
                  pname = "clip";
                  version = "1.0";
                  src = prev.fetchFromGitHub {
                    owner = "openai";
                    repo = "CLIP";
                    rev = "a1d071733d7111c9c014f024669f959182114e33";
                    sha256 = "sha256-NOiKadc5DYvE94NEHPvlUn4e8lvW2k0NkyEACAxekGQ=";
                  };
                  propagatedBuildInputs = with pyFinal; [
                    torch
                    torchvision
                    numpy
                    pillow
                    ftfy
                    regex
                    tqdm
                  ];
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
                };

                # Override Gradio to use version 3.41.2 that stable-diffusion-webui expects
                gradio = pyFinal.buildPythonPackage rec {
                  pname = "gradio";
                  version = "3.41.2";
                  format = "pyproject";
                  src = pyFinal.fetchPypi {
                    inherit pname version;
                    sha256 = "sha256-lcYrUEGVq+M2PQFRZ86Eis3he3W4lKeaLeeMz8/YLLI=";
                  };
                  nativeBuildInputs = with pyFinal; [
                    hatchling
                    hatch-requirements-txt
                    hatch-fancy-pypi-readme
                    pythonRelaxDepsHook
                  ];
                  pythonRelaxDeps = [
                    "aiofiles"
                    "markupsafe"
                    "numpy"
                    "pillow"
                  ];
                  propagatedBuildInputs = with pyFinal; [
                    importlib-resources
                    aiofiles
                    altair
                    fastapi
                    ffmpy
                    gradio-client
                    httpx
                    huggingface-hub
                    jinja2
                    markdown-it-py
                    markupsafe
                    matplotlib
                    numpy
                    orjson
                    packaging
                    pandas
                    pillow
                    pydantic
                    pydub
                    python-multipart
                    pyyaml
                    requests
                    semantic-version
                    typing-extensions
                    uvicorn
                    websockets
                  ];
                };

                # gradio-client for Gradio 3.41.2
                gradio-client = pyFinal.buildPythonPackage rec {
                  pname = "gradio-client";
                  version = "0.5.0";
                  format = "pyproject";
                  src = pyFinal.fetchPypi {
                    pname = "gradio_client";
                    inherit version;
                    sha256 = "sha256-cJ6RweBzir5GrZ9FZdSQ7zaw8XzjRwUAF6+qRp7Xmmo=";
                  };
                  nativeBuildInputs = with pyFinal; [
                    hatchling
                    hatch-requirements-txt
                    hatch-fancy-pypi-readme
                  ];
                  propagatedBuildInputs = with pyFinal; [
                    httpx
                    huggingface-hub
                    packaging
                    requests
                    typing-extensions
                    websockets
                  ];
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
                };

                tomesd = pyFinal.buildPythonPackage rec {
                  pname = "tomesd";
                  version = "0.1.3";
                  src = pyFinal.fetchPypi {
                    inherit pname version;
                    sha256 = "sha256-Fbui6VL0ZDyDVZUeiS/akY3cy9/yI43DaNQr0Hj87ck=";
                  };
                  propagatedBuildInputs = with pyFinal; [ torch ];
                };

                # Override websockets to version 11.x for compatibility with gradio-client 0.5.0
                websockets = pyFinal.buildPythonPackage rec {
                  pname = "websockets";
                  version = "11.0.3";
                  format = "pyproject";
                  src = pyFinal.fetchPypi {
                    inherit pname version;
                    sha256 = "sha256-iPxR2aJrEPwzG+NE8XgSJKN1t4SI/DQ2IBhOlaSycBY=";
                  };
                  nativeBuildInputs = with pyFinal; [
                    setuptools
                    wheel
                  ];
                };
              };
            };
          };

          pkgs = import inputs.nixpkgs {
            inherit system;
            config = {
              allowUnfree = true;
              cudaSupport = true;
            };
            overlays = [ pythonOverlay ];
          };

          pythonEnv = pkgs.python312.withPackages (
            ps: with ps; [
              accelerate
              blendmodes
              clean-fid
              clip
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

          stable-diffusion-stability-ai = pkgs.stdenv.mkDerivation {
            pname = "stable-diffusion-stability-ai";
            version = "unstable-2022-11-23";
            src = pkgs.fetchFromGitHub {
              owner = "Stability-AI";
              repo = "stablediffusion";
              rev = "cf1d67a6fd5ea1aa600c4df58e5b47da45f6bdbf";
              sha256 = "sha256-yEtrz/JTq53JDI4NZI26KsD8LAgiViwiNaB2i1CBs/I=";
            };
            patches = [
              ./patch/01-pytorch-lightning-import-fix-repo.patch
            ];
            patchFlags = [ "-p0" ];
            installPhase = ''
              mkdir -p $out
              cp -r . $out/
            '';
          };

          stable-diffusion-webui-assets = pkgs.fetchFromGitHub {
            owner = "AUTOMATIC1111";
            repo = "stable-diffusion-webui-assets";
            rev = "6f7db241d2f8ba7457bac5ca9753331f0c266917";
            sha256 = "sha256-gos24/VHz+Es834ZfMVdu3L9m04CR0cLi54bgTlWLJk=";
          };

          generative-models = pkgs.fetchFromGitHub {
            owner = "Stability-AI";
            repo = "generative-models";
            rev = "45c443b316737a4ab6e40413d7794a7f5657c19f";
            sha256 = "sha256-qaZeaCfOO4vWFZZAyqNpJbTttJy17GQ5+DM05yTLktA=";
          };

          k-diffusion = pkgs.fetchFromGitHub {
            owner = "crowsonkb";
            repo = "k-diffusion";
            rev = "ab527a9a6d347f364e3d185ba6d714e22d80cb3c";
            sha256 = "sha256-tOWDFt0/hGZF5HENiHPb9a2pBlXdSvDvCNTsCMZljC4=";
          };

          stable-diffusion-webui = pkgs.stdenv.mkDerivation {
            pname = "stable-diffusion-webui";
            version = "unstable-2024-07-25";
            src = inputs.stable-diffusion-webui;

            # Apply patches for main source
            patches = [
              ./patch/02-pydantic-v2-compatibility.patch
              ./patch/03-config-states-writable-dir.patch
            ];
            patchFlags = [
              "-p0"
              "--binary" # CRLFファイルが存在するのでバイナリ扱いします。
            ];

            buildInputs = with pkgs; [
              cudaPackages.cudatoolkit
              cudaPackages.cudnn
              git
              pythonEnv
            ];

            buildPhase = ''
              # Copy source
              cp -r . $TMPDIR/webui
              cd $TMPDIR/webui
              # Copy repositories and make them writable
              mkdir -p repositories
              cp -r ${generative-models} repositories/generative-models
              cp -r ${k-diffusion} repositories/k-diffusion
              cp -r ${stable-diffusion-stability-ai} repositories/stable-diffusion-stability-ai
              cp -r ${stable-diffusion-webui-assets} repositories/stable-diffusion-webui-assets
              chmod -R u+w repositories
              cd -
            '';
            installPhase = ''
              mkdir -p $out/share/stable-diffusion-webui
              cp -r $TMPDIR/webui/* $out/share/stable-diffusion-webui/
              # Create wrapper script
              mkdir -p $out/bin
              cat > $out/bin/stable-diffusion-webui << EOF
              #!/usr/bin/env bash
              # Use XDG Base Directory specification
              DATA_DIR="\''${XDG_DATA_HOME:-\$HOME/.local/share}/stable-diffusion-webui"
              # Create base directory
              mkdir -p "\$DATA_DIR"
              cd $out/share/stable-diffusion-webui
              export PYTHONPATH=$out/share/stable-diffusion-webui:$out/share/stable-diffusion-webui/modules
              export GRADIO_ANALYTICS_ENABLED=False
              exec ${pythonEnv}/bin/python webui.py \
                --skip-python-version-check \
                --skip-install \
                --skip-torch-cuda-test \
                --data-dir "\$DATA_DIR" \
                "\$@"
              EOF
              chmod +x $out/bin/stable-diffusion-webui
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
          devShells.default = pkgs.mkShell {
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
