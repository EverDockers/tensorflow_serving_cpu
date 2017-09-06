FROM ubuntu:16.04

MAINTAINER Baker Wang <baikangwang@hotmail.com>

ARG DEBIAN_FRONTEND=noninteractive

# Set up Bazel.
ENV BAZELRC /root/.bazelrc
# Install the most recent bazel release.
ENV BAZEL_VERSION 0.5.4
# Serving port
ENV SERVING_PORT 9000
# Client port
ENV CLIENT_PORT 8080

# Serving port & client port
EXPOSE $SERVING_PORT $CLIENT_PORT

RUN apt update && \
    #
    # Prerequisites
    #
    apt install -y --no-install-recommends \
        # Build tools
        build-essential g++ \
        # Developer Essentials
        curl git wget zip unzip \
        libfreetype6-dev \
        libpng12-dev \
        libzmq3-dev \
        pkg-config \
        #
        # Python 2.7
        # Tensorflow serving still relies on python2, exactly it's that GRPC still dosen't supprt python3
        #
        python2.7 python-dev python-numpy python-pip \
        # Python 3.5
        python3.5 python3.5-dev python3-numpy python3-pip \
        software-properties-common \
        swig \
        zlib1g-dev \
        libcurl3-dev && \
    # pip
    pip install --no-cache-dir --upgrade pip \
     # Fix No module named pkg_resources
     setuptools && \
    # Grpc
    pip install --no-cache-dir mock grpcio \
    # TensorFlow Serving Python API PIP package
     tensorflow-serving-api && \
    # grpc still dosen't support python3, hance won't install it
    pip3 install --no-cache-dir --upgrade pip \
     # Fix No module named pkg_resources
     setuptools && \
    # For convenience, alisas (but don't sym-link) python & pip to python3 & pip3 as recommended in:
    # http://askubuntu.com/questions/351318/changing-symlink-python-to-python3-causes-problems
    echo "alias python='python3'" >> /root/.bash_aliases && \
    echo "alias pip='pip3'" >> /root/.bash_aliases && \
    #
    # Clean up
    #
    apt-get clean && \
    apt autoremove && \
    rm -rf /var/lib/apt/lists/* && \
    #
    # Set up Bazel
    #
    mkdir /bazel && \
    cd /bazel && \
    curl -fSsL -O https://github.com/bazelbuild/bazel/releases/download/$BAZEL_VERSION/bazel-$BAZEL_VERSION-installer-linux-x86_64.sh && \
    curl -fSsL -o /bazel/LICENSE.txt https://raw.githubusercontent.com/bazelbuild/bazel/master/LICENSE && \
    chmod +x bazel-*.sh && \
    ./bazel-$BAZEL_VERSION-installer-linux-x86_64.sh && \
    cd / && \
    rm -f /bazel/bazel-$BAZEL_VERSION-installer-linux-x86_64.sh && \
    #
    # Install Tensorflow serving 1.3.0
    #
    # Install using apt-get
    # remove the old version
    apt remove tensorflow-model-server && \
    echo "deb [arch=amd64] http://storage.googleapis.com/tensorflow-serving-apt stable tensorflow-model-server tensorflow-model-server-universal" | sudo tee /etc/apt/sources.list.d/tensorflow-serving.list && \
    curl https://storage.googleapis.com/tensorflow-serving-apt/tensorflow-serving.release.pub.gpg | sudo apt-key add - && \
    apt update && apt install tensorflow-model-server && \
    apt upgrade tensorflow-model-server && \
    #
    # Clean up
    #
    apt-get clean && \
    apt autoremove && \
    rm -rf /var/lib/apt/lists/* && \
    # client deployment directory
    cd / && \
    mkdir /client

WORKDIR /

CMD ["/bin/bash"]