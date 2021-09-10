FROM nvidia/cuda:11.4.1-cudnn8-devel-ubuntu20.04

RUN apt update && \
    apt install -y \
        curl \
        git \
        python3-dev \
        python3-pip \
        sudo \
        vim \
        wget && \
    apt autoremove -y && \
    apt clean -y && \
    rm -rf /var/lib/apt/lists/*

RUN curl https://get.docker.com | sh
