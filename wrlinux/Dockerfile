FROM saxofon/wrlinux_builder:9
MAINTAINER Anders Wallin

ENV TERM vt100

RUN dpkg --add-architecture i386
RUN apt-get update
RUN DEBIAN_FRONTEND=noninteractive; apt-get -y upgrade
RUN DEBIAN_FRONTEND=noninteractive; apt-get install -y apt-utils
RUN DEBIAN_FRONTEND=noninteractive; apt-get install -y \
    texi2html chrpath diffstat subversion \
    libgl1-mesa-dev libglu1-mesa-dev libsdl1.2-dev texinfo gawk \
    gcc gcc-multilib help2man g++ git-core python-gtk2 bash diffutils \
    xz-utils make file screen bzip2 wget cpio libncurses5:i386 libc6:i386
