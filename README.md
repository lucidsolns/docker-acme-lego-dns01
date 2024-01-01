This is a docker container project. The container is intended for use
in small docker-compose style environments for application that require
a x.509 certificate that is issued using Acme DNS-01.

The intended usage is for:
  - Simple docker compose application
  - One or two certificates
  - Acme DNS-01 support
  - Where there isn't a HTTP server in the application (e.g. mail, jabberd, ...)

This project is probably **not** useful:
 - if a large number of certificates need to be managed
 - wildcard certificates are used (not tested)
 - using k8s or some other container orchestration implementation

# Usage

TODO: write this

# Links

- https://github.com/go-acme/lego
- https://go-acme.github.io/lego/usage/cli/options/
- https://go-acme.github.io/lego/dns/luadns/
- https://go-acme.github.io/lego/dns/
- https://hub.docker.com/r/goacme/lego/
