ARG debianversion=buster
FROM debian:${debianversion:-buster} as swh-common
LABEL maintainer="Software Heritage <sysop@softwareheritage.org>"
ENV PROJECT_NAME swh-base

RUN export DEBIAN_FRONTEND=noninteractive && \
  apt-get update && apt-get upgrade -y && \
  apt-get install -y \
    apt-transport-https \
	curl \
	lsb-release \
 	wait-for-it


RUN echo deb http://deb.debian.org/debian/ $(lsb_release -sc)-backports main \
         > /etc/apt/sources.list.d/backports.list

RUN echo deb [trusted=yes] https://debian.softwareheritage.org/ $(lsb_release -sc)-swh main  \
         > /etc/apt/sources.list.d/softwareheritage.list

RUN mkdir /etc/softwareheritage
RUN mkdir -p /var/run/gunicorn/swh
RUN mkdir -p /var/lib/swh
RUN mkdir -p /srv/softwareheritage/objects

ENV SWH_CONFIG_FILENAME=/etc/softwareheritage/config.yml
ENV LC_ALL=C.UTF-8

##################################
# BASE services
##################################

FROM swh-common as swh-base
ARG SWH_VER
ENV SWH_VER=${SWH_VER}

RUN export DEBIAN_FRONTEND=noninteractive && \
  apt-get update && \
  apt-get install -y \
    -t $(lsb_release -sc)-backports \
	--no-install-recommends \
	gunicorn \
	postgresql-client \
	python3-dulwich \
    python3-swh.journal \
    python3-swh.objstorage \
#    python3-swh.objstorage.cloud \
#    python3-swh.objstorage.rados \
    python3-swh.scheduler \
    python3-swh.storage \
	&& \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/*
## still missing: vault, deposit

COPY conf/logconfig.ini /etc/gunicorn/logconfig.ini
COPY conf/gunicorn.cfg /etc/gunicorn/swh.cfg
COPY tools/*.sh /srv/softwareheritage/utils/
COPY tools/*.sql /srv/softwareheritage/utils/
RUN chmod +x /srv/softwareheritage/utils/*.sh

COPY base/entrypoint.sh /
ENTRYPOINT ["/entrypoint.sh"]

##################################
# WEB
##################################
FROM swh-common as swh-web
ARG SWH_VER
ENV SWH_VER=${SWH_VER}

ENV DJANGO_SETTINGS_MODULE=swh.web.settings.production

RUN export DEBIAN_FRONTEND=noninteractive && \
  apt-get update && \
  apt-get install -y --no-install-recommends \
    -t $(lsb_release -sc)-backports \
	gunicorn \
	python3-magic \
    python3-swh.web \
	&& \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/*

COPY conf/logconfig.ini /etc/gunicorn/logconfig.ini
COPY conf/gunicorn.cfg /etc/gunicorn/swh.cfg

COPY web/entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]

##################################
# Mirror (replayer)
##################################
FROM swh-common as swh-replayer
ARG SWH_VER
ENV SWH_VER=${SWH_VER}

RUN export DEBIAN_FRONTEND=noninteractive && \
  apt-get update && \
  apt-get install -y \
    -t $(lsb_release -sc)-backports \
	--no-install-recommends \
    python3-swh.journal \
    python3-swh.objstorage \
    python3-swh.objstorage.replayer \
    python3-swh.storage \
	&& \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/*

COPY tools/*.sh /srv/softwareheritage/utils/
COPY tools/*.sql /srv/softwareheritage/utils/
RUN chmod +x /srv/softwareheritage/utils/*.sh

COPY replayer/entrypoint.sh /
ENTRYPOINT ["/entrypoint.sh"]
