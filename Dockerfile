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

RUN apt-get update && \
    #
    # Prerequisites
    #
    apt-get install -y --no-install-recommends \
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
        # Tensorflow serving still relies on python2
        #
        python2.7 python-dev python-numpy python-pip \
        # Python 3.5
        python3.5 python3.5-dev python3-numpy python3-pip \
        software-properties-common \
        swig \
        zlib1g-dev \
        libcurl3-dev && \
    # pip
    pip3 install --no-cache-dir --upgrade pip && \
    # TensorFlow Serving Python API PIP package
    pip2 install --no-cache-dir --upgrade pip && \
    pip2 install --no-cache-dir mock grpcio tensorflow-serving-api && \
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
    # Install Tensorflow serving
    #
    # Python Configuration Error: 'PYTHON_BIN_PATH' environment variable is not set
    # <https://github.com/tensorflow/tensorflow/issues/9436>
    # Since use /bin/sh, should follow the UNIX export command <https://stackoverflow.com/questions/7328223/unix-export-command>
    # PYTHON_BIN_PATH=/usr/bin/python3 && \
    # export PYTHON_BIN_PATH && \
    # PYTHON_LIB_PATH=/usr/local/lib/python3.5/dist-packages && \
    # export PYTHON_LIB_PATH && \
    git clone --recurse-submodules https://github.com/tensorflow/serving && \
    # remove repository meta and index
    rm -r serving/.git && \
    # configurate original tensorflow
    cd serving/tensorflow && \
    ./configure && \
    cd .. && \
    # build entire serving tree
    bazel build -c opt //tensorflow_serving/... && \
    # client deployment directory
    cd / && \
    mkdir /client


WORKDIR /serving

CMD ["/bin/bash"]