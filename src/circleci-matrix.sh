#!/usr/bin/env bash
set -e

VERSION="0.2.0"
CONFIG_FILE=".circleci-matrix.yml"
STOP_ON_ERROR=0
FAILED_COMMANDS=0

# Ensure sane defaults and export for subshells
export CIRCLE_NODE_TOTAL=${CIRCLE_NODE_TOTAL:-1}
export CIRCLE_NODE_INDEX=${CIRCLE_NODE_INDEX:-0}

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
        echo "$message"
    fi
}

print_horizontal_rule () {
    printf "%$(tput cols)s\n" | tr " " "-"
}

print_help() {
    info "Usage: circleci-matrix [OPTIONS]"
    info ""
    info "Options:"
    info "  --help, -h           Print this screen"
    info "  --version            Current version of circleci-matrix"
    info "  --config, -c         Specify the config file to use"
    info "                       (default: .circleci-matrix.yml)"
    info "  --stop-on-error,-s   Halt after the first failed command"
}

parse_args() {
    while : ; do
    case "$1" in
    -h|--help)
        print_help
        exit 0
        ;;

    --version)
        info "$VERSION"
        exit 0
        ;;

    -c|--config)
        if [ "$2" == "" ]; then
            error "Missing argument for: $1"
        fi
        CONFIG_FILE=$2
        shift 2
        ;;

    -s|--stop-on-error)
        STOP_ON_ERROR=1
        shift
        ;;

    *)
        if [ "$1" != "" ]; then
            error "Unknown option: $1"
        fi
        break
        ;;
    esac
    done
}

ensure_file() {
    if [ ! -f $CONFIG_FILE ]; then
        error "No $CONFIG_FILE file found!"
    fi
}

sources() {
    # Detect and load nvm for NodeJS
    if [ -f ~/nvm/nvm.sh ]; then
        echo "source ~/nvm/nvm.sh;"
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
    local envparam=$1

    while read line; do
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
            set +e
            (bash -c "$(sources) $envparam; $line")
            local exitcode=$?
            set -e

            if [ $exitcode -ne 0 ]; then
                ((FAILED_COMMANDS=FAILED_COMMANDS+1))
                if [ $STOP_ON_ERROR -eq 1 ]; then
                    exit 1
                fi
            fi

            continue
        fi
    done < <(read_file)
}

process_envs() {
    local line=""
    local mode=""
    local i=0

    while read line; do
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
                print_horizontal_rule
                info "Env: $line"
                print_horizontal_rule

                process_commands "$line"
                info ""
            fi
            ((i=i+1))
            continue
        fi
    done < <(read_file)
}

main() {
    parse_args $@

    info "circleci-matrix version: $VERSION"
    info "circleci node total: $CIRCLE_NODE_TOTAL"
    info "circleci node index: $CIRCLE_NODE_INDEX"
    ensure_file
    info ""

    process_envs

    if [ $FAILED_COMMANDS -gt 0 ]; then
        error "$FAILED_COMMANDS command(s) failed"
    fi
}

main $@
