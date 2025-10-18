#!/bin/sh
set -e

fatal() {
    echo "$*" >&2
    exit 2
}

if [ ! -f /config.php ]; then
    USERNAME=${USERNAME:-'admin'}
    PASSWORD=${PASSWORD:-'123'}
    [ -z "$ZONES" ] && fatal "missing config: ZONES"
    [ -z "$SERVER" ] && fatal "missing config: SERVER"
    [ -z "$ENC_SECRET" ] && {
        if [ ! -f .enc_secret ]; then
            echo "Generating encryptionSecret"
            head -c 16 /dev/urandom | xxd -p >.enc_secret
        fi
        ENC_SECRET=$(cat .enc_secret)
    }
    [ -z "$HASHED_PASSWORD" ] && {
        echo "Generating hashed password from PASSWORD"
        HASHED_PASSWORD=$(php83 -r "echo password_hash('$PASSWORD', PASSWORD_DEFAULT);")
    }

    echo "Generating config.php" >&2
cat <<EOF  >/app/config/config.php
<?php
\$config = [];
\$config["user"] = [
    '$USERNAME' => [
        "password" => '$HASHED_PASSWORD',
        "zones" => ['$(echo "$ZONES" | sed -e "s/,/','/g")'],
        "defaultTtl" => 3600,
    ],
];
\$config["zones"] = [
EOF

for zone in $(echo "$ZONES" | sed -e "s/,/ /g"); do
    cat <<EOF  >>/app/config/config.php
    '$zone' => [
        "server" => "$SERVER",
EOF
    [ -n "$TRANSFER_KEY" ] && cat <<EOF  >>/app/config/config.php
        "transferKey" => '$TRANSFER_KEY',
EOF
    [ -n "$UPDATE_KEY" ] && cat <<EOF  >>/app/config/config.php
        "updateKey" => '$UPDATE_KEY',
EOF
    echo '    ],'>>/app/config/config.php
done

cat <<EOF  >>/app/config/config.php
];
\$config["encryptionSecret"] = "$ENC_SECRET";
EOF

else
    echo "Using mounted /config.php" >&2
    cp /config.php /app/config/config.php
fi

[ -n "$DEBUG" ] && cat /app/config/config.php >&2


HOST="${HOST-0.0.0.0}"
PORT="${PORT-5380}"

cd /app || exit 2

exec 3>&1

mkdir -p /run/lighttpd/
cat <<EOF >/etc/lighttpd/lighttpd.conf
server.modules = (
    "mod_access",
    "mod_accesslog"
)
include "mod_fastcgi.conf"
server.document-root = "/app"
server.pid-file      = "/run/lighttpd.pid"
index-file.names     = ("index.php", "index.html", "index.htm", "default.htm")
server.errorlog      = "/dev/stderr"
accesslog.filename   = "/dev/stderr"
server.port = $PORT
server.bind = "$HOST"
EOF

exec lighttpd -D -f /etc/lighttpd/lighttpd.conf
