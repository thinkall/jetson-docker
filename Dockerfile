# syntax=docker/dockerfile:experimental

FROM tensorflow/tensorflow:nightly-py3-jupyter

MAINTAINER Li JIANG <li.jiang@orange.com>

# Set non interactive frontend during build
ENV DEBIAN_FRONTEND=noninteractive

#  Set locale and lang
ENV LC_ALL=C.UTF-8
ENV LANG=C.UTF-8

# Set local timezone
ENV TZ=Asia/shanghai
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

RUN apt-get update && \
    apt-get install -y \
    apt-utils \
    automake \
    build-essential \
    ca-certificates \
    curl \
    git \
    gnupg2 \
    hdf5-tools \
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
    openjdk-8-jdk \
    openjdk-8-jre-headless \ 
    procps \
    python3 \
    python3-dev \
    python3-pip\
    swig \
    vim \
    wget && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN ln -sf /usr/lib/gcc/aarch64-linux-gnu/5/cc1plus /usr/local/bin/cc1plus

# Install common python packages 
RUN pip3 install pip -U && \
    pip config set global.index-url https://pypi.tuna.tsinghua.edu.cn/simple && \
    pip install -U --no-cache-dir absl-py astor future>=0.17.1 gast google-pasta \
    grpcio h5py keras-applications keras-preprocessing mock numpy \
    requests six wrapt flask json5 Pillow \
	



