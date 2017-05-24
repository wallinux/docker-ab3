FROM saxofon/wrlinux_builder:9
MAINTAINER Anders Wallin

ENV TERM xterm
ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update
RUN apt-get -y upgrade
RUN apt-get install -y texi2html chrpath diffstat subversion \
    libgl1-mesa-dev libglu1-mesa-dev libsdl1.2-dev texinfo gawk \
    gcc gcc-multilib help2man g++ git-core python-gtk2 bash diffutils \
    xz-utils make file screen bzip2 wget cpio
