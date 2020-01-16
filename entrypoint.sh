#!/bin/sh
set -x

GIT_TAG=$(echo "${INPUT_TAG_REF}" | sed -e 's|refs/tags/||')
IMAGE_NAME="docker.pkg.github.com/${INPUT_IMAGE_NAME}"
IMAGE_TAG=$(echo "${GIT_TAG}" | sed -e 's/v//')

echo "Building ${IMAGE_NAME}:${IMAGE_TAG} based on Git tag ${GIT_TAG} ..."

if [ "${INPUT_CREATE_BUILD_VERSION_FILE}" = "yes" ]; then
  echo "Creating build-version.txt file ..."
  echo "${IMAGE_TAG}" > "${GITHUB_WORKSPACE}/build-version.txt"
fi

echo "${INPUT_REGISTRY_PASSWORD}" | docker login -u github --password-stdin https://docker.pkg.github.com/v2/

git checkout "${GIT_TAG}"
set -- "-t" "${IMAGE_NAME}:${IMAGE_TAG}"

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
docker push "${IMAGE_NAME}:${IMAGE_TAG}"
