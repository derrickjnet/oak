#!/bin/bash -e

OAK_VERSION="4.3.0";
BASE="oaklabs/oak:$OAK_VERSION";

# our FROM line in the Dockerfile, should ideally match the current electron node version
FROM="node";
NODE_VERSION="8.11.3";
ELECTRON_VERSION="1.8.7"
FROM_TAG="$NODE_VERSION-stretch";

NPM_URL="https://registry.npmjs.org/";

DOCKERFILE_TEMPLATE_PATH="./node_modules/.bin/dockerfile-template";
MANIFEST_TOOL_PATH=$(which manifest-tool);

UNAME_ARCH=$(uname -m);

# The immediate targets are just for intel and arm (raspi)
case $UNAME_ARCH in
  x86_64)
    FROM="node";
    ARCH_TAG="amd64";
    ;;
  armv6l)
    FROM="hypriot/rpi-node";
    ARCH_TAG="arm";
    ;;
  armv7l)
    FROM="hypriot/rpi-node";
    ARCH_TAG="arm64";
    ;;
esac

FULL_TAG=$BASE-$ARCH_TAG

# Keep track of tags for an optional push arg
TAGS=()
TAGS+=("${FULL_TAG}")

echo "";
echo "* Compiling Dockerfile with $FULL_TAG";
echo "";
# compile our template file
$DOCKERFILE_TEMPLATE_PATH \
    -d FROM=$FROM \
    -d FROM_TAG=$FROM_TAG \
    -d ELECTRON_VERSION=$ELECTRON_VERSION > Dockerfile

# build our base tag
echo "";
echo "** Building $FULL_TAG";
echo "";
docker build -t $FULL_TAG $(pwd);

# push our tags array
if [[ $# -lt 3 && $1 == "push" ]]; then
    for TAG in "${TAGS[@]}"; do
        echo "";
        echo "** Pushing $TAG";
        echo "";
        docker push $TAG;
        if [ ! -e "$MANIFEST_TOOL_PATH" ]; then
            echo "";
            echo "* manifest-tool missing. Install it so you can use it!.";
            echo "";
            exit 1;
        else
            $MANIFEST_TOOL_PATH push from-spec manifest.yml
            echo "";
            echo "* manifest pushed successfully.";
            exit 0;
        fi
    done;
fi
