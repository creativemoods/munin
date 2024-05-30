#!/bin/bash
set -eu

NODES="${NODES:-}"

echo "Starting rrdcached..."
mkdir -p /var/lib/munin/rrdcached-journal
/usr/sbin/rrdcached \
  -p /run/munin/rrdcached.pid \
  -B -b /var/lib/munin/ \
  -F -j /var/lib/munin/rrdcached-journal/ \
  -m 0660 -l unix:/run/munin/rrdcached.sock \
  -w 1800 -z 1800 -f 3600

# Generate node list
[[ ! -z "$NODES" ]] && for NODE in $NODES
do
  NAME=`echo "$NODE" | cut -d ":" -f1`
  HOST=`echo "$NODE" | cut -d ":" -f2`
  PORT=`echo "$NODE" | cut -d ":" -f3`
  if [ ${#PORT} -eq 0 ]; then
      PORT=4949
  fi
  if ! grep -q "$HOST" /etc/munin/munin-conf.d/nodes.conf 2>/dev/null ; then
    cat << EOF >> /etc/munin/munin-conf.d/nodes.conf
[$NAME]
    address $HOST
    use_node_name yes
    port $PORT

EOF
  fi
done

# Run once before we start fcgi
echo "Running munin-cron once..."
/usr/bin/munin-cron munin

# Spawn fast cgi process for generating graphs on the fly
echo "Starting spawn-fcgi..."
spawn-fcgi -s /var/run/munin/fastcgi-graph.sock -U nginx -u munin -g munin -- \
  /usr/share/webapps/munin/cgi/munin-cgi-graph

# Spawn fast cgi process for generating html on the fly
echo "Starting spawn-fcgi..."
spawn-fcgi -s /var/run/munin/fastcgi-html.sock -U nginx -u munin -g munin -- \
  /usr/share/webapps/munin/cgi/munin-cgi-html

# Supercronic
echo "Starting supercronic..."
/usr/local/bin/supercronic /etc/crontabs/munin &

# Start web-server
echo "Starting nginx..."
nginx
