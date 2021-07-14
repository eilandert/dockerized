FROM    eilandert/ubuntu-base:rolling
LABEL   maintainer="Thijs Eilander <eilander@myguard.nl>"
ENV     DEBIAN_FRONTEND="noninteractive"

## Install packages
RUN \
  apt-get update \
  && apt-get install --no-install-recommends -y \
    s6 \
    cron \
    nginx \
    ca-certificates \
    reprepro \
    openssh-server \
    devscripts \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

## Repository volume
VOLUME /repo

## Copy configurations and scripts
COPY ./repo /tpl-repo
COPY ./services /services
ADD ./sh/start.sh /

## Finishing installation
RUN \
  # Scripts
  chmod +x /start.sh \
  && echo "export PATH=/repo/bin:${PATH}" >> /root/.bashrc \
  # Services
  && chmod +x /services/cron/* \
  && chmod +x /services/nginx/* \
  && chmod +x /services/sshd/* \
  # Symlinks
  && rm /etc/nginx/sites-available/default \
  && ln -s /repo/conf/nginx_site /etc/nginx/sites-available/default \
  && ln -s /repo/ssh /root/.ssh \
  && ln -s /repo/gnupg /root/.gnupg

# Start
ENV PATH "/repo/bin:${PATH}"
EXPOSE 22 80
ENTRYPOINT ["/start.sh"]
CMD []
