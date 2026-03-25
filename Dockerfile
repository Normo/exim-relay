FROM docker.io/alpine:3.23.3

RUN apk --no-cache add exim tini && \
    mkdir /var/spool/exim && \
    chmod 777 /var/spool/exim && \
    ln -sf /dev/stdout /var/log/exim/mainlog && \
    ln -sf /dev/stderr /var/log/exim/panic && \
    ln -sf /dev/stderr /var/log/exim/reject && \
    chmod 0755 /usr/sbin/exim

COPY exim.conf exim-smtps.conf /etc/exim/

# Regardless of the permissions of the original config files in the build context,
# ensure that they are not writable by the Exim user. Otherwise, we'll get an Exim panic:
# > Exim configuration file /etc/exim/exim.conf has the wrong owner, group, or mode
RUN chmod 664 /etc/exim/exim.conf /etc/exim/exim-smtps.conf

USER exim
EXPOSE 8025

ENV LOCAL_DOMAINS=@ \
    RELAY_FROM_HOSTS="<; 10.0.0.0/8; 172.16.0.0/12; 192.168.0.0/16; fc00::/7" \
    RELAY_TO_DOMAINS=* \
    RELAY_TO_USERS= \
    DISABLE_SENDER_VERIFICATION= \
    DKIM_SELECTOR=default \
    HOSTNAME= \
    SMARTHOST= \
    SMTP_PASSWORD= \
    SMTP_USERDOMAIN= \
    SMTP_USERNAME=

ENTRYPOINT ["/sbin/tini", "--"]
CMD ["sh", "-c", "exec exim -C /etc/exim/exim${SMARTHOST_PROTOCOL:+-${SMARTHOST_PROTOCOL}}.conf -bdf -q15m"]
