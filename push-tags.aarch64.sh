#!/bin/bash
set -x

SE_VERSION="5.01.9674"
SUFFIX="aarch64"
VERSION_TAG=${SE_VERSION}-${SUFFIX}

#docker pull devdotnetorg/softethervpn-alpine:${VERSION_TAG}

NEW_TAGS="aarch64 latest"

for TAG in ${NEW_TAGS}; do
  docker tag devdotnetorg/softethervpn-alpine:${VERSION_TAG} devdotnetorg/softethervpn-alpine:${TAG}
  docker push devdotnetorg/softethervpn-alpine:${TAG}  
done
