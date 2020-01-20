#!/bin/sh
set -x

GIT_TAG=$(echo "${INPUT_TAG_REF}" | sed -e 's|refs/tags/||')
IMAGE_NAME="docker.pkg.github.com/${INPUT_IMAGE_NAME}"
IMAGE_TAG=$(echo "${GIT_TAG}" | sed -e 's/^v//' | sed -e 's/+.*//')

echo "Building ${IMAGE_NAME}:${IMAGE_TAG} based on Git tag ${GIT_TAG} ..."

echo "Creating build-version.txt file ..."
echo "${GIT_TAG}" > "${GITHUB_WORKSPACE}/build-version.txt"

echo "${INPUT_REGISTRY_PASSWORD}" | docker login -u github --password-stdin https://docker.pkg.github.com/v2/

git checkout "${GIT_TAG}"
set -- "-t" "${IMAGE_NAME}:${IMAGE_TAG}" \
  "--label" "org.label-schema.schema-version=1.0" \
  "--label" "org.label-schema.version=${IMAGE_TAG}" \
  "--label" "org.label-schema.build-date=$(date '+%FT%TZ')" \
  "--build-arg" "BUILD_DATE=$(date '+%FT%TZ')"

if [ -n "${INPUT_GIT_REPOSITORY_URL}" ]; then
  set -- "$@" "--label" "org.label-schema.vcs-url=${INPUT_GIT_REPOSITORY_URL}"
fi
if [ -n "${INPUT_GIT_SHA}" ]; then
  set -- "$@" "--label" "org.label-schema.vcs-ref=${INPUT_GIT_SHA}"
fi

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
