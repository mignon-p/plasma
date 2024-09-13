FROM ubuntu:22.04 AS build

ARG DEBIAN_FRONTEND=noninteractive
ENV TERM=xterm-256color

RUN apt-get update
RUN apt-get install -y --no-install-recommends tzdata apt-utils locales

# Configure timezone
RUN ln -fs /usr/share/zoneinfo/America/Los_Angeles /etc/localtime
RUN dpkg-reconfigure tzdata

# Configure locales
RUN sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && \
    dpkg-reconfigure --frontend=noninteractive locales && \
    update-locale LANG=en_US.UTF-8
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8
RUN apt-get install -y software-properties-common

RUN apt-get update && apt-get install -y \
    build-essential \
    curl \
    git \
    ninja-build \
    cmake \
    sudo \
    libyaml-dev \
    libicu-dev \
    libssl-dev \
    libavahi-client-dev \
    python2.7-dev \
    libboost-all-dev

# Setup Bash niceities
COPY etc/skel/.bashrc /etc/skel/
COPY etc/skel/.profile /etc/skel/
RUN cp -v /etc/skel/.bashrc /root
RUN cp -v /etc/skel/.profile /root

# Silence ownership warnings inside container
RUN git config --system --add safe.directory /work

WORKDIR /work
COPY entrypoint.sh /entrypoint.sh
ENTRYPOINT [ "/entrypoint.sh" ]
