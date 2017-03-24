FROM ubuntu:16.04
MAINTAINER Anders Wallin

WORKDIR /root

ENV TERM xterm
ENV HOME /root
ENV DEBIAN_FRONTEND noninteractive

ADD lttng/.gitconfig /root/.gitconfig

# Preparing packages needed by lttng 
RUN apt-get update
RUN apt-get install -y apt-utils
RUN apt-get install -y git libpopt-dev uuid-dev libxml2-dev automake autoconf libtool flex \
	bison make libc6 libc6-dev libglib2.0-0 libglib2.0-dev libpopt-dev python-pip python-dev
RUN apt-get install -y libelf-dev libdw-dev
RUN apt-get install -y asciidoc xmlto

# Installing lttng repos
RUN (git clone https://github.com/wallinux/lttng-test.git)
RUN apt-get install -y ncurses-bin
RUN (cd lttng-test; make repo.clone)
RUN groupadd tracing

ENTRYPOINT ["/bin/sh"]
EXPOSE 5342 5343 5344
