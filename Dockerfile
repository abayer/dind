FROM ubuntu:16.04

ENV DEBIAN_FRONTEND noninteractive
ENV DEBCONF_NONINTERACTIVE_SEEN true

USER root

# Let's start with some basic stuff.
RUN apt-get update -qq && apt-get install -qqy \
    apt-transport-https \
    ca-certificates \
    curl \
    lxc \
    iptables
    
# Install Docker from Docker Inc. repositories.
RUN curl -sSL https://get.docker.com/ | sh

# Install the magic wrapper.
ADD ./wrapdocker /usr/local/bin/wrapdocker
RUN chmod +x /usr/local/bin/wrapdocker

RUN groupadd docker || true
RUN groupmod -g 1000 docker

RUN apt-get install -y openssh-server
RUN mkdir -p /var/run/sshd
RUN useradd test -d /home/test && \
    mkdir -p /home/test/.ssh && \
    echo 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDzpxmTW9mH87DMkMSqBrSecoSHVCkKbW5IOO+4unak8M8cyn+b0iX07xkBn4hUJRfKA7ezUG8EX9ru5VinteqMOJOPknCuzmUS2Xj/WJdcq3BukBxuyiIRoUOXsCZzilR/DOyNqpjjI3iNb4los5//4aoKPCmLInFnQ3Y42VaimH1298ckEr4tRxsoipsEAANPXZ3p48gGwOf1hp56bTFImvATNwxMViPpqyKcyVaA7tXCBnEk/GEwb6MiroyHbS0VvBz9cZOpJv+8yQnyLndGdibk+hPbGp5iVAIsm28FEF+4FvlYlpBwq9OYuhOCREJvH9CxDMhbOXgwKPno9GyN kohsuke@atlas' > /home/test/.ssh/authorized_keys && \
    echo 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDagNSCDst/8z5oH9S5QWr+QNdx+haImY0FD3IQvKdD+eWI9zUbBgtoo/yYEbLvpTWiKsgT3Hw1F8mZ+/bd2Uv3lPyoG+TSzrHL4gSal6d1RWVjCOzSosciXVm4gRUvJjKXzaz8dOg+ii9yIrbeONNK0nlDUCAKy5YXSEl0avcPdUDyR3cStL6870SyanxAzktDw0n8xMq4F/alF3PZ002bcZJrmDeNVAwkP+uO2Tf8pN37SU+nApotZmlmZR32xYHnx+/OiQ7gOAVYmgNRMg0Kwh6Q73FcY3ZWCeNHwLnr95LoEAdj3On8Qr62VhGThuQNVCqBc6SeYjArfjijpcW9 jenkins-ci@localhost' >> /home/test/.ssh/authorized_keys && \
    chown -R test:test /home/test && \
    chmod 0600 /home/test/.ssh/authorized_keys && \
    echo "test:test" | chpasswd

# JDK is from Universe
RUN echo deb http://archive.ubuntu.com/ubuntu precise universe >> /etc/apt/sources.list
RUN apt-get install --no-install-recommends -y software-properties-common
RUN add-apt-repository ppa:openjdk-r/ppa
RUN apt-get update
RUN apt-get install --no-install-recommends -y openjdk-8-jdk openjdk-7-jdk
RUN apt-get install --no-install-recommends -y curl git wget ant vnc4server make expect firefox=45.0.2+build1-0ubuntu1

RUN apt-get update -qqy \
  && apt-get -qqy install \
    x11vnc \
    pyvnc2swf \
    xvfb \
    xorg \
    xserver-xorg-video-dummy \
      xfonts-100dpi \
  xfonts-75dpi \
  xfonts-scalable \
  xfonts-cyrillic

RUN apt-get -y install dbus libdbus-1-dev dbus-x11
RUN dbus-uuidgen > /etc/machine-id

ENV MAVEN_VERSION 3.3.9

RUN mkdir -p /usr/share/maven /usr/share/maven/ref \
  && curl -fsSL http://apache.osuosl.org/maven/maven-3/$MAVEN_VERSION/binaries/apache-maven-$MAVEN_VERSION-bin.tar.gz \
    | tar -xzC /usr/share/maven --strip-components=1 \
  && ln -s /usr/share/maven/bin/mvn /usr/bin/mvn

ENV MAVEN_HOME /usr/share/maven

ENV SCREEN_WIDTH 1680
ENV SCREEN_HEIGHT 1050
ENV SCREEN_DEPTH 24
ENV DISPLAY :99.0


RUN apt-get install -y zip dmsetup supervisor sudo
# Create log folder for supervisor and docker
RUN mkdir -p /var/log/supervisor
RUN mkdir -p /var/log/docker
RUN echo "test  ALL=(ALL)   NOPASSWD: ALL" >> /etc/sudoers

COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

ADD ./launch_wrapper /usr/local/bin/launch_wrapper
RUN chmod +x /usr/local/bin/launch_wrapper

RUN touch /root/.cloudbees-license
USER test

# Define additional metadata for our image.
VOLUME /var/lib/docker
ENTRYPOINT ["/usr/local/bin/launch_wrapper"]

