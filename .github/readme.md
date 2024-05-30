<h1 align="center">Munin for Docker<br />
<div align="center">
<a href="https://github.com/dockur/munin"><img src="https://raw.githubusercontent.com/dockur/munin/master/.github/logo.jpg" title="Logo" style="max-width:100%;" width="256" /></a>
</div>
<div align="center">

[![Build]][build_url]
[![Version]][tag_url]
[![Size]][tag_url]
[![Pulls]][hub_url]

</div></h1>

This fork of https://github.com/dockur/munin is adapted for running inside Kubernetes:

```bash
helm secrets upgrade munin . --install --atomic --cleanup-on-fail --values=values-config-prod.yaml --values=values-secrets-prod.yaml -n munin
```
It has the following improvements:
* a Helm directory with an example Helm chart for deploying the image inside a vanilla K8S
* Possibility to change port from 80 to e.g. 8080 in order to run rootless
* Possibility to disable IPv6 in nginx if host doesn't have IPv6
* Possibility to pass timezone as build arg
* Creates a user and group munin (1000 / 1000) for running rootless
* Removal of sudo
* Use of supercronic instead of crond
* Removal of /etc/munin/plugin-conf.d volume
* Configuration of rootless nginx




Container image for a Munin master server, optimized for a large number of nodes in an effective manner.

* `rrdcached` is used to be able to handle a large number of nodes

* `fcgi` is used for generation of graphs on demand and not cron

## How to use

Via Docker Compose:

```yaml
services:
  munin:
    image: dockurr/munin
    container_name: munin
    environment:
      TZ: "Europe/Berlin"
      NODES: "node1:10.0.0.101 node2:10.0.0.102"
    ports:
      - 80:80
    volumes:
      - "/munin/lib:/var/lib/munin"
      - "/munin/log:/var/log/munin"
      - "/munin/conf:/etc/munin/munin-conf.d"
      - "/munin/plugin:/etc/munin/plugin-conf.d"
    stop_grace_period: 1m
```

Via Docker CLI:

```bash
docker run -it --rm -p 80:80 -e "NODES=node1:10.0.0.101 node2:10.0.0.102" --stop-timeout 60 dockurr/munin
```

Access the container at `http://host/munin/`

## Stars
[![Stars](https://starchart.cc/dockur/munin.svg?variant=adaptive)](https://starchart.cc/dockur/munin)

[build_url]: https://github.com/dockur/munin/
[hub_url]: https://hub.docker.com/r/dockurr/munin
[tag_url]: https://hub.docker.com/r/dockurr/munin/tags

[Build]: https://github.com/dockur/munin/actions/workflows/build.yml/badge.svg
[Size]: https://img.shields.io/docker/image-size/dockurr/munin/latest?color=066da5&label=size
[Pulls]: https://img.shields.io/docker/pulls/dockurr/munin.svg?style=flat&label=pulls&logo=docker
[Version]: https://img.shields.io/docker/v/dockurr/munin/latest?arch=amd64&sort=semver&color=066da5
