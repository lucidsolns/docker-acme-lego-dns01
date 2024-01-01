FROM goacme/lego:v4.14.2

RUN apk --no-cache --no-progress add bash docker jq openssl
COPY lego-dns01 /lego-dns01

ENTRYPOINT [ "/lego-dns01" ]