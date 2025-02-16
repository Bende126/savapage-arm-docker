# Alap kép megadása
FROM ubuntu:20.04

# Szükséges környezeti változók beállítása
ENV DEBIAN_FRONTEND=noninteractive
ENV USER_LIMIT=10000

# Rendszer frissítése és szükséges csomagok telepítése
RUN apt-get update && \
    apt-get install -y \
    cups \
    cups-bsd \
    poppler-utils \
    qpdf \
    imagemagick \
    wget \
    gnupg \
    rng-tools \
    software-properties-common \
    avahi-daemon \
    avahi-discover \
    libnss-mdns \
    binutils \
    cpio \
    openjdk-11-jdk \
    maven \
    g++ \
    make \
    pkg-config\
    zip \
    pgpgpg \
    supervisor \
    openssh-server \
    build-essential \
    git \
    libpam0g-dev \
    libpcsclite-dev \
    libcups2-dev && \
    apt-get clean

# savapage rendszerfelhasználó létrehozása és szükséges könyvtárak létrehozása
RUN useradd -r -s /bin/bash -d /opt/savapage savapage && \
    mkdir -p /opt/savapage /var/log/supervisor /run/sshd && \
    chown savapage:savapage /opt/savapage

RUN mkdir -p /opt/savapage/repos

COPY ./init.sh /opt/savapage/repos/init.sh

WORKDIR /opt/savapage/repos

RUN /opt/savapage/repos/init.sh

RUN cd /opt/savapage/repos/savapage-make && \
    git checkout master && \
    ./dev-git-all.sh "checkout master" && \
    cd /opt/savapage && \
    ./repos/savapage-make/dev-init.sh

RUN rm /opt/savapage/repos/savapage-core/src/main/java/org/savapage/core/community/MemberCard.java

COPY ./MemberCard.java /opt/savapage/repos/savapage-core/src/main/java/org/savapage/core/community/MemberCard.java

#build
RUN cd /opt/savapage/repos/savapage-make && \
    ./build.sh all-x64

# CUPS és Supervisor konfigurációs fájlok másolása
COPY config/cupsd.conf /etc/cups/cupsd.conf
COPY config/cups-browsed.conf /etc/cups/cups-browsed.conf
COPY config/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Alapértelmezett papírméret beállítása
COPY config/papersize /etc/papersize

RUN cp /opt/savapage/repos/savapage-make/target/savapage-setup-1.5.0-final-linux-x64.bin /opt/savapage/ && \
    chmod +x /opt/savapage/savapage-setup-1.5.0-final-linux-x64.bin && \
    cd /opt/savapage && \
    su savapage -c "./savapage-setup-1.5.0-final-linux-x64.bin -n"

RUN /opt/savapage/MUST-RUN-AS-ROOT

# Supervisor indítása alapértelmezett parancsként
CMD ["/usr/bin/supervisord"]

ENTRYPOINT ["/bin/bash", "-c"]