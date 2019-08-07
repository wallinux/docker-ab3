ARG IMAGENAME=ubuntu:16.04
FROM $IMAGENAME

MAINTAINER Anders Wallin

WORKDIR /root

ENV TERM xterm
ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update
RUN apt-get -y upgrade
RUN apt-get install -y apt-utils
RUN apt-get install -y build-essential bison flex git tig tmux
RUN apt-get install -y qemu g++-arm-linux-gnueabihf
RUN apt-get install -y libncurses5-dev libncursesw5-dev

RUN git clone git://git.denx.de/u-boot.git

ADD u-boot/.gitconfig /root/.gitconfig
ADD u-boot/.tmux.conf /root/.tmux.conf
ADD u-boot/build /root/build

ENTRYPOINT ["/bin/sh"]
