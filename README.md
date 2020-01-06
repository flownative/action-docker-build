# Docker Image Build Github Action

This Github action builds a Docker image based on a given Git tag reference. 

It's also possible to provide a script which can dynamically set environment variables which are then used as build
arguments. That way you can retrieve a version number of a specific dependency via a web service or URL and pass
the information to your Dockerfile. 

## Example workflow

````yaml
name: Build and release Docker images
on:
  push:
    branches-ignore:
      - '**'
    tags:
      - 'v*.*.*'

jobs:
  build:
    runs-on: ubuntu-latest
    steps:

      - uses: actions/checkout@v2
        with:
          fetch-depth: 1

      - name: Build Docker image
        uses: flownative/action-docker-build@master
        with:
          tag_ref: ${{ github.ref }}
          image_name: flownative/docker-base/base
          registry_password: ${{ secrets.GITHUB_TOKEN }}
````

If the following file is present as `.github/workflows/build-env.sh`, its exported environment environment variables
(you can provide multiple ones) will be parsed ...

````bash
BUILD_ARG_MICRO_VERSION=$(wget -qO- https://versions.flownative.io/projects/base/channels/stable/versions/micro.txt)
export BUILD_ARG_MICRO_VERSION
````

... and can be used in a Dockerfile as build arguments as such:

```Dockerfile
…
ARG MICRO_VERSION
ENV MICRO_VERSION=${MICRO_VERSION}
RUN wget --no-hsts https://github.com/zyedidia/micro/releases/download/v${MICRO_VERSION}/micro-${MICRO_VERSION}-linux64.tar.gz; \
    tar xfz micro-${MICRO_VERSION}-linux64.tar.gz; \
    mv micro-${MICRO_VERSION}/micro /usr/local/bin; \
    chmod 755 /usr/local/bin/micro; \
    rm -rf micro-${MICRO_VERSION}* /var/log/* /var/lib/dpkg/status-old
…
```
