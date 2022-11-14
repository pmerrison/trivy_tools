#!/bin/bash

# Copyright (c) Tetrate, Inc 2022 All Rights Reserved.

set -e

SCAN_OUTPUT_PATH="./scans"
HUB=${HUB:-gcr.io/tetrate-internal-containers}

## Get the list of all images distributed in the release
getImages() {
    tmpImages=$(mktemp)
    tctl install image-sync --just-print --raw --accept-eula --source-registry "${HUB}" > ${tmpImages}
    echo ${tmpImages}
}

## Perform scan on a given image, saving output
## to file
scanImage() {
    IMAGE=${1}
    FILE_NAME=$(echo ${IMAGE} | sed s,${HUB}/,,g | sed -e s,:,_,g)
    OUTPUT_FILE="${SCAN_OUTPUT_PATH}/${FILE_NAME}"
    
    docker image inspect ${IMAGE} > /dev/null 2>&1 || docker pull ${IMAGE}
    set +e # Avoid failing image scan in the first try
    trivy image --list-all-pkgs --format json  --exit-code 0 --output ${OUTPUT_FILE} -- ${IMAGE}
    if [ $? -ne 0 ]; then
        # scan failed, could be a scratch image.
        trivy image --list-all-pkgs --format json --exit-code 0 --output ${OUTPUT_FILE} --severity ${VULN_TYPES} --vuln-type library ${IMAGE} # Try again scanning only libraries
    fi

    set -e
}

#
# main
#
FILE=$(getImages)


while read image; do
    echo "Scanning image ${image} ..."
    scanImage ${image}
    echo
done <${FILE}

echo "Scanned all images 🍺"