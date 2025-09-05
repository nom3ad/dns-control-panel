#!/bin/sh
set -ex

fatal() {
    echo "$*" >&2
    exit 2
}

if [ ! -f /config.php ]; then
    USERNAME=${USERNAME:-'admin'}
    PASSWORD=${PASSWORD:-'123'}
    [ -z "$ZONE" ] && fatal "missing config: ZONE"
    [ -z "$SERVER" ] && fatal "missing config: SERVER"
    [ -z "$ENC_SECRET" ] && {
        if [ ! -f .enc_secret ]; then
            echo "Generating encryptionSecret"
            openssl rand -hex 16 >.enc_secret
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
        "zones" => ['$ZONE'],
        "defaultTtl" => 3600,
    ],
];
\$config["zones"] = [
    '$ZONE' => [
        "server" => "$SERVER",
EOF
[ -n "$TRANSFER_KEY" ] && cat <<EOF  >>/app/config/config.php
        "transferKey" => '$TRANSFER_KEY',
EOF
[ -n "$UPDATE_KEY" ] && cat <<EOF  >>/app/config/config.php
        "updateKey" => '$UPDATE_KEY',
EOF
cat <<EOF  >>/app/config/config.php
    ],
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
exec php83 -S "$HOST:$PORT"
