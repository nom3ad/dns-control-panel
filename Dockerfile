FROM alpine:3.22

RUN apk add --no-cache php83 php83-sqlite3 php83-openssl bind-tools lighttpd php83-cgi

COPY . /app

WORKDIR /app

ENTRYPOINT /app/entrypoint.sh
