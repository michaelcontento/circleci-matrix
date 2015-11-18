#!/usr/bin/env bash
set -e

CIRCLE_MATRIX_VERSION="0.2.0"
CONFIG_FILE="circle-matrix.yml"

# Ensure sane defaults
CIRCLE_NODE_TOTAL=${CIRCLE_NODE_TOTAL:-1}
CIRCLE_NODE_INDEX=${CIRCLE_NODE_INDEX:-0}

error() {
    local message=$1
    echo >&2 "ERROR: $message"
    exit 1
}

info() {
    local message=$1
    if [ "$message" == "" ]; then
        echo ""
    else
        echo "INFO: $message"
    fi
}

ensure_file() {
    if [ ! -f $CONFIG_FILE ]; then
        error "No $CONFIG_FILE file found!"
    fi
}

sources() {
    # Detect and load nvm for NodeJS
    if [ -f ~/nvm/nvm.sh ]; then
        source ~/nvm/nvm.sh
        info "Detected CircleCI environment"
    fi
}

read_file() {
    # 1) Remove leading spaces
    # 2) Remove leading dashes
    # 3) Remove comment lines
    # 4) Remove empty lines
    sed \
        -e 's/^ *//' \
        -e 's/^- //' \
        -e '/^#.*/d' \
        -e '/^$/d' \
        $CONFIG_FILE
}

process_commands() {
    local line=""
    local mode=""

    read_file | while read line; do
        # Detect mode
        if [ "env:" == "$line" ]; then
            mode="env"
            continue
        elif [ "command:" == "$line" ]; then
            mode="command"
            continue
        fi

        # Process commands
        if [ "command" == "$mode" ]; then
            #info "Running command: $line"
            eval $line
            continue
        fi
    done
}

process_envs() {
    local line=""
    local mode=""
    local i=0

    read_file | while read line; do
        # Detect mode
        if [ "env:" == "$line" ]; then
            mode="env"
            continue
        elif [ "command:" == "$line" ]; then
            mode="command"
            continue
        fi

        # Process envs
        if [ "env" == "$mode" ]; then
            if [ $(($i % $CIRCLE_NODE_TOTAL)) -eq $CIRCLE_NODE_INDEX ]; then
                #info "Running env: $line"
                export $line
                process_commands
            fi
            ((i=i+1))
            continue
        fi
    done
}

main() {
    if [[ "$1" != "" ]]; then CONFIG_FILE=$1; fi
    info "Circle Matrix Version: $CIRCLE_MATRIX_VERSION"
    info "Circle Node Total: $CIRCLE_NODE_TOTAL"
    info "Circle Node Index: $CIRCLE_NODE_INDEX"

    ensure_file
    sources

    info ""
    process_envs
}

main $@
