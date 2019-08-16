FROM nvcr.io/nvidia/deepstream-l4t:4.0-19.07

MAINTAINER Li JIANG <li.jiang@orange.com>


RUN apt-get update && \
    apt-get install -y \ 
    apt-utils \
    curl \
    openjdk-8-jdk \
    openjdk-8-jre-headless \ 
    python3 \
    python3-dev \
    python3-pip\ 
    vim \
    wget && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*


# Install common python packages 
RUN pip install pip -U && \
    pip config set global.index-url https://pypi.tuna.tsinghua.edu.cn/simple && \
    pip install -U --no-cache-dir absl-py astor future>=0.17.1 gast google-pasta \
    grpcio h5py keras-applications keras-preprocessing mock numpy \
    requests six wrapt flask json5 Pillow 
	

# Install Nvidia flavored tensorflow with gpu/cuda support
RUN pip install --no-cache-dir https://developer.download.nvidia.com/compute/redist/jp/v42/tensorflow-gpu/tensorflow_gpu-1.13.1+nv19.5-cp36-cp36m-linux_aarch64.whl


