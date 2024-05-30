FROM alpine:edge

ARG VERSION_ARG="0.0"
ARG PORT=80
ARG DISABLEIPV6=false
ARG TZ=Europe/Lisbon

# Create the user and group
RUN addgroup -g 1000 munin
RUN adduser -G munin -u 1000 -D munin

# Install packages
RUN apk --no-cache add \
    coreutils \
    curl \
    dumb-init \
    findutils \
    logrotate \
    munin \
    munin-node \
    nginx \
    perl-cgi-fast \
    procps \
    rrdtool-cached \
    spawn-fcgi \
    ttf-opensans \
    tzdata && \
  echo "$VERSION_ARG" > /run/version && \
  rm -rf /var/cache/apk/*

# Set munin crontab
RUN sed '/^[^*].*$/d; s/ munin //g' /etc/munin/munin.cron.sample | crontab -u munin - 
RUN chown munin:munin /etc/crontabs/munin
RUN rm /etc/crontabs/root /etc/crontabs/cron.update

# Default nginx.conf
COPY nginx.conf /etc/nginx/

# Copy munin config to nginx
COPY default.conf /etc/nginx/conf.d/
RUN sed -i "s/PORT/$PORT/g" /etc/nginx/conf.d/default.conf
RUN if [[ "$DISABLEIPV6" == "true" ]] ; then sed -i '/listen \[::\]/d' /etc/nginx/conf.d/default.conf ; fi

# Set timezone
RUN if ! [[ ! -z "$TZ" && -f "/usr/share/zoneinfo/$TZ" ]]; then TZ="UTC"; fi
RUN cp "/usr/share/zoneinfo/$TZ" /etc/localtime
RUN echo "$TZ" > /etc/timezone

# Copy munin conf
COPY munin.conf /etc/munin/

# Start script with all processes
COPY docker-cmd.sh /

# Set execute permission
RUN chmod +x /docker-cmd.sh

# Logrotate script for munin logs
COPY munin /etc/logrotate.d/

RUN chown munin:munin \
  /var/log/munin /run/munin /var/lib/munin /var/lib/munin/cgi-tmp \
  /etc/munin/munin-conf.d /etc/munin/plugin-conf.d
RUN chmod 755 /usr/share/webapps/munin/html
RUN chown -R munin:munin /usr/share/webapps/munin/html
RUN chown -R munin:munin /usr/share/webapps/munin/cgi
RUN chown -R munin:munin /var/log/nginx
RUN chown -R munin:munin /var/lib/nginx

# supercronic
# Latest releases available at https://github.com/aptible/supercronic/releases
ENV SUPERCRONIC_URL=https://github.com/aptible/supercronic/releases/download/v0.2.29/supercronic-linux-amd64 \
    SUPERCRONIC=supercronic-linux-amd64 \
    SUPERCRONIC_SHA1SUM=cd48d45c4b10f3f0bfdd3a57d054cd05ac96812b

RUN curl -fsSLO "$SUPERCRONIC_URL" \
 && echo "${SUPERCRONIC_SHA1SUM}  ${SUPERCRONIC}" | sha1sum -c - \
 && chmod +x "$SUPERCRONIC" \
 && mv "$SUPERCRONIC" "/usr/local/bin/${SUPERCRONIC}" \
 && ln -s "/usr/local/bin/${SUPERCRONIC}" /usr/local/bin/supercronic

# Expose volumes
VOLUME /etc/munin/munin-conf.d /var/lib/munin /var/log/munin

# Expose NODES variable
ENV NODES ""

# Expose nginx
EXPOSE $PORT

# Healthcheck
HEALTHCHECK --interval=60s --retries=2 --timeout=10s CMD wget -nv -t1 --spider "http://localhost:$PORT/munin/" || exit 1

# Use dumb-init since we run a lot of processes
ENTRYPOINT ["/usr/bin/dumb-init", "--"]

# Run start script or what you choose
CMD ["/bin/bash", "/docker-cmd.sh"]
