FROM nvcr.io/nvidia/l4t-base:r32.2
###FROM nvcr.io/nvidia/deepstream-l4t:4.0-19.07

###Ubuntu 18.04, python 3.6, tensorflow-gpu 1.14

MAINTAINER Li JIANG <bnujli@gmail.com>

# Install systems libs
RUN apt-get update && \
    apt-get install -y \
    apt-utils curl libcurl3-dev libfreetype6-dev libglu1-mesa libglu1-mesa-dev \
    libhdf5-dev hdf5-tools libhdf5-serial-dev libjpeg8-dev libpng-dev libtool \
    libx11-dev libxi-dev libxmu-dev libzmq3-dev openjdk-8-jdk \
    openjdk-8-jre-headless python3 python3-dev python3-pip vim wget && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install python packages
RUN HDF5_DIR=/usr/lib/aarch64-linux-gnu/hdf5/serial/  \
    pip3 install --extra-index-url https://pypi.tuna.tsinghua.edu.cn/simple  --no-cache-dir \
    astor future>=0.17.1 gast google-pasta \
    grpcio h5py keras-applications keras-preprocessing mock numpy \
    requests six wrapt flask json5 Pillow matplotlib celery

# Install tensorflow
RUN pip3 install --no-cache-dir https://developer.download.nvidia.cn/compute/redist/jp/v42/tensorflow-gpu/tensorflow_gpu-1.14.0+nv19.7-cp36-cp36m-linux_aarch64.whl

WORKDIR /workspace
