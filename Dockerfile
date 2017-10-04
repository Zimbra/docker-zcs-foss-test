FROM ubuntu:16.04

# docker build . -t zimbra/soap-harness:latest
# docker run --network dockerzcsdevmachine_default --name soap --dns 10.0.0.2 --dns 8.8.8.8 --hostname soap.test  -it --entrypoint /bin/bash zimbra/soap-harness:latest
#   export PATH=/usr/local/staf/bin:$PATH
#   /usr/local/staf/startSTAFProc.sh 
#   STAF local service add service SOAP LIBRARY JSTAF EXECUTE /opt/qa/soapvalidator/bin/zimbrastaf.jar
#   STAF local service add service LOG LIBRARY STAFLog


# Install Basic Packages
RUN apt-get update && \
    apt-get install -y \
    ant \
    ant-contrib \
    build-essential \
    curl \
    dnsmasq \
    dnsutils \
    gettext \
    git \
    git-flow \
    linux-tools-common \
    maven \
    net-tools \
    npm \
    openjdk-8-jdk \
    python \
    python-pip \
    ruby \
    rsyslog \
    software-properties-common \
    vim \
    wget

WORKDIR /tmp
# Install STAF to /usr/local/staf
# Unpack the QA soapvalidator tests to /opt/qa/soapvalidator
# Add the STAF libraries to the END of the list of places where libraries are searched
# Some of the libraries included with STAF are wonky and will bork normal commands
# if they are loaded first.
RUN curl -L -O http://downloads.sourceforge.net/project/staf/staf/V3.4.26/STAF3426-setup-linux-amd64-NoJVM.bin
RUN curl -L -O https://docker.zimbra.com.s3.amazonaws.com/assets/soapvalidator-20171004.tar.gz
RUN curl -L -O https://docker.zimbra.com.s3.amazonaws.com/assets/genesis-20171004.tar
RUN curl -L -O https://docker.zimbra.com.s3.amazonaws.com/assets/genesis-20171004.conf
RUN mkdir -p /opt/qa && \
    mkdir -p /opt/qa/logs/soap-harness && \
    mkdir -p /opt/qa/logs/genesis && \
    tar xzvf /tmp/soapvalidator-20171004.tar.gz -C /opt/qa/ && \
    tar xvf /tmp/soapvalidator-20171004.tar.gz -C /opt/qa/ && \
    cp /tmp/genesis-20171004.conf /opt/qa/genesis/conf/genesis.conf.in && \
    chmod +x /tmp/STAF3426-setup-linux-amd64-NoJVM.bin && \
    /tmp/STAF3426-setup-linux-amd64-NoJVM.bin -i silent \
       -DACCEPT_LICENSE=1 \
       -DCHOSEN_INSTALL_SET=Custom \
       -DCHOSEN_INSTALL_FEATURE_LIST=STAF,ExtSvcs,Langs,Codepage && \
    rm /tmp/STAF3426-setup-linux-amd64-NoJVM.bin && \
    rm /tmp/soapvalidator-*.tar.gz && \
    rm /tmp/genesis* && \
    echo /usr/local/staf/lib > /etc/ld.so.conf.d/zzz-staf.conf && \
    ldconfig

COPY ./init-test-container /opt/qa/init
RUN  chmod +x /opt/qa/init

ENTRYPOINT ["/opt/qa/init"]
