FROM p4lang/behavioral-model:latest
MAINTAINER Antonin Bas <antonin@barefootnetworks.com>

# Default to using 2 make jobs, which is a good default for CI. If you're
# building locally or you know there are more cores available, you may want to
# override this.
ARG MAKEFLAGS=-j2

# Select the type of image we're building. Use `build` for a normal build, which
# is optimized for image size. Use `test` if this image will be used for
# testing; in this case, the source code and build-only dependencies will not be
# removed from the image.
ARG IMAGE_TYPE=build

# Select the compiler to use. GCC 5 is available as 'gcc'/'g++'. GCC 6 is
# available as 'gcc-6'/'g++-6'. Clang 3.8 is available as
# 'clang-3.8'/'clang++-3.8'.
ARG CC=gcc
ARG CXX=g++

ENV PI_DEPS automake \
            build-essential \
            clang-3.8 \
            clang-format-3.8 \
            g++ \
            g++-6 \
            libboost-dev \
            libboost-system-dev \
            libtool \
            libtool-bin \
            pkg-config \
            libjudy-dev \
            libreadline-dev \
            libpcap-dev \
            libmicrohttpd-dev \
            doxygen \
            valgrind
ENV PI_RUNTIME_DEPS libboost-system1.58.0 \
                    libjudydebian1 \
                    libpcap0.8 \
                    python
COPY . /PI/
WORKDIR /PI/
RUN apt-get update && \
    apt-get install -y --no-install-recommends software-properties-common && \
    add-apt-repository -y ppa:ubuntu-toolchain-r/test && \
    apt-get update && \
    apt-get install -y --no-install-recommends $PI_DEPS $PI_RUNTIME_DEPS && \
    ./autogen.sh && \
    ./configure --with-bmv2 --with-proto && \
    make && \
    make install-strip && \
    (test "$IMAGE_TYPE" = "build" && \
      apt-get purge -y $PI_DEPS && \
      apt-get autoremove --purge -y && \
      rm -rf /PI /var/cache/apt/* /var/lib/apt/lists/* && \
      echo 'Build image ready') || \
    (test "$IMAGE_TYPE" = "test" && \
      echo 'Test image ready')
