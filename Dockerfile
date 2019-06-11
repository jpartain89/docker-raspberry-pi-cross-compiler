FROM debian:stretch

RUN apt-get update \
 && DEBIAN_FRONTEND=noninteractive apt-get install -y apt-utils \
 && DEBIAN_FRONTEND=noninteractive dpkg-reconfigure apt-utils \
 && DEBIAN_FRONTEND=noninteractive apt-get install -y \
        automake \
        cmake \
        curl \
        fakeroot \
        g++ \
        git \
        make \
        runit \
        sudo \
        xz-utils

# Here is where we hardcode the toolchain decision.
ENV HOST=arm-linux-gnueabihf \
    TOOLCHAIN=gcc-linaro-arm-linux-gnueabihf-raspbian-x64 \
    RPXC_ROOT=/rpxc

#    TOOLCHAIN=arm-rpi-4.9.3-linux-gnueabihf \
#    TOOLCHAIN=gcc-linaro-arm-linux-gnueabihf-raspbian-x64 \

WORKDIR $RPXC_ROOT
RUN curl -L https://github.com/raspberrypi/tools/tarball/master \
  | tar --wildcards --strip-components 3 -xzf - "*/arm-bcm2708/$TOOLCHAIN/"

ENV ARCH=arm \
    CROSS_COMPILE=$RPXC_ROOT/bin/$HOST- \
    PATH=$RPXC_ROOT/bin:$PATH \
    QEMU_PATH=/usr/bin/qemu-arm-static \
    QEMU_EXECVE=1 \
    SYSROOT=$RPXC_ROOT/sysroot

WORKDIR $SYSROOT
RUN curl -Ls https://github.com/schachr/docker-raspbian-stretch/raw/master/raspbian.image.tar.xz \
    | tar -xJf - \
 && curl -Ls https://github.com/resin-io-projects/armv7hf-debian-qemu/raw/master/bin/qemu-arm-static \
    > $SYSROOT/$QEMU_PATH \
 && chmod +x $SYSROOT/$QEMU_PATH \
 && mkdir -p $SYSROOT/build

COPY image/ /

RUN chroot $SYSROOT $QEMU_PATH /bin/sh -c '\
        echo "deb http://archive.raspbian.org/raspbian stretch main contrib non-free firmware rpi" \
            >> /etc/apt/sources.list \
        && echo "deb http://archive.raspbian.org/raspbian stretch-staging main contrib non-free firmware rpi" \
            >> /etc/apt/sources.list \
        && sudo apt-get update \
        && DEBIAN_FRONTEND=noninteractive sudo apt-get install -y apt-utils \
        && DEBIAN_FRONTEND=noninteractive sudo dpkg-reconfigure apt-utils \
        && DEBIAN_FRONTEND=noninteractive sudo apt-get upgrade -y \
        && DEBIAN_FRONTEND=noninteractive sudo apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 \
            0xF1656F24C74CD1D8 \
        && echo "deb-src [arch=amd64] http://nyc2.mirrors.digitalocean.com/mariadb/repo/10.3/debian stretch main" \
            >> /etc/apt/sources.list.d/mariadb.list \
        && sudo apt-get update \
        && DEBIAN_FRONTEND=noninteractive sudo apt-get upgrade -y \
        && DEBIAN_FRONTEND=noninteractive sudo apt-get install -y \
                libc6-dev \
                symlinks \
        && DEBIAN_FRONTEND=noninteractive sudo apt-get build-dep \
            mariadb-server-10.3 \
        && symlinks -cors /'

WORKDIR /build
ENTRYPOINT [ "/rpxc/entrypoint.sh" ]
