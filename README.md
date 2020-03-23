[![MIT license](http://img.shields.io/badge/license-MIT-brightgreen.svg)](http://opensource.org/licenses/MIT)
[![Maintenance level: Love](https://img.shields.io/badge/maintenance-%E2%99%A1%E2%99%A1%E2%99%A1-ff69b4.svg)](https://www.flownative.com/en/products/open-source.html)

# Docker Image Build Github Action

This Github action builds a Docker image based on a given Git tag
reference. The Git tag must start with a "v" prefix, for example
"v1.23.4+5"

It's also possible to provide a script which can dynamically set
environment variables which are then used as build arguments. That way
you can retrieve a version number of a specific dependency via a web
service or URL and pass the information to your Dockerfile.

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
        uses: flownative/action-docker-build@v1
        with:
          tag_ref: ${{ github.ref }}
          image_name: flownative/docker-base/base
          registry_password: ${{ secrets.GITHUB_TOKEN }}
````
## Inputs

The following inputs are used by this action:

- `tag_ref`: The full Git tag reference. This must be a semver tag ref
  of an existing tagged image. For example, `refs/tags/v1.2.5+12`
- `git_sha`: The SHA hash of the Git commit being used for the build. If
  set, this value is used as a label for the resulting Docker image
- `git_repository_url`: The URL leading to the Git repository. If set,
  this value is used as a label for the resulting Docker image
- `image_name`: The image name to build, without tag. For example,
  `flownative/docker-magic-image/magic-image`
- `image_tag`: The image tag to build. If empty, the tag is derived from
  `tag_ref`: e.g. `v1.2.5`
- `registry_password`: Password / token for the Github Docker image
  registry

## Outputs

After a successful run, the action provides your workflow with the
following outputs:

- `image_name`: The name of the Docker image, which was built and pushed
- `image_tag`: The tag of the Docker image, which was built and pushed
- `git_tag`: The tag of the Git commit, which was discovered during the
  process

## Docker image labels

This action automatically sets a couple of labels in the built Docker
image. This metadata may help you and others identifying the state of
source code used at build time.

The following labels are set:

- `org.label-schema.version`: set to the image tag
- `org.label-schema.build-date`: set to the current date and time during
  the build
- `org.label-schema.vcs-url`: set to to the Git repository URL
- `org.label-schema.vcs-ref`: set to the SHA of the current Git commit

Hint: You can review the image labels by running `docker inspect`.

## Dynamic build arguments

If the following file is present as `.github/workflows/build-env.sh`,
its exported environment environment variables (you can provide multiple
ones) will be parsed ...

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

## Implementation Note

The repository of this action does not contain the actual implementation
code. Instead, it's referring to a pre-built image in its `Dockerfile`
in order to save resources and speed up workflow runs.

The code of this action can be found
[here](https://github.com/flownative/docker-action-docker-build).
