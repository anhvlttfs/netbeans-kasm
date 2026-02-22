FROM kasmweb/ubuntu-noble-desktop:x86_64-1.17.0-rolling-daily
USER root

ENV HOME="/home/kasm-default-profile"
ENV STARTUPDIR="/dockerstartup"
ENV INST_SCRIPTS="$STARTUPDIR/install"
WORKDIR $HOME

ENV DEBIAN_FRONTEND="noninteractive"
ENV TZ="Etc/UTC"

######### Customize Container Here ###########

RUN printf '%s\n' '#!/bin/sh' 'exit 101' > /usr/sbin/policy-rc.d && chmod +x /usr/sbin/policy-rc.d \
    && printf '%s\n' '#!/bin/sh' 'exit 0' > /usr/local/bin/systemctl-fake && chmod +x /usr/local/bin/systemctl-fake \
    && ln -sf /usr/local/bin/systemctl-fake /bin/systemctl

# Register MSSQL Repo
RUN curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | sudo gpg --dearmor -o /usr/share/keyrings/microsoft-prod.gpg
RUN curl -fsSL https://packages.microsoft.com/config/ubuntu/24.04/mssql-server-2025.list | sudo tee /etc/apt/sources.list.d/mssql-server-2025.list

# Update & install required packages
RUN apt update && apt full-upgrade -y \
    && apt dist-upgrade -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" \
    && apt install -y gcc g++ gdb net-tools build-essential uuid-dev python3 make cmake automake \
    autoconf curl git gzip tar nodejs npm mssql-server tree htop unzip apt-transport-https maven default-jdk \
    && apt autoremove -y \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

## Installing Azure Data Studio
RUN curl -o /tmp/azuredatastudio-linux-1.52.0.deb https://download.microsoft.com/download/6b2bfeac-9c1b-4182-9a2f-ce86ff8cc371/azuredatastudio-linux-1.52.0.deb \
    && apt install -y /tmp/azuredatastudio-linux-1.52.0.deb -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" \
    && rm /tmp/azuredatastudio-linux-1.52.0.deb

## Installing Netbeans
RUN mkdir -p /usr/netbeans \
    && curl -o /tmp/netbeans-28-bin.zip https://dlcdn.apache.org/netbeans/netbeans/28/netbeans-28-bin.zip \
    && unzip /tmp/netbeans-28-bin.zip -d /home/kasm-user \
    && rm /tmp/netbeans-28-bin.zip \
    && chmod +x /home/kasm-user/netbeans/bin/netbeans
COPY ./netbeans.desktop /home/kasm-user/Desktop/netbeans.desktop
RUN chown -R 1000:0 /home/kasm-user/Desktop  \
    && chmod 644 /home/kasm-user/Desktop/netbeans.desktop

## Installing tomcat 10.1
RUN curl -o /tmp/apache-tomcat-10.1.52.zip https://dlcdn.apache.org/tomcat/tomcat-10/v10.1.52/bin/apache-tomcat-10.1.52.zip \
    && unzip /tmp/apache-tomcat-10.1.52.zip -d /home/kasm-user \
    && rm /tmp/apache-tomcat-10.1.52.zip

######### End Customizations ###########

RUN chown 1000:0 $HOME
RUN $STARTUPDIR/set_user_permission.sh $HOME || true

ENV HOME="/home/kasm-user"
WORKDIR $HOME
RUN mkdir -p $HOME && chown -R 1000:0 $HOME

USER 1000