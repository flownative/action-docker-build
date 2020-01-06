#!/bin/sh
set -x

TAG=$(echo "${INPUT_TAG_REF}" | sed -e 's|refs/tags/||')
IMAGE_NAME="docker.pkg.github/${INPUT_IMAGE_NAME}"

echo "${INPUT_GITHUB_TOKEN}" | docker login -u github --password-stdin https://docker.pkg.github.com/v2/

git checkout ${TAG}
set -- "-t" "${IMAGE_NAME}:${TAG}"

BUILD_ENV_SCRIPT=${GITHUB_WORKSPACE}/.github/build-env.sh

if [ -f "${BUILD_ENV_SCRIPT}" ]; then
  # shellcheck disable=SC1090
  . "${BUILD_ENV_SCRIPT}"
  IFS="$(printf '\n ')" && IFS="${IFS% }"
  set -o noglob
  for line in $(env | grep BUILD_ARG_); do
    set -- "$@" '--build-arg' $(echo "$line" | sed -E 's/(BUILD_ARG_)//g')
  done
  echo "Build arguments: " "$@"
else
  echo "Skipping build env script (none found at ${BUILD_ENV_SCRIPT})"
fi

docker build "$@" .
docker push "${IMAGE_NAME}:${TAG}"
