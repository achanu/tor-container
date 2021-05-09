FROM quay.io/centos/centos:stream AS micro-build

RUN \
  mkdir -p /rootfs && \
  dnf install -y \
    --installroot /rootfs --releasever 8 \
    --setopt install_weak_deps=false --nodocs \
    coreutils-single \
    glibc-minimal-langpack \
    setup \
    openssl \
  && \
  cp -v /etc/yum.repos.d/*.repo /rootfs/etc/yum.repos.d/ && \
  && \
  dnf install -y \
    --installroot /rootfs \
    --setopt install_weak_deps=false --nodocs \
    tor
  && \
  dnf clean all && \
  rm -rf /rootfs/var/cache/* && \
  sed -i \
    -e '/^User/ s/^/#/' \
    /rootfs/usr/share/tor/defaults-torrc && \
  echo "HiddenServiceDir /var/lib/tor/hidden_service/" >> /rootfs/etc/tor/torrc && \
  echo "HiddenServicePort 80 127.0.0.1:80" >> /rootfs/etc/tor/torrc


FROM scratch AS ttrss-micro
LABEL maintainer="Alexandre Chanu <alexandre.chanu@gmail.com>"

COPY --from=micro-build /rootfs/ /

USER toranon
CMD ["/usr/bin/tor", "--runasdaemon", "0", "--defaults-torrc", "/usr/share/tor/defaults-torrc", "-f", "/etc/tor/torrc"]

VOLUME /var/lib/tor/hidden_service


FROM registry.chanu.info/ubi8-ce:latest
LABEL maintainer="Alexandre Chanu <alexandre.chanu@gmail.com>"

RUN \
  dnf install -y \
    --enablerepo="epel" \
    tor \
  && \
  rm -rf /var/cache/dnf && \
  rm -rf /var/log/*.log && \
