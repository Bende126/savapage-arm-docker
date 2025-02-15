# Alap kép megadása
FROM ubuntu:20.04

# Szükséges környezeti változók beállítása
ENV DEBIAN_FRONTEND=noninteractive
ENV SAVA_VERSION=1.5.0-final

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
    software-properties-common \
    avahi-daemon \
    avahi-discover \
    libnss-mdns \
    binutils \
    cpio \
    openjdk-11-jdk \
    supervisor \
    openssh-server \
    build-essential \
    git \
    libpam0g-dev \
    libcups2-dev && \
    apt-get clean

# savapage rendszerfelhasználó létrehozása és szükséges könyvtárak létrehozása
RUN useradd -r -s /bin/bash -d /opt/savapage savapage && \
    mkdir -p /opt/savapage /var/log/supervisor /run/sshd && \
    chown savapage:savapage /opt/savapage

# CUPS és Supervisor konfigurációs fájlok másolása
COPY config/cupsd.conf /etc/cups/cupsd.conf
COPY config/cups-browsed.conf /etc/cups/cups-browsed.conf
COPY config/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Alapértelmezett papírméret beállítása
COPY config/papersize /etc/papersize

# SavaPage telepítő letöltése és telepítése
RUN cd /opt/savapage && \
    wget https://www.savapage.org/download/installer/savapage-setup-${SAVA_VERSION}-linux-x64.bin -O savapage-setup-linux.bin && \
    chmod +x savapage-setup-linux.bin && \
    su savapage -c "./savapage-setup-linux.bin -e"

# xmlrpcpp könyvtár letöltése és fordítása
RUN cd /opt && \
    git clone https://gitlab.com/savapage/xmlrpcpp.git && \
    cd xmlrpcpp && \
    make && \
    # Másolás a megfelelő helyekre
    mkdir -p /usr/local/include/xmlrpcpp && \
    cp libXmlRpc.a /usr/local/lib/

# savapage-notifier, savapage-nss és savapage-pam forráskódjának letöltése és fordítása
RUN cd /opt && \
    git clone https://gitlab.com/savapage/savapage-cups-notifier.git && \
    cd savapage-cups-notifier && \
    make && \
    cp target/savapage-notifier /opt/savapage/savapage/providers/cups/linux-x64/ && \
    cd /opt && \
    git clone https://gitlab.com/savapage/savapage-nss.git && \
    cd savapage-nss && \
    make && \
    cp target/savapage-nss /opt/savapage/savapage/server/bin/linux-x64/ && \
    cd /opt && \
    git clone https://gitlab.com/savapage/savapage-pam.git && \
    cd savapage-pam && \
    make && \
    cp target/savapage-pam /opt/savapage/savapage/server/bin/linux-x64/


RUN cd /opt/savapage/savapage && \
    su savapage -c "./install -n -d /opt/savapage"

RUN /opt/savapage/MUST-RUN-AS-ROOT

# Supervisor indítása alapértelmezett parancsként
CMD ["/usr/bin/supervisord"]
