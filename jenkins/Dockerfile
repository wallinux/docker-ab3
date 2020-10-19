FROM jenkins/jenkins
MAINTAINER Anders Wallin

USER root

RUN apt-get update
RUN apt-get install -y make bsdmainutils libltdl7

RUN usermod -g users jenkins
