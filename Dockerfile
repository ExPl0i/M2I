FROM nvidia/cuda:11.1.1-cudnn8-runtime-ubuntu20.04

ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

# --- System deps + build Python 3.6.15 from source ---
RUN apt-get update && apt-get install -y --no-install-recommends \
      build-essential git curl ca-certificates \
      libssl-dev zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev \
      libffi-dev liblzma-dev libncursesw5-dev libgdbm-dev uuid-dev tk-dev \
      libgl1 libglib2.0-0 libsm6 libxext6 libxrender1 \
    && rm -rf /var/lib/apt/lists/*

# --- Download/build Python (IPv4 + retries + mirror/GitHub fallback) ---
ARG PYTHON_VERSION=3.6.15
RUN set -eux; \
    PYTGZ="Python-${PYTHON_VERSION}.tgz"; \
    URL1="https://www.python.org/ftp/python/${PYTHON_VERSION}/${PYTGZ}"; \
    URL2="https://www.mirrorservice.org/sites/www.python.org/ftp/python/${PYTHON_VERSION}/${PYTGZ}"; \
    URL3="https://github.com/python/cpython/archive/refs/tags/v${PYTHON_VERSION}.tar.gz"; \
    rm -f "/tmp/${PYTGZ}" /tmp/cpython.tgz; \
    fetch() { \
      url="$1"; out="$2"; \
      i=1; \
      while [ "$i" -le 8 ]; do \
        if curl -4fsSL --connect-timeout 20 --retry 0 "$url" -o "$out"; then \
          return 0; \
        fi; \
        sleep 2; \
        i=$((i+1)); \
      done; \
      return 1; \
    }; \
    (fetch "$URL1" "/tmp/${PYTGZ}" || true); \
    if [ ! -s "/tmp/${PYTGZ}" ]; then \
      (fetch "$URL2" "/tmp/${PYTGZ}" || true); \
    fi; \
    if [ -s "/tmp/${PYTGZ}" ]; then \
      tar -xzf "/tmp/${PYTGZ}" -C /tmp; \
    else \
      fetch "$URL3" /tmp/cpython.tgz; \
      tar -xzf /tmp/cpython.tgz -C /tmp; \
      mv "/tmp/cpython-${PYTHON_VERSION}" "/tmp/Python-${PYTHON_VERSION}"; \
    fi; \
    cd "/tmp/Python-${PYTHON_VERSION}"; \
    ./configure --prefix=/usr/local --enable-optimizations --with-ensurepip=install; \
    make -j"$(nproc)"; \
    make altinstall; \
    cd /; \
    rm -rf "/tmp/Python-${PYTHON_VERSION}" "/tmp/${PYTGZ}" /tmp/cpython.tgz

# Make `python` / `python3` point to Python 3.6
RUN ln -sf /usr/local/bin/python3.6 /usr/local/bin/python && \
    ln -sf /usr/local/bin/python3.6 /usr/local/bin/python3

# pip на Python 3.6: фиксируем версии и отключаем кэш флагом, а не ENV
RUN python -m ensurepip --upgrade && \
    python -m pip install --no-cache-dir --upgrade "pip<22" "setuptools<60" wheel

# --- Clone repo ---
ARG REPO_URL="https://github.com/ExPl0i/M2I.git"
ARG REPO_BRANCH="main"

WORKDIR /workspace
RUN git clone --depth 1 --branch "${REPO_BRANCH}" "${REPO_URL}" /workspace/M2I
WORKDIR /workspace/M2I

# --- Python deps (pip equivalent of conda.cuda111.yaml) ---
RUN python -m pip install --no-cache-dir --upgrade "pip<22" "setuptools<60" wheel && \
    python -m pip install --no-cache-dir \
      torch==1.8.1+cu111 torchvision==0.9.1+cu111 \
      -f https://download.pytorch.org/whl/torch_stable.html && \
    python -m pip install --no-cache-dir \
      numpy==1.19.2 scipy==1.5.4 \
      numba==0.53.1 llvmlite==0.36.0 \
      numpy-quaternion==2021.4.5.14.42.35 && \
    python -m pip install --no-cache-dir \
      cython==0.29.21 tqdm==4.60.0 matplotlib==3.3.4 \
      tensorflow-gpu==2.4.0 tensorflow-estimator==2.4.0 \
      tensorboard==2.5.0 tensorboard-data-server==0.6.1 tensorboard-plugin-wit==1.8.0 \
      waymo-open-dataset-tf-2-4-0==1.3.0 \
      protobuf==3.17.3 h5py==2.10.0 pillow==8.2.0 pyyaml==6.0 xmltodict==0.12.0 \
      absl-py==0.12.0 astunparse==1.6.3 blessings==1.7 cached-property==1.5.2 cachetools==4.2.2 \
      chardet==4.0.0 cycler==0.10.0 flatbuffers==1.12 future==0.18.2 gast==0.3.3 \
      google-auth==1.30.1 google-auth-oauthlib==0.4.4 google-pasta==0.2.0 \
      gpustat==0.6.0 nvidia-ml-py3==7.352.0 grpcio==1.32.0 \
      idna==2.10 importlib-metadata==4.5.0 keras-preprocessing==1.1.2 kiwisolver==1.3.1 \
      markdown==3.3.4 oauthlib==3.1.1 opt-einsum==3.3.0 pickle5==0.0.11 \
      psutil==5.8.0 pyasn1==0.4.8 pyasn1-modules==0.2.8 pyparsing==2.4.7 python-dateutil==2.8.1 \
      requests==2.25.1 requests-oauthlib==1.3.0 rsa==4.7.2 termcolor==1.1.0 urllib3==1.26.5 \
      werkzeug==2.0.1 wrapt==1.12.1 zipp==3.4.1

# --- Build Cython extension (as in README) ---
RUN cd src && \
    cython -a utils_cython.pyx && \
    python setup.py build_ext --inplace

CMD ["bash"]