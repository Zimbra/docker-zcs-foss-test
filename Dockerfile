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
    wget && \
    apt-get install -y man psutils psmisc ruby-dev gcc && \
    apt-get clean

WORKDIR /tmp
# Install STAF to /usr/local/staf
# Unpack the QA soapvalidator tests to /opt/qa/soapvalidator
# Unpack the QA genesis tests to /opt/qa/genesis
# Add the STAF libraries to the END of the list of places where libraries are searched
# Some of the libraries included with STAF are wonky and will bork normal commands
# if they are loaded first.
RUN curl -L -O http://downloads.sourceforge.net/project/staf/staf/V3.4.26/STAF3426-setup-linux-amd64-NoJVM.bin
RUN curl -k -L -O https://docker.zimbra.com.s3.amazonaws.com/assets/soapvalidator-20171004.tar.gz
RUN curl -k -L -O https://docker.zimbra.com.s3.amazonaws.com/assets/genesis-20171004.tar
RUN curl -k -L -O https://docker.zimbra.com.s3.amazonaws.com/assets/genesis-20171004.conf
RUN mkdir -p /opt/qa && \
    mkdir -p /opt/qa/logs/soap-harness && \
    mkdir -p /opt/qa/logs/genesis && \
    mkdir -p /opt/qa/genesis/conf && \
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
    ldconfig && \
    gpg --keyserver keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 && \
    curl -sSL https://get.rvm.io | bash -s stable && \
    /bin/bash -c 'source /etc/profile.d/rvm.sh && rvm install 2.0.0 --with-zlib-directory=/usr/local/rvm/usr --with-openssl-directory=/usr/local/rvm/usr' && \
    /bin/bash -c 'source /etc/profile.d/rvm.sh && gem install soap4r-spox log4r net-ldap json httpclient' && \
    /bin/bash -c 'source /etc/profile.d/rvm.sh && rvm cleanup all' && \
    apt-get clean

COPY ./init-test-container /opt/qa/init
RUN  chmod +x /opt/qa/init
ENTRYPOINT ["/opt/qa/init"]
