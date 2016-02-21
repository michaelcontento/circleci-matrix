#!/usr/bin/env bash
set -e

mkdir -p ~/.local/bin
curl \
    --fail\
    --silent \
    --show-error \
    --location \
    https://raw.githubusercontent.com/michaelcontento/circleci-matrix/master/src/circleci-matrix.sh \
    -o ~/.local/bin/circleci-matrix
chmod +x ~/.local/bin/circleci-matrix
