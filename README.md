This is a docker container project. The container is intended for use
in small docker-compose style environments for application that require
a x.509 certificate that is issued using Acme DNS-01.

The intended usage is for:
  - Simple docker compose application
  - One or two certificates
  - Acme DNS-01 support
  - Where there isn't a HTTP server in the application (e.g. mail, jabberd, ...)
  - When DNS Domain Delegation is used (works out of the box with Lego)

This project is probably **not** useful:
 - if a large number of certificates need to be managed
 - wildcard certificates are used (not tested)
 - using k8s or some other container orchestration implementation

# Usage

To use the container, the following basic steps need to be setup:

1. add `ghcr.io/lucidsolns/docker-acme-lego-dns01` service to `docker-compose.yaml`
2. ensure the service depends on the lego service
3. make sure the lego service runs occasionally to renew certificates

## Add service

Add a service to the `docker-compose.yaml` for lego. The service
should be configured to use the desired DNS-01 provider. This requires
setting the `LEGO_DNS01_PROVIDER` environment variable as well as any
provider specific values (e.g. for authentication)

The `LEGO_SERVER` should be set to `https://acme-v02.api.letsencrypt.org/directory`
once testing is completed. The example below uses the staging environment
which should be used for testing.

The `LEGO_PATH` variable should be set to a location where persistent
storage is available; otherwise certificates will be issued every time the
hosting environment is restarted.

If DH parameters are required, then set `DHPARAM_SIZE` to the size of the 
parameters required.

**Note:** the DNS setup used for DNS-01 validation is outside the scope of this
document. The example setup uses DNS delegation to a child domain that is hosted
by luadns.

```yaml
  lego:
    image:  ghcr.io/lucidsolns/docker-acme-lego-dns01:latest
    restart: no
    environment:
      - LEGO_SERVER=https://acme-staging-v02.api.letsencrypt.org/directory
      - LEGO_ACCOUNT_EMAIL=<user@example.com>
      - LEGO_DNS01_PROVIDER=luadns
      - LUADNS_API_USERNAME=<user@example.com>>
      - LUADNS_API_TOKEN=<xxxxxxxxxxxxxxxxxxx>
      - LEGO_PATH=/.lego
      - DHPARAM_SIZE=2048
    volumes:
      - /data/lego:/.lego
      - /var/run/docker.sock:/var/run/docker.sock
```
## Dependent service

Setup the service that requires a certificate in `docker-compose.yaml`.

The `depends_on` option should be used so that the service doesn't attempt
to start until after the first run of the lego container, so that the 
certificates (and DH parameters) will be in place.

Add labels to the container to declare which certificates are required.
If the certificate requires multiple names, then use a comma separated 
values (CSV) with the domains. If multiple certificates are required
then suffix each `acme.dns01.lego.domain` label with a number so that
unique labels are used.

With the labels present, the lego contain will signal the application service
container with a `SIGHUP` whenever the certificates/DH parameters change.

**Note:** When a certificate changes, the HUP signal is sent blindly to the
container whether it is running or not - this tends to result in some
errors that the container is not running.

example:
```yaml
  ejabberd:
    image: ejabberd/ecs
    depends_on:
      lego:
        condition: service_completed_successfully
    labels:
      - acme.dns01.lego.domain.0=xmpp-server.example.com,example.com
      - acme.dns01.lego.domain.1=xmpp-client.example.com,example.com
    ...
```
## Renew Timer

The lego docker service needs to be run occasionally (say daily) to renew
certificates. The interval should be randomised.

The following uses a systemd service on Flatcar Linux to run the docker
compose service.

The service file (`acme-certificate-renew.service`):
```unit file (systemd)
[Unit]
Description=Run Acme Lego to renew certificates
Wants=network-online.target
After=network.target network-online.target docker.service docker-compose-install.service
Requires=docker.service docker-compose-install.service

[Service]
Type=oneshot
EnvironmentFile=/etc/lego.ini
ExecStart=/opt/bin/docker-compose -f /etc/docker-compose.yaml start lego
```
And a timer file (`acme-certificate-renew.timer`):
```unit file (systemd)
[Unit]
Description=Update certificates once a day

[Timer]
# Daily at 3:33am local time (with random-ness)
#
# To display when it will actually trigger:
#     > systemd-analyze calendar *-*-* 03:33:33
OnCalendar=*-*-* 03:33:33 Pacific/Auckland
RandomizedDelaySec=1h

[Install]
WantedBy=multi-user.target
```

# Known residuals

- the certificate key type isn't configurable
- the signal sent on change is not configurable
- testing with wildcard certificates has not been attempted

# Links

- https://github.com/go-acme/lego
- https://go-acme.github.io/lego/usage/cli/options/
- https://go-acme.github.io/lego/dns/luadns/
- https://go-acme.github.io/lego/dns/
- https://hub.docker.com/r/goacme/lego/
- https://ghcr.io/lucidsolns/docker-acme-lego-dns01
- https://github.com/lucidsolns/docker-acme-lego-dns01
