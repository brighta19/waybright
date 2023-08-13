# syntax=docker/dockerfile:1

FROM ubuntu:22.04


SHELL [ "/bin/bash", "-c" ]

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        apt-transport-https doxygen freerdp2-dev g++ gcc git gnupg graphviz hwdata make meson \
        ninja-build python3 python3-pip python3-setuptools python3-wheel weston wget xmlto \
        xsltproc xwayland xz-utils \
        libcairo2-dev libdrm-dev libgbm-dev libgles-dev libgles2 libgstreamer1.0-dev libinput-dev \
        libjpeg-dev liblcms2-dev libseat-dev libsystemd-dev libva-dev libwebp-dev \
        libxcb-composite0-dev libxcb-dri3-dev libxcb-icccm4-dev libxcb-present-dev \
        libxcb-res0-dev libxcb-render-util0-dev libxcb-xinput-dev libxkbcommon-dev libxcursor-dev \
        libxml++2.6-dev

# install dart. not included with above `apt-get install` since `gpg` (from gnupg package) wasn't installed
RUN wget -O- https://dl-ssl.google.com/linux/linux_signing_key.pub | gpg --dearmor -o /usr/share/keyrings/dart.gpg && \
    echo 'deb [signed-by=/usr/share/keyrings/dart.gpg arch=amd64] https://storage.googleapis.com/download.dartlang.org/linux/debian stable main' | tee /etc/apt/sources.list.d/dart_stable.list && \
    apt-get update && \
    apt-get install -y --no-install-recommends dart

# add this so wlroots can find wayland-scanner (a dependency) using pkgconfig
ENV PKG_CONFIG_PATH="/usr/local/lib64/pkgconfig:$PKG_CONFIG_PATH"

# add this so waybright.so can find wlroots.so
ENV LD_LIBRARY_PATH="/usr/local/lib64:$LD_LIBRARY_PATH"

ENV WAYLAND_VERSION=1.21.93
ENV WAYLAND_PROTOCOLS_VERSION=1.27
ENV WLROOTS_VERSION=0.16.2

WORKDIR /tmp

# build and install wayland
RUN wget -O- https://gitlab.freedesktop.org/wayland/wayland/-/releases/$WAYLAND_VERSION/downloads/wayland-$WAYLAND_VERSION.tar.xz | tar -xJ && \
    cd wayland-$WAYLAND_VERSION/ && \
    meson build/ && \
    ninja -C build/ install && \
    cd ../ && \
    rm -r wayland-$WAYLAND_VERSION/

# build and install wayland-protocols
RUN wget -O- https://gitlab.freedesktop.org/wayland/wayland-protocols/-/releases/$WAYLAND_PROTOCOLS_VERSION/downloads/wayland-protocols-$WAYLAND_PROTOCOLS_VERSION.tar.xz | tar -xJ && \
    cd wayland-protocols-$WAYLAND_PROTOCOLS_VERSION/ && \
    meson build/ && \
    ninja -C build/ install && \
    cd ../ && \
    rm -r wayland-protocols-$WAYLAND_PROTOCOLS_VERSION/

# build and install wlroots
RUN wget -O- https://gitlab.freedesktop.org/wlroots/wlroots/-/releases/$WLROOTS_VERSION/downloads/wlroots-$WLROOTS_VERSION.tar.gz | tar -xz && \
    cd wlroots-$WLROOTS_VERSION/ && \
    meson build/ && \
    ninja -C build/ install && \
    cd ../ && \
    rm -r wlroots-$WLROOTS_VERSION/


WORKDIR /
RUN useradd -m -s /bin/bash user
USER user

# add this so ffigen can find missing C standard library headers
RUN echo export CPATH="$(gcc --print-file-name=include):$CPATH" >> ~/.bashrc

CMD bash
