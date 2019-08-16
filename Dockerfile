FROM ubuntu:16.04

MAINTAINER Li JIANG <li.jiang@orange.com>

# Set non interactive frontend during build
ENV DEBIAN_FRONTEND=noninteractive

#  Set locale and lang
ENV LC_ALL=C.UTF-8
ENV LANG=C.UTF-8

# Set local timezone
ENV TZ=Asia/shanghai
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Setup search path for shared libraries
ENV LD_LIBRARY_PATH="/lib/aarch64-linux-gnu:${LD_LIBRARY_PATH}"
ENV LD_LIBRARY_PATH="/usr/lib/aarch64-linux-gnu/tegra:${LD_LIBRARY_PATH}"
ENV LD_LIBRARY_PATH="/usr/lib/aarch64-linux-gnu:${LD_LIBRARY_PATH}"
ENV LD_LIBRARY_PATH="/usr/local/cuda-10.0/lib64:${LD_LIBRARY_PATH}"
ENV LD_LIBRARY_PATH="/usr/local/lib/:${LD_LIBRARY_PATH}"
ENV LD_LIBRARY_PATH="/opt/archiconda3/lib:${LD_LIBRARY_PATH}"

# Setup capabilties for cuda
ENV NVIDIA_VISIBLE_DEVICES all
ENV NVIDIA_DRIVER_CAPABILITIES compute,utility
ENV NVIDIA_REQUIRE_CUDA "cuda>=10.0"
ENV CUDA_VERSION 10.0
ENV APT_KEY_DONT_WARN_ON_DANGEROUS_USAGE=DontWarn

# Install common packages
RUN apt-get update && \
    apt-get install -y \
    apt-utils \
    automake \
    build-essential \
    bzip2 \
    ca-certificates \
    curl \
    dnsutils \
    file \
    freeglut3-dev \
    git \
    gnupg2 \
    hdf5-tools \
    htop \
    iotop \
    iputils-ping \
    less \
    libcurl3-dev \
    libfreetype6-dev \
    libglu1-mesa \
    libglu1-mesa-dev \
    libhdf5-dev \
    libhdf5-serial-dev \
    libjpeg8-dev \
    libpng-dev \
    libtool \
    libx11-dev \
    libxi-dev \
    libxmu-dev \
    libzmq3-dev \
    mlocate \
    nano \
    net-tools \
    nmap \
    ntp \
    openjdk-8-jdk\
    openjdk-8-jre-headless \
    patch \
    pkg-config \
    procps \
    python \
    python-dev \
    rsync \
    software-properties-common \
    sudo \
    swig \
    telnet \
    unzip \
    vim \
    wget \
    zip \
    zlib1g-dev \
    && \
    apt-get clean
RUN ln -sf /usr/lib/gcc/aarch64-linux-gnu/5/cc1plus /usr/local/bin/cc1plus

# Register bind-mounted and public NVIDIA repositories
COPY /host/apt-trusted-keys /tmp/
RUN apt-key add /tmp/apt-trusted-keys && \
    echo "deb file:///var/cuda-repo /" > /etc/apt/sources.list.d/cuda.list && \
    echo "deb http://international.download.nvidia.com/jetson/repos/common r32 main" > /etc/apt/sources.list.d/nvidia-l4t-apt-source.list && \
    echo "deb http://international.download.nvidia.com/jetson/repos/t210 r32 main" >> /etc/apt/sources.list.d/nvidia-l4t-apt-source.list

# Install all relevant CUDA libraries from repository on host, bind-mounted to reduce download time
RUN --mount=type=bind,readonly,source=/host/cuda-repo,target=/var/cuda-repo \
    apt-get update && \
    apt-get install -y \
    cuda-libraries-dev-$CUDA_VERSION \
    cuda-nvml-dev-$CUDA_VERSION \
    cuda-minimal-build-$CUDA_VERSION \
    cuda-command-line-tools-$CUDA_VERSION \
#    cuda-samples-$CUDA_VERSION \
    cuda-cublas-dev-$CUDA_VERSION \
    cuda-nsight-compute-addon-l4t-$CUDA_VERSION \
    cuda-toolkit-$CUDA_VERSION \
    cuda-tools-$CUDA_VERSION

## Install packages for ML such as CUDNN, TensorRT and python bindings -  repacked on host before using `make nano-one-cuda-ml-deb-repack`
RUN --mount=type=bind,readonly,source=/host/cuda-ml-repo,target=/var/cuda-ml-repo \
    cd /var/cuda-ml-repo && \
    dpkg -i *.deb

# Install anaconda for arm64s
RUN wget --quiet -O archiconda.sh https://github.com/Archiconda/build-tools/releases/download/0.2.3/Archiconda3-0.2.3-Linux-aarch64.sh && \
    sh archiconda.sh -b -p /opt/archiconda3 && \
    rm archiconda.sh
ENV PATH="/opt/archiconda3/bin:${PATH}"
RUN conda config --add channels gaiar && \
    conda config --add channels conda-forge && \
    conda config --add channels c4aarch64 && \
    conda update -n base --all && \
    conda install -y python=3.6.7 libiconv && \
    conda install -y conda-build && \
    conda install -y anaconda-client

