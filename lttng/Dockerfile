FROM ubuntu:16.04
MAINTAINER Anders Wallin

WORKDIR /root
ENV TERM xterm

ENV HOME /root
ENV DEBIAN_FRONTEND noninteractive

# Preparing packages needed by lttng 
RUN apt-get update
RUN apt-get install -y apt-utils
RUN apt-get install -y git libpopt-dev uuid-dev libxml2-dev automake autoconf libtool flex \
	bison make libc6 libc6-dev libglib2.0-0 libglib2.0-dev libpopt-dev python-pip python-dev
RUN apt-get install -y libelf-dev libdw-dev
#RUN apt-get install -y asciidoc xmlto

# Installing lttng repos
RUN (cd /root; git clone https://github.com/wallinux/lttng-test.git)
RUN apt-get install -y ncurses-bin
RUN (cd /root/lttng-test; make repo.clone)

# Building lttng repos
RUN (cd /root/lttng-test; make make stable-2.9.checkout)
RUN (cd /root/lttng-test; make ALL.userspace-rcu && make install.userspace-rcu)
RUN (cd /root/lttng-test; make ALL.lttng-ust && make install.lttng-ust)
RUN (cd /root/lttng-test; make ALL.lttng-tools && make install.lttng-tools)
RUN (cd /root/lttng-test; make ALL.babeltrace && make install babeltrace)

ADD live.sh /usr/local/bin/live
ENTRYPOINT ["/usr/local/bin/live"]

EXPOSE 5342 5343 5344
