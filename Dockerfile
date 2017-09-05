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
        build-essential \
        # Developer Essentials
        curl git wget zip unzip \
        libfreetype6-dev \
        libpng12-dev \
        libzmq3-dev \
        mlocate \
        pkg-config \
        # Python 3.5
        python3.5 python3.5-dev python3-numpy python3-pip \
        software-properties-common \
        swig \
        zlib1g-dev \
        libcurl3-dev \
        openjdk-8-jdk\
        openjdk-8-jre-headless \
        && \
    # pip
    pip3 install --no-cache-dir --upgrade pip && \
    # For convenience, alisas (but don't sym-link) python & pip to python3 & pip3 as recommended in:
    echo "alias python='python3'" >> /root/.bash_aliases && \
    echo "alias pip='pip3'" >> /root/.bash_aliases && \
    # Set up grpc
    pip3 install --no-cache-dir mock grpcio && \
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
    export PYTHON_BIN_PATH = /usr/bin/python3 && \
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