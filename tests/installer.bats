#!/usr/bin/env bats

setup() {
    cd $BATS_TEST_DIRNAME
    unset CIRCLE_NODE_TOTAL
    unset CIRCLE_NODE_INDEX
}

@test "installer" {
    rm -rf ~/.local/bin/circleci-matrix
    # Only remove the whole folder if it's empty!
    if [ $(ls -1 ~/.local/bin | wc -l) -eq 0 ]; then
        rm -rf ~/.local/bin
    fi

    $BATS_TEST_DIRNAME/../src/install.sh

    [ -f ~/.local/bin/circleci-matrix ]
    [ -x ~/.local/bin/circleci-matrix ]
    ~/.local/bin/circleci-matrix --version
}
