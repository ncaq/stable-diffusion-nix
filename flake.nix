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
    stable-diffusion-stability-ai = {
      url = "github:Stability-AI/stablediffusion/cf1d67a6fd5ea1aa600c4df58e5b47da45f6bdbf";
      flake = false;
    };
    stable-diffusion-webui-assets = {
      url = "github:AUTOMATIC1111/stable-diffusion-webui-assets/6f7db241d2f8ba7457bac5ca9753331f0c266917";
      flake = false;
    };
    generative-models = {
      url = "github:Stability-AI/generative-models/45c443b316737a4ab6e40413d7794a7f5657c19f";
      flake = false;
    };
    k-diffusion = {
      url = "github:crowsonkb/k-diffusion/ab527a9a6d347f364e3d185ba6d714e22d80cb3c";
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
            python312 = prev.python312.override {
              packageOverrides = pyFinal: pyPrev: {
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
                  doCheck = false; # No tests
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
            config = {
              allowUnfree = true;
              cudaSupport = true;
            };
            overlays = [ pythonOverlay ];
          };

          # Python environment with all dependencies
          pythonEnv = pkgs'.python312.withPackages (
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
            buildPhase = ''
              # Copy source
              cp -r . $TMPDIR/webui
              cd $TMPDIR/webui
              # Copy repositories and make them writable
              mkdir -p repositories
              cp -r ${inputs.generative-models} repositories/generative-models
              cp -r ${inputs.k-diffusion} repositories/k-diffusion
              cp -r ${inputs.stable-diffusion-stability-ai} repositories/stable-diffusion-stability-ai
              cp -r ${inputs.stable-diffusion-webui-assets} repositories/stable-diffusion-webui-assets
              chmod -R u+w repositories

              # Patch Gradio to disable runtime pyi generation
              cat > gradio_pyi_patch.py << 'PYTHON_EOF'
              import sys
              import importlib.util
              # Load the original gradio module
              spec = importlib.util.find_spec("gradio.component_meta")
              module = importlib.util.module_from_spec(spec)

              # Replace create_or_modify_pyi with a no-op
              def create_or_modify_pyi(*args, **kwargs):
                  pass

              module.create_or_modify_pyi = create_or_modify_pyi
              sys.modules["gradio.component_meta"] = module
              spec.loader.exec_module(module)
              PYTHON_EOF

              # Create a simple monkey patch for Gradio
              cat > modules/gradio_patch.py << 'PYTHON_EOF'
              import sys

              # Monkey patch Gradio's create_or_modify_pyi before it's used
              def patch_gradio():
                  try:
                      import gradio.component_meta as cm
                      cm.create_or_modify_pyi = lambda *args, **kwargs: None
                  except:
                      pass

              patch_gradio()
              PYTHON_EOF

              # Add the patch import at the top of ui_components.py
              sed -i '1a import gradio_patch' modules/ui_components.py

              # Fix Gradio IOComponent compatibility issue
              sed -i 's/gr.components.IOComponent/gr.components.Component/g' modules/gradio_extensons.py
              sed -i 's/gradio.components.IOComponent/gradio.components.Component/g' modules/ui_tempdir.py

              # Fix Gradio deprecation warning issue
              sed -i '/warnings.filterwarnings.*gr.deprecation.GradioDeprecationWarning/d' modules/ui.py

              # Fix pytorch_lightning import issue
              sed -i 's/from pytorch_lightning.utilities.distributed/from pytorch_lightning.utilities.rank_zero/' repositories/stable-diffusion-stability-ai/ldm/models/diffusion/ddpm.py

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
