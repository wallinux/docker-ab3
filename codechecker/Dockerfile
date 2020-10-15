FROM windriver/ubuntu1804_64
MAINTAINER Anders Wallin

USER root

# Set the locale
RUN locale-gen en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

RUN apt-get update
RUN apt-get install -y moreutils bc bsdmainutils

###############################################################
# add clang version 12
RUN apt-get install -y software-properties-common
RUN (wget https://apt.llvm.org/llvm.sh; chmod +x llvm.sh)
RUN ./llvm.sh 12

# Prepare for codechecker
RUN apt-get install -y clang clang-tidy build-essential curl doxygen \
    gcc-multilib git python-virtualenv python3-dev

# add newer nodejs version
RUN (curl -sL https://deb.nodesource.com/setup_12.x | bash -)
RUN apt-get install -y nodejs

# download codechecker
RUN git clone https://github.com/Ericsson/CodeChecker.git /opt/codechecker
RUN git -C /opt/codechecker/ checkout -b b6.14.0 v6.14.0

# build codechecker
RUN make -C /opt/codechecker venv
RUN (. /opt/codechecker/venv/bin/activate; make -C /opt/codechecker package)