# Install common python packages
RUN HDF5_DIR=/usr/lib/aarch64-linux-gnu/hdf5/serial/ pip install \
    absl-py \
    astor \
    future>=0.17.1 \
    gast \
    google-pasta \
    grpcio \
    h5py \
    keras-applications \
    keras-preprocessing \
    mock \
    numpy \
    pgen \
    portpicker \
    protobuf \
    psutil \
    py-cpuinfo \
    requests \
    six \
    termcolor \
    wrapt \
    flask \
	json5 \
	Pillow \
	requests


# Install Nvidia flavored tensorflow with gpu/cuda support
RUN pip install --no-cache-dir https://developer.download.nvidia.com/compute/redist/jp/v42/tensorflow-gpu/tensorflow_gpu-1.13.1+nv19.5-cp36-cp36m-linux_aarch64.whl

# Remove repository reference so child images do not have to bind-mount again
RUN rm /etc/apt/sources.list.d/cuda.list


# Install supervisord
RUN apt-get update && \
    apt-get install -y supervisor && \
    apt-get clean && \
    mkdir -p /var/log/supervisor

# Build bazel build
ENV BAZEL_VERSION=0.24.1
RUN wget --quiet https://github.com/bazelbuild/bazel/releases/download/$BAZEL_VERSION/bazel-$BAZEL_VERSION-dist.zip && \
    mkdir bazel-$BAZEL_VERSION && \
    unzip -q bazel-$BAZEL_VERSION-dist.zip -d bazel-$BAZEL_VERSION && \
    cd bazel-$BAZEL_VERSION && \
    ./compile.sh && \
    cp -f output/bazel /usr/local/bin && \
    cd .. && \
    rm -rf bazel*

# Build TF serving from source using bazel build including Python binding
WORKDIR /
ENV TF_SERVING_VERSION_GIT_BRANCH=master
ENV TF_SERVING_VERSION_GIT_COMMIT=master
# TensorRT version as provided by ml-base
ENV TF_TENSORRT_VERSION=5.1.6
# CUDNN version as provided by ml-base
ENV CUDNN_VERSION=7.5.0
# CUDA as provided by ml-base
ENV TF_NEED_CUDA=1
# CUDA capabilities of Jetson (Nano, TX1, TX2 and Xavier)
ENV TF_CUDA_COMPUTE_CAPABILITIES="5.3,6.2,7.2"
# Use TensorRT as provided in ml-base
ENV TF_NEED_TENSORRT=1
# Required for ncc
ENV TMP=/tmp
# Use python of Anaconda as provided in ml-base
ENV BAZEL_PYTHON=/opt/archiconda3/bin/python
COPY /.bazelrc /tmp/tfs.bazelrc
RUN mkdir -p /tensorflow-serving && \
    cd /tensorflow-serving && \
    git clone --branch=${TF_SERVING_VERSION_GIT_BRANCH} --recurse-submodules https://github.com/tensorflow/serving . && \
    git remote add upstream https://github.com/tensorflow/serving.git && \
    if [ "${TF_SERVING_VERSION_GIT_COMMIT}" != "head" ]; then git checkout ${TF_SERVING_VERSION_GIT_COMMIT} ; fi && \
    \
    mv -f /tmp/tfs.bazelrc .bazelrc && \
    \
    bazel build \
    --color=yes \
    --curses=yes \
    --jobs="1" \
    --verbose_failures \
    --output_filter=DONT_MATCH_ANYTHING \
    --config=cuda \
    --config=nativeopt \
    --config=jetson \
    --copt="-fPIC" \
    tensorflow_serving/model_servers:tensorflow_model_server && \
    cp /tensorflow-serving/bazel-bin/tensorflow_serving/model_servers/tensorflow_model_server /usr/local/bin/tensorflow_model_server && \
    \
    bazel build \
    --color=yes \
    --curses=yes \
    --jobs="1" \
    --verbose_failures \
    --output_filter=DONT_MATCH_ANYTHING \
    --config=cuda \
    --config=nativeopt \
    --config=jetson \
    --copt="-fPIC" \
    tensorflow_serving/tools/pip_package:build_pip_package && \
    bazel-bin/tensorflow_serving/tools/pip_package/build_pip_package \
    /tmp/pip && \
    pip --no-cache-dir install \
    /tmp/pip/tensorflow_serving_api_gpu-*.whl && \
    \
    cd / && \
    rm -rf /tmp/pip && \
    rm -rf /root/.cache && \
    rm -rf /tensorflow-serving

# Create model directory
ENV MODEL_BASE_PATH=/models
ENV MODEL_NAME=default
RUN mkdir -p ${MODEL_BASE_PATH}

# Install supervisord configuration
COPY /etc/supervisor/conf.d /etc/supervisor/conf.d 

# Expose ports
# grpc
EXPOSE 8500
# rest
EXPOSE 8501
# webservice
EXPOSE 80

